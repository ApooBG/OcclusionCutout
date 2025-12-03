using UnityEngine;

[ExecuteAlways]
public class BubbleOcclusionController : MonoBehaviour
{
    public Material overrideMaterial;

    void Update()
    {
        if (overrideMaterial == null) return;

        Vector3 pos = transform.position;
        float radius = transform.lossyScale.x * 0.5f;

        overrideMaterial.SetVector("_SpherePosition", pos);
        overrideMaterial.SetFloat("_SphereRadius", radius);
    }
}
