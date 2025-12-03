using UnityEngine;

[ExecuteAlways]
public class BubbleOcclusionController : MonoBehaviour
{
    public Material overrideMaterial;
    public Transform player;
    public Transform cameraTransform;

    void Update()
    {
        if (overrideMaterial == null || player == null || cameraTransform == null)
            return;

        Vector3 pos = transform.position;
        float radius = transform.lossyScale.x * 0.5f;

        overrideMaterial.SetVector("_SpherePosition", pos);
        overrideMaterial.SetFloat("_SphereRadius", radius);
        overrideMaterial.SetVector("_CameraWorldPos", cameraTransform.position);
        overrideMaterial.SetVector("_PlayerWorldPos", player.position);
    }
}
