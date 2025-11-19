using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
[RequireComponent(typeof(MeshFilter))]
public class PipeWallClip : MonoBehaviour
{
    public LayerMask occludableLayer;
    public Material pipeMat;
    private List<Bounds> intersectingBounds = new();

    void Update()
    {
        intersectingBounds.Clear();

        Collider[] hits = Physics.OverlapBox(transform.position, transform.localScale * 0.5f, transform.rotation, occludableLayer);
        foreach (var hit in hits)
            intersectingBounds.Add(hit.bounds);

        UpdateMaterial();
    }

    void UpdateMaterial()
    {
        Vector4[] centers = new Vector4[intersectingBounds.Count];
        Vector4[] sizes = new Vector4[intersectingBounds.Count];

        for (int i = 0; i < intersectingBounds.Count; i++)
        {
            Bounds b = intersectingBounds[i];
            centers[i] = new Vector4(b.center.x, b.center.y, b.center.z, 0);
            sizes[i] = new Vector4(b.extents.x, b.extents.y, b.extents.z, 0);
        }

        pipeMat.SetInt("_BoundsCount", intersectingBounds.Count);
        pipeMat.SetVectorArray("_BoundsCenters", centers);
        pipeMat.SetVectorArray("_BoundsExtents", sizes);
    }
}
