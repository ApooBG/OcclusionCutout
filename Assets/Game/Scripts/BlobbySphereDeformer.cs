using Unity.Mathematics;
using UnityEngine;

[ExecuteAlways]
[RequireComponent(typeof(MeshFilter))]
public class BlobbySphereDeformer : MonoBehaviour
{
    [Header("Noise Settings")]
    [Tooltip("How strongly vertices are pushed in/out from the center.")]
    public float amplitude = 0.2f;

    [Tooltip("Frequency of the noise pattern on the sphere surface.")]
    public float frequency = 3f;

    [Tooltip("Seed to get different random shapes.")]
    public int seed = 1234;

    [Header("Options")]
    public bool updateEveryFrame = false;
    public bool autoRebuildOnChange = true;

    private MeshFilter meshFilter;
    private Mesh originalMesh;
    private Mesh deformedMesh;

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

        if (originalMesh == null)
            originalMesh = meshFilter.sharedMesh;

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
        if (meshFilter != null && originalMesh != null)
            meshFilter.sharedMesh = originalMesh;
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
        Vector3[] dstVerts = new Vector3[srcVerts.Length];

        // assume sphere is centered at local (0,0,0)
        float seedOffset = seed * 0.1234f;
        float twoPi = math.PI * 2f;

        for (int i = 0; i < srcVerts.Length; i++)
        {
            Vector3 v = srcVerts[i];

            // Direction from center, and original radius
            float radius = v.magnitude;
            if (radius <= 1e-5f)
            {
                dstVerts[i] = v;
                continue;
            }

            Vector3 dir = v / radius;  // normalized

            // Convert direction to "spherical" UV for stable noise:
            // u = azimuth angle (around Y), v = height
            float azimuth = Mathf.Atan2(dir.z, dir.x);       // -pi..pi
            float u = azimuth / twoPi + 0.5f;                // 0..1
            float vCoord = dir.y * 0.5f + 0.5f;              // -1..1 -> 0..1

            Vector2 uv = new Vector2(u, vCoord) * frequency +
                         new Vector2(seedOffset, seedOffset);

            float noise = Mathf.PerlinNoise(uv.x, uv.y);     // 0..1
            float signed = (noise - 0.5f) * 2.0f;            // -1..1

            float offset = signed * amplitude;

            // New radius, only slightly in/out.
            float newRadius = radius + offset;
            // Avoid inverting the sphere on itself
            newRadius = Mathf.Max(radius * 0.1f, newRadius);

            dstVerts[i] = dir * newRadius;
        }

        deformedMesh.vertices = dstVerts;
        deformedMesh.RecalculateNormals();
        deformedMesh.RecalculateBounds();
    }
}
