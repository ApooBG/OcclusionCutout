using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
[RequireComponent(typeof(MeshRenderer), typeof(MeshFilter))]
public class PipeWallClip : MonoBehaviour
{
    public LayerMask occludableLayer;

    private List<Bounds> intersectingBounds = new();
    private Renderer rend;
    private MaterialPropertyBlock propBlock;

    void Awake()
    {
        rend = GetComponent<Renderer>();
        propBlock = new MaterialPropertyBlock();
    }

    void Update()
    {
        if (rend == null)
            rend = GetComponent<Renderer>();

        if (propBlock == null)
            propBlock = new MaterialPropertyBlock();

        intersectingBounds.Clear();

        Collider[] hits = Physics.OverlapBox(transform.position, transform.localScale * 0.5f, transform.rotation, occludableLayer);
        foreach (var hit in hits)
            intersectingBounds.Add(hit.bounds);

        UpdateMaterialProperties();
    }



    void UpdateMaterialProperties()
    {
        if (intersectingBounds.Count == 0)
        {
            rend.GetPropertyBlock(propBlock);
            propBlock.SetInt("_BoundsCount", 0);
            rend.SetPropertyBlock(propBlock);
            return;
        }

        Vector4[] centers = new Vector4[intersectingBounds.Count];
        Vector4[] sizes = new Vector4[intersectingBounds.Count];

        for (int i = 0; i < intersectingBounds.Count; i++)
        {
            Bounds b = intersectingBounds[i];
            centers[i] = new Vector4(b.center.x, b.center.y, b.center.z, 0);
            sizes[i] = new Vector4(b.extents.x, b.extents.y, b.extents.z, 0);
        }

        rend.GetPropertyBlock(propBlock);
        propBlock.SetInt("_BoundsCount", intersectingBounds.Count);
        propBlock.SetVectorArray("_BoundsCenters", centers);
        propBlock.SetVectorArray("_BoundsExtents", sizes);
        rend.SetPropertyBlock(propBlock);
    }

}
