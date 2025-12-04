using UnityEngine;

[ExecuteAlways]
public class BubbleOcclusionController : MonoBehaviour
{
    [Header("Materials")]
    public Material overrideMaterial;   // main cutout shader (stencil 1/2)
    public Material depthMaterial;      // sphere collision stencil shader (stencil 3)

    [Header("References")]
    public Transform player;
    public Transform cameraTransform;

    [Header("Sphere Settings")]
    [Range(-1, 1)]
    public float sphereSideSign = 0f;
    //  -1 = back side of sphere
    //   0 = full sphere volume
    //  +1 = front side (camera-facing)

    void Update()
    {
        if (player == null || cameraTransform == null)
            return;

        Vector3 pos = transform.position;
        float radius = transform.lossyScale.x * 0.5f;

        // Apply to main cutout material
        if (overrideMaterial != null)
        {
            overrideMaterial.SetVector("_SpherePosition", pos);
            overrideMaterial.SetFloat("_SphereRadius", radius);
            overrideMaterial.SetVector("_CameraWorldPos", cameraTransform.position);
            overrideMaterial.SetVector("_PlayerWorldPos", player.position);
        }

        // Apply to new depth/stencil material
        if (depthMaterial != null)
        {
            depthMaterial.SetVector("_SpherePosition", pos);
            depthMaterial.SetFloat("_SphereRadius", radius);
            depthMaterial.SetVector("_CameraWorldPos", cameraTransform.position);
            depthMaterial.SetVector("_PlayerWorldPos", player.position);
            depthMaterial.SetFloat("_SphereSideSign", sphereSideSign);
        }
    }
}
