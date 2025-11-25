using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class StencilEdgeRenderer : ScriptableRendererFeature
{
    [System.Serializable]
    public class Settings
    {
        public LayerMask occludableLayer = ~0;   // set to your Occludable layer in the inspector
        public Shader occludableDepthShader;     // Hidden/OccludableDepthOnly
    }

    class OccludableDepthPass : ScriptableRenderPass
    {
        private Settings settings;
        private FilteringSettings filteringSettings;

        private readonly ShaderTagId[] shaderTagIds =
        {
            new ShaderTagId("UniversalForward"),
            new ShaderTagId("SRPDefaultUnlit")
        };

        private Material depthMaterial;

        // RTHandle instead of RenderTargetHandle
        private RTHandle occludableDepthRT;
        private RenderTextureDescriptor depthDesc;

        private static readonly int OccludableDepthTexID = Shader.PropertyToID("_OccludableDepthTex");

        public OccludableDepthPass(Settings settings)
        {
            this.settings = settings;

            filteringSettings = new FilteringSettings(
                RenderQueueRange.opaque,
                settings.occludableLayer
            );

            renderPassEvent = RenderPassEvent.AfterRenderingPrePasses;

            if (settings.occludableDepthShader != null)
            {
                depthMaterial = new Material(settings.occludableDepthShader);
            }
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            if (depthMaterial == null)
                return;

            depthDesc = cameraTextureDescriptor;
            depthDesc.depthBufferBits = 0;
            depthDesc.msaaSamples = 1;
            depthDesc.colorFormat = RenderTextureFormat.RFloat;

            // Allocate / resize RTHandle as needed
            RenderingUtils.ReAllocateIfNeeded(
                ref occludableDepthRT,
                depthDesc,
                FilterMode.Point,
                TextureWrapMode.Clamp,
                name: "_OccludableDepthTex"
            );

            ConfigureTarget(occludableDepthRT);
            ConfigureClear(ClearFlag.Color, Color.black);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (depthMaterial == null || occludableDepthRT == null)
                return;

            var cmd = CommandBufferPool.Get("Occludable Depth Pass");

            using (new ProfilingScope(cmd, new ProfilingSampler("Occludable Depth Pass")))
            {
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();

                var sortFlags = renderingData.cameraData.defaultOpaqueSortFlags;
                var drawingSettings = CreateDrawingSettings(shaderTagIds[0], ref renderingData, sortFlags);

                for (int i = 1; i < shaderTagIds.Length; i++)
                {
                    drawingSettings.SetShaderPassName(i, shaderTagIds[i]);
                }

                drawingSettings.overrideMaterial = depthMaterial;

                context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref filteringSettings);

                // Make the RTHandle available to shaders as _OccludableDepthTex
                cmd.SetGlobalTexture(OccludableDepthTexID, occludableDepthRT);
            }

            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        public void Dispose()
        {
            if (occludableDepthRT != null)
            {
                occludableDepthRT.Release();
                occludableDepthRT = null;
            }

            if (depthMaterial != null)
            {
#if UNITY_EDITOR
                if (Application.isPlaying)
                    Object.Destroy(depthMaterial);
                else
                    Object.DestroyImmediate(depthMaterial);
#else
                Object.Destroy(depthMaterial);
#endif
                depthMaterial = null;
            }
        }
    }

    public Settings settings = new Settings();
    private OccludableDepthPass occludableDepthPass;

    public override void Create()
    {
        if (settings.occludableDepthShader == null)
        {
            Debug.LogError("StencilEdgeRenderer: Assign an Occludable Depth Shader in the inspector.");
            return;
        }

        occludableDepthPass = new OccludableDepthPass(settings);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (occludableDepthPass != null)
        {
            renderer.EnqueuePass(occludableDepthPass);
        }
    }

    protected override void Dispose(bool disposing)
    {
        base.Dispose(disposing);

        if (disposing && occludableDepthPass != null)
        {
            occludableDepthPass.Dispose();
            occludableDepthPass = null;
        }
    }
}
