using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class PipeRenderFeature : ScriptableRendererFeature
{
    class PipePass : ScriptableRenderPass
    {
        Material pipeMat;
        string profilerTag = "Render Pipe";

        public PipePass(Material mat)
        {
            this.pipeMat = mat;
            renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get(profilerTag);
            var meshObjects = GameObject.FindGameObjectsWithTag("Pipe"); // Tag your pipe object

            foreach (var obj in meshObjects)
            {
                var mf = obj.GetComponent<MeshFilter>();
                var mr = obj.GetComponent<MeshRenderer>();
                if (!mf || !mr) continue;

                cmd.DrawMesh(mf.sharedMesh, obj.transform.localToWorldMatrix, pipeMat);
            }

            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }

    public Material pipeMaterial;
    PipePass pass;

    public override void Create()
    {
        pass = new PipePass(pipeMaterial);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(pass);
    }
}
