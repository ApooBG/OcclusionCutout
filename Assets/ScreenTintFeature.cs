using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class ScreenTintFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class Settings
    {
        public Material blitMaterial; // use the shader below
    }
    public Settings settings = new Settings();

    class TintPass : ScriptableRenderPass
    {
        static readonly string kTag = "DEBUG Tint Pass";
        readonly ProfilingSampler _sampler = new ProfilingSampler(kTag);
        Material _mat;

        public TintPass(Material m) { _mat = m; renderPassEvent = RenderPassEvent.AfterRendering; }

        public void Setup(Material m) { _mat = m; }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (_mat == null) return;
            var cmd = CommandBufferPool.Get(kTag);
            using (new ProfilingScope(cmd, _sampler))
            {
                var cameraColor = renderingData.cameraData.renderer.cameraColorTargetHandle;
                Blitter.BlitCameraTexture(cmd, cameraColor, cameraColor, _mat, 0); // in-place
            }
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }

    TintPass _pass;

    public override void Create() { _pass = new TintPass(settings.blitMaterial); }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (settings.blitMaterial == null) return;
        _pass.Setup(settings.blitMaterial);
        renderer.EnqueuePass(_pass);
    }
}
