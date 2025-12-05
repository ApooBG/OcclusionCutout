using UnityEngine;

[ExecuteAlways]
public class BubbleOcclusionController : MonoBehaviour
{
    [Header("Materials")]
    public Material cutoutFront;
    public Material cutoutBack;
    public Material cutoutEdge;   

    [Header("References")]
    public Transform player;
    public Transform cameraTransform;

    void Update()
    {
        if (player == null || cameraTransform == null)
            return;

        Vector3 pos = transform.position;
        float radius = transform.lossyScale.x * 0.5f;

        UpdateMat(cutoutFront, pos, radius);
        UpdateMat(cutoutBack, pos, radius);
        UpdateMat(cutoutEdge, pos, radius);
    }

    void UpdateMat(Material m, Vector3 pos, float radius)
    {
        if (m == null) return;

        m.SetVector("_SpherePosition", pos);
        m.SetFloat("_SphereRadius", radius);
        m.SetVector("_CameraWorldPos", cameraTransform.position);
        m.SetVector("_PlayerWorldPos", player.position);
    }



}
