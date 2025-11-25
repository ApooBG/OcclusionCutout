using System.Collections.Generic;
using UnityEngine;

public class SimpleOcclusionHandler : MonoBehaviour
{
    [Header("References")]
    public Transform player;
    public Camera cam;
    public Transform sphere;

    [Header("Settings")]
    public float yOffset = 0.0f;
    public string occludableLayer = "Occludable";

    [SerializeField] private float rayRadius = 0f; // width of detection ray
    [SerializeField] private List<string> ignoreLayers = new List<string>(); // layers that should never be occluded

    private Dictionary<GameObject, int> originalLayers = new Dictionary<GameObject, int>();
    private List<GameObject> currentlyOccluded = new List<GameObject>();

    private bool sphereYLocked = false;
    private float lockedY = 0f;

    void Update()
    {
        HandleOcclusion();
    }

    void HandleOcclusion()
    {
        Vector3 origin = player.position;
        Vector3 direction = cam.transform.position - origin;
        float distance = direction.magnitude;

        //
        // 1) Narrow ray for EXACT sphere placement
        //
        RaycastHit[] narrowHits = Physics.RaycastAll(origin, direction.normalized, distance);
        bool hasNarrowHit = narrowHits.Length > 0;

        //
        // 2) Wide ray for occlusion detection
        //
        RaycastHit[] wideHits =
            (rayRadius > 0f)
            ? Physics.SphereCastAll(origin, rayRadius, direction.normalized, distance)
            : narrowHits;

        //
        // --- No hit → disable sphere ---
        //
        if (!hasNarrowHit)
        {
            ResetAll();
            sphere.gameObject.SetActive(false);
            sphereYLocked = false;
            return;
        }

        //
        // Sphere active
        //
        if (!sphere.gameObject.activeSelf)
            sphere.gameObject.SetActive(true);

        //
        // Sort narrow hits for accurate placement
        //
        System.Array.Sort(narrowHits, (a, b) => a.distance.CompareTo(b.distance));
        Vector3 hitPoint = narrowHits[0].point;

        //
        // Lock Y once
        //
        if (!sphereYLocked)
        {
            lockedY = hitPoint.y + yOffset;
            sphereYLocked = true;
        }

        // Move sphere only in XZ
        sphere.position = new Vector3(hitPoint.x, lockedY, hitPoint.z);

        //
        // --- Handle occludable objects ---
        //
        List<GameObject> hitObjects = new List<GameObject>();

        foreach (var h in wideHits)
        {
            GameObject obj = h.collider.gameObject;

            //
            // Skip ignored layers
            //
            if (ignoreLayers.Contains(LayerMask.LayerToName(obj.layer)))
                continue;

            if (!hitObjects.Contains(obj))
                hitObjects.Add(obj);
        }

        //
        // Apply occludable layer
        //
        foreach (GameObject obj in hitObjects)
        {
            if (!originalLayers.ContainsKey(obj))
            {
                originalLayers[obj] = obj.layer;
                obj.layer = LayerMask.NameToLayer(occludableLayer);
            }
        }

        //
        // Restore objects no longer hit
        //
        for (int i = currentlyOccluded.Count - 1; i >= 0; i--)
        {
            GameObject obj = currentlyOccluded[i];

            if (!hitObjects.Contains(obj))
            {
                // Skip ignored layers
                if (ignoreLayers.Contains(LayerMask.LayerToName(obj.layer)))
                    continue;

                if (originalLayers.ContainsKey(obj))
                {
                    obj.layer = originalLayers[obj];
                    originalLayers.Remove(obj);
                }

                currentlyOccluded.RemoveAt(i);
            }
        }

        currentlyOccluded = hitObjects;
    }

    void ResetAll()
    {
        foreach (var kvp in originalLayers)
            kvp.Key.layer = kvp.Value;

        originalLayers.Clear();
        currentlyOccluded.Clear();
    }
}
