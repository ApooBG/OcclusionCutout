using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class DrawOccludablesFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class Settings
    {
        [Tooltip("Layer that contains meshes you want to hide inside the volume.")]
        public LayerMask occludableLayer = 0;

        [Tooltip("When this is true, the pass runs BeforeRenderingOpaques (recommended).")]
        public bool beforeOpaques = true;
    }

    class DrawOccludablesPass : ScriptableRenderPass
    {
        readonly ShaderTagId _tag = new ShaderTagId("UniversalForward");
        FilteringSettings _filter;
        RenderStateBlock _stateBlock;
        ProfilingSampler _sampler = new ProfilingSampler("Draw Occludables (Stencil != 1)");

        public DrawOccludablesPass(LayerMask layer, bool beforeOpaques)
        {
            // Draw only the chosen layer, opaque queue
            _filter = new FilteringSettings(RenderQueueRange.opaque, layer);

            // Stencil: draw where stencil != 1 (the sphere wrote 1)
            var stencil = new StencilState(
                enabled: true,
                readMask: 0xFF,
                writeMask: 0xFF,
                compareFunction: CompareFunction.NotEqual,
                passOperation: StencilOp.Keep,
                failOperation: StencilOp.Keep,
                zFailOperation: StencilOp.Keep
            );

            _stateBlock = new RenderStateBlock(RenderStateMask.Stencil)
            {
                stencilState = stencil,
                stencilReference = 1 // << IMPORTANT: compare against 1
            };

            renderPassEvent = beforeOpaques ? RenderPassEvent.BeforeRenderingOpaques
                                            : RenderPassEvent.AfterRenderingOpaques;
        }

        public void UpdateForFrame(LayerMask layer)
        {
            _filter.layerMask = layer;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var cmd = CommandBufferPool.Get("Draw Occludables (Stencil != 1)");
            using (new ProfilingScope(cmd, _sampler))
            {
                var sort = SortingCriteria.CommonOpaque;
                var drawing = CreateDrawingSettings(_tag, ref renderingData, sort);
                // Use objects' own materials (no override material)
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();

                context.DrawRenderers(renderingData.cullResults, ref drawing, ref _filter, ref _stateBlock);
            }
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }

    public Settings settings = new Settings();
    DrawOccludablesPass _pass;

    public override void Create()
    {
        _pass = new DrawOccludablesPass(settings.occludableLayer, settings.beforeOpaques);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        _pass.UpdateForFrame(settings.occludableLayer);
        renderer.EnqueuePass(_pass);
    }
}
