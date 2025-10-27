using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using ProfilingScope = UnityEngine.Rendering.ProfilingScope;

public class DrawOccludablesFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class Settings
    {
        [Tooltip("Layer that contains meshes you want to hide inside the volume.")]
        public LayerMask occludableLayer = 0; // which layer to draw

        [Tooltip("When this is true, the pass runs BeforeRenderingOpaques (recommended).")]
        public bool beforeOpaques = true;  // when to insert the pass 
    }

    class DrawOccludablesPass : ScriptableRenderPass
    {
        //Only draw sub-passes whose LightMode tag is "UniversalForward".
        // (URP/Lit uses this; for full coverage you might also include "UniversalForwardOnly" and "SRPDefaultUnlit".)
        readonly ShaderTagId _tag = new ShaderTagId("UniversalForward"); 
       
        FilteringSettings _filter; //Opaque queue only (no transparents) and only the chosen layer.
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


            //where to run
            renderPassEvent = beforeOpaques ? RenderPassEvent.BeforeRenderingOpaques
                                            : RenderPassEvent.AfterRenderingOpaques;
        }

        public void UpdateForFrame(LayerMask layer)
        {
            _filter.layerMask = layer;
        }


        /*Asks URP to draw culled renderers that match:

            the LightMode tag (UniversalForward),

            the filter (opaque queue + selected LayerMask),

            and the stencil state (NotEqual 1).

            No material override → it uses each object’s own material.

         */
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


    //Instantiates the pass and enqueues it every frame so it runs at the specified event.
    public override void Create()
    {
        _pass = new DrawOccludablesPass(settings.occludableLayer, settings.beforeOpaques);
    }

    //Instantiates the pass and enqueues it every frame so it runs at the specified event.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        _pass.UpdateForFrame(settings.occludableLayer);
        renderer.EnqueuePass(_pass);
    }
}
