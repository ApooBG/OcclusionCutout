using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class StencilOcclusionFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class Settings
    {
        [Tooltip("Layer that contains the volume(s) that carve the hole.")]
        public LayerMask volumeLayer;           // e.g., "OcclusionVolume"

        [Tooltip("Layer that contains meshes to be hidden inside the volume.")]
        public LayerMask occludableLayer;       // e.g., "Occludable"

        [Tooltip("Material that writes stencil Ref=1 (Hidden/OcclusionStencilWrite).")]
        public Material stencilWriteMaterial;
    }

    class VolumeStencilPass : ScriptableRenderPass
    {
        FilteringSettings filter;
        Material mat;
        ShaderTagId tag = new ShaderTagId("UniversalForward");
        ProfilingSampler sampler = new ProfilingSampler("Write Stencil");

        public VolumeStencilPass(LayerMask layer, Material m)
        {
            renderPassEvent = RenderPassEvent.BeforeRenderingOpaques;
            filter = new FilteringSettings(RenderQueueRange.all, layer);
            mat = m;
        }

        public void UpdateForFrame(LayerMask layer, Material m)
        {
            filter.layerMask = layer;
            mat = m;
        }

        public override void Execute(ScriptableRenderContext ctx, ref RenderingData data)
        {
            if (mat == null) return;

            var cmd = CommandBufferPool.Get("Write Stencil");
            using (new ProfilingScope(cmd, sampler))
            {
                var draw = CreateDrawingSettings(tag, ref data, SortingCriteria.CommonOpaque);
                draw.overrideMaterial = mat;
                draw.overrideMaterialPassIndex = 0;

                var state = new RenderStateBlock(RenderStateMask.Nothing);
                ctx.ExecuteCommandBuffer(cmd);
                cmd.Clear();
                ctx.DrawRenderers(data.cullResults, ref draw, ref filter, ref state);
            }
            ctx.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }

    class DrawOccludablesPass : ScriptableRenderPass
    {
        FilteringSettings filter;
        ShaderTagId tag = new ShaderTagId("UniversalForward");
        ProfilingSampler sampler = new ProfilingSampler("Draw Occludables (Stencil != 1)");
        RenderStateBlock state;

        public DrawOccludablesPass(LayerMask layer)
        {
            renderPassEvent = RenderPassEvent.BeforeRenderingOpaques;
            filter = new FilteringSettings(RenderQueueRange.opaque, layer);

            // Stencil: only draw where stencil != 1
            var stencil = new StencilState(true, (byte)255, (byte)255,
                compareFunction: CompareFunction.NotEqual,
                passOperation: StencilOp.Keep,
                failOperation: StencilOp.Keep,
                zFailOperation: StencilOp.Keep);

            state = new RenderStateBlock(RenderStateMask.Stencil) { stencilState = stencil, stencilReference = 1 };
        }

        public void UpdateForFrame(LayerMask layer)
        {
            filter.layerMask = layer;
        }

        public override void Execute(ScriptableRenderContext ctx, ref RenderingData data)
        {
            var cmd = CommandBufferPool.Get("Draw Occludables");
            using (new ProfilingScope(cmd, sampler))
            {
                var draw = CreateDrawingSettings(tag, ref data, SortingCriteria.CommonOpaque);
                // Use objects' own materials; no override material here.
                ctx.ExecuteCommandBuffer(cmd);
                cmd.Clear();
                ctx.DrawRenderers(data.cullResults, ref draw, ref filter, ref state);
            }
            ctx.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }

    public Settings settings = new Settings();
    VolumeStencilPass volumePass;
    DrawOccludablesPass drawPass;

    public override void Create()
    {
        volumePass = new VolumeStencilPass(settings.volumeLayer, settings.stencilWriteMaterial);
        drawPass = new DrawOccludablesPass(settings.occludableLayer);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData data)
    {
        if (settings.stencilWriteMaterial == null) return;

        // Keep layers up to date (editable at runtime)
        volumePass.UpdateForFrame(settings.volumeLayer, settings.stencilWriteMaterial);
        drawPass.UpdateForFrame(settings.occludableLayer);

        // Enqueue: first write stencil, then draw occluders with stencil test
        renderer.EnqueuePass(volumePass);
        renderer.EnqueuePass(drawPass);
    }
}
