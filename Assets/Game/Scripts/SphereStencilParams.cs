using UnityEngine;

[ExecuteAlways]
public class SphereStencilParams : MonoBehaviour
{
    [Header("The collider that defines the REAL collision sphere")]
    public SphereCollider sphereCollider;

    [Header("Material used in the render feature (Hidden/SphereCollisionEdgeStencil)")]
    public Material edgeStencilMaterial;

    // Extra thickness around the true edge, in world units
    public float edgeThickness = 0.03f;

    void LateUpdate()
    {
        if (sphereCollider == null || edgeStencilMaterial == null)
            return;

        var t = sphereCollider.transform;

        // Center of the collider in world space
        Vector3 centerWS = t.TransformPoint(sphereCollider.center);

        // World-space radius (handle scaling)
        float maxScale = Mathf.Max(
            Mathf.Abs(t.lossyScale.x),
            Mathf.Abs(t.lossyScale.y),
            Mathf.Abs(t.lossyScale.z)
        );
        float radiusWS = sphereCollider.radius * maxScale;

        edgeStencilMaterial.SetVector("_SphereCenterWS", centerWS);
        edgeStencilMaterial.SetFloat("_SphereRadius", radiusWS);
        edgeStencilMaterial.SetFloat("_EdgeThickness", edgeThickness);
    }
}
