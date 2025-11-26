using Unity.Mathematics;
using UnityEngine;

[ExecuteAlways]
[RequireComponent(typeof(MeshFilter))]
public class BlobbySphereDeformer : MonoBehaviour
{
    [Header("Noise Settings")]
    [Tooltip("How strongly vertices are pushed in/out from the center.")]
    public float amplitude = 0.2f;          // how much to break the circle

    [Tooltip("Frequency of the noise pattern on the sphere surface.")]
    public float frequency = 3f;

    [Tooltip("Seed to get different random shapes.")]
    public int seed = 1234;

    [Header("Options")]
    [Tooltip("Apply deformation continuously (in editor + play mode). Turn off to keep it static.")]
    public bool updateEveryFrame = false;

    [Tooltip("Rebuild the deformed mesh when parameters change.")]
    public bool autoRebuildOnChange = true;

    private MeshFilter meshFilter;
    private Mesh originalMesh;
    private Mesh deformedMesh;

    // cache hash of last settings to detect changes
    private int lastSeed;
    private float lastAmplitude;
    private float lastFrequency;

    void OnEnable()
    {
        meshFilter = GetComponent<MeshFilter>();
        if (meshFilter == null || meshFilter.sharedMesh == null)
        {
            Debug.LogWarning($"{nameof(BlobbySphereDeformer)} on {name}: No MeshFilter or mesh found.");
            return;
        }

        // Keep a copy of the original mesh so we don't destroy the asset
        if (originalMesh == null)
        {
            // Use sharedMesh as source
            originalMesh = meshFilter.sharedMesh;
        }

        if (deformedMesh == null)
        {
            deformedMesh = Instantiate(originalMesh);
            deformedMesh.name = originalMesh.name + "_BlobbyCopy";
        }

        meshFilter.sharedMesh = deformedMesh;

        Rebuild();
        StoreLastSettings();
    }

    void OnDisable()
    {
        // Optionally restore the original mesh when disabling
        if (meshFilter != null && originalMesh != null)
        {
            meshFilter.sharedMesh = originalMesh;
        }
    }

    void Update()
    {
#if UNITY_EDITOR
        if (!Application.isPlaying)
        {
            if (autoRebuildOnChange && SettingsChanged())
            {
                Rebuild();
                StoreLastSettings();
            }
        }
#endif

        if (updateEveryFrame && Application.isPlaying)
        {
            Rebuild();
        }
    }

    private bool SettingsChanged()
    {
        return lastSeed != seed ||
               !Mathf.Approximately(lastAmplitude, amplitude) ||
               !Mathf.Approximately(lastFrequency, frequency);
    }

    private void StoreLastSettings()
    {
        lastSeed = seed;
        lastAmplitude = amplitude;
        lastFrequency = frequency;
    }

    [ContextMenu("Rebuild Now")]
    public void Rebuild()
    {
        if (originalMesh == null || deformedMesh == null)
            return;

        Vector3[] srcVerts = originalMesh.vertices;
        Vector3[] srcNormals = originalMesh.normals;

        if (srcNormals == null || srcNormals.Length != srcVerts.Length)
        {
            // If no normals, recalc on original temporarily
#if UNITY_EDITOR
            originalMesh.RecalculateNormals();
            srcNormals = originalMesh.normals;
#else
            return;
#endif
        }

        Vector3[] dstVerts = new Vector3[srcVerts.Length];

        // Use a pseudo-random offset so different seeds give different blobs
        float seedOffset = seed * 0.1234f;

        for (int i = 0; i < srcVerts.Length; i++)
        {
            Vector3 v = srcVerts[i];
            Vector3 n = srcNormals[i].normalized;

            // Compute spherical-ish coordinates from normal for sampling
            // (works well if the mesh is roughly a sphere centered at origin)
            float3 dir = new float3(n.x, n.y, n.z); // conceptual; we only use xz
            float2 uv = new Vector2(n.x, n.z) * frequency + new Vector2(seedOffset, seedOffset);

            // Unity has 2D PerlinNoise
            float noise = Mathf.PerlinNoise(uv.x, uv.y); // 0..1
            float signed = (noise - 0.5f) * 2.0f;        // -1..1

            float offset = signed * amplitude;

            // Push vertex along its normal
            dstVerts[i] = v + n * offset;
        }

        deformedMesh.vertices = dstVerts;
        deformedMesh.RecalculateNormals();
        deformedMesh.RecalculateBounds();
    }
}
