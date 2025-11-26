using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class BehindSceneRenderer : ScriptableRendererFeature
{
    [System.Serializable]
    public class Settings
    {
        // Layers that SHOULD be rendered into the "behind" texture
        // IMPORTANT: do NOT include the Occludable layer here.
        public LayerMask visibleLayers = ~0;
    }

    class BehindScenePass : ScriptableRenderPass
    {
        private Settings settings;
        private FilteringSettings filteringSettings;
        private readonly ShaderTagId[] shaderTagIds =
        {
            new ShaderTagId("UniversalForward"),
            new ShaderTagId("SRPDefaultUnlit")
        };

        private RTHandle behindRT;
        private RenderTextureDescriptor desc;
        private static readonly int SceneBehindTexID = Shader.PropertyToID("_SceneBehindTex");

        public BehindScenePass(Settings settings)
        {
            this.settings = settings;

            filteringSettings = new FilteringSettings(
                RenderQueueRange.all,
                settings.visibleLayers
            );

            // Run before normal opaques so we render skybox + non-occludables
            renderPassEvent = RenderPassEvent.BeforeRenderingOpaques;
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            desc = cameraTextureDescriptor;
            desc.msaaSamples = 1;

            RenderingUtils.ReAllocateIfNeeded(
                ref behindRT,
                desc,
                FilterMode.Bilinear,
                TextureWrapMode.Clamp,
                name: "_SceneBehindTex"
            );

            // Clear both color and depth in our own RT
            ConfigureTarget(behindRT);
            ConfigureClear(ClearFlag.Color | ClearFlag.Depth, Color.clear);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (behindRT == null)
                return;

            var cmd = CommandBufferPool.Get("Behind Scene Pass");

            using (new ProfilingScope(cmd, new ProfilingSampler("Behind Scene Pass")))
            {
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();

                // 1. Draw skybox into _SceneBehindTex
                var camera = renderingData.cameraData.camera;
                context.DrawSkybox(camera);

                // 2. Draw all non-occludable renderers (visibleLayers)
                var sortFlags = renderingData.cameraData.defaultOpaqueSortFlags;
                var drawingSettings = CreateDrawingSettings(shaderTagIds[0], ref renderingData, sortFlags);
                for (int i = 1; i < shaderTagIds.Length; i++)
                    drawingSettings.SetShaderPassName(i, shaderTagIds[i]);

                context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref filteringSettings);

                // 3. Expose the texture globally
                cmd.SetGlobalTexture(SceneBehindTexID, behindRT);
            }

            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        public void Dispose()
        {
            if (behindRT != null)
            {
                behindRT.Release();
                behindRT = null;
            }
        }
    }

    public Settings settings = new Settings();
    private BehindScenePass pass;

    public override void Create()
    {
        pass = new BehindScenePass(settings);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (pass != null)
            renderer.EnqueuePass(pass);
    }

    protected override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
        if (disposing && pass != null)
        {
            pass.Dispose();
            pass = null;
        }
    }
}
