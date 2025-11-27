using System.Collections.Generic;
using UnityEngine;

public class SimpleOcclusionHandlerSphere : MonoBehaviour
{
    [Header("References")]
    public Transform player;
    public Camera cam;
    public Transform sphere;

    [Header("Settings")]
    public float yOffset = 0.0f;
    public string occludableLayer = "Occludable";

    [SerializeField] private float rayRadius = 0f;
    [SerializeField] private List<string> ignoreLayers = new List<string>();

    [Header("Cutout Adjustments")]
    [SerializeField] private Vector3 positionOffset = Vector3.zero;
    [SerializeField] private float smoothSpeed = 12f;
    [SerializeField] private float scaleUpTime = 0.16f;
    [SerializeField] private float noramlScale = 1.3f;

    [Header("Debug")]
    [SerializeField] private bool drawRay = true;
    [SerializeField] private float rayWidth = 0.02f;
    [SerializeField] private Color rayColor = Color.red;


    private Dictionary<GameObject, int> originalLayers = new Dictionary<GameObject, int>();
    private List<GameObject> currentlyOccluded = new List<GameObject>();
    private List<GameObject> sphereTouchedObjects = new List<GameObject>();
    List<GameObject> hitObjects = new List<GameObject>();

    private Vector3 targetPosition;
    private Vector3 originalScale;
    private float scaleLerpTime = 0f;
    private bool isScaling = false;

    // ----------------------------------------------
    // Init
    // ----------------------------------------------
    void Start()
    {
        if (sphere != null)
        {
            originalScale = sphere.localScale * noramlScale;
            sphere.localScale = Vector3.zero;

            // Ensure sphere has a trigger collider
            SphereCollider col = sphere.GetComponent<SphereCollider>();
            if (col == null)
                col = sphere.gameObject.AddComponent<SphereCollider>();

            col.isTrigger = true;
        }
    }

    void Update()
    {
        HandleOcclusion();

        // Smooth sphere movement
        if (sphere.gameObject.activeSelf)
        {
            sphere.position = Vector3.Lerp(sphere.position, targetPosition, Time.deltaTime * smoothSpeed);

            // Smooth scale-up
            if (isScaling)
            {
                scaleLerpTime += Time.deltaTime / scaleUpTime;
                sphere.localScale = Vector3.Lerp(Vector3.zero, originalScale, scaleLerpTime);

                if (scaleLerpTime >= 1f)
                    isScaling = false;
            }
        }
    }

    // ----------------------------------------------
    // Main occlusion logic
    // ----------------------------------------------
    void HandleOcclusion()
    {
        hitObjects.Clear();
        Vector3 origin = player.position;
        Vector3 direction = cam.transform.position - origin;
        float distance = direction.magnitude;
        Ray mainRay = new Ray(origin, direction.normalized);

        // ----------------------------
        // Debug Ray Visualization
        // ----------------------------
        if (drawRay)
        {
            // Main ray
            Debug.DrawRay(origin, direction.normalized * distance, rayColor);

            // Wide debug ray
            if (rayWidth > 0f)
            {
                Vector3 right = cam.transform.right * rayWidth;
                Vector3 up = cam.transform.up * rayWidth;

                Debug.DrawLine(origin + right, origin + right + direction.normalized * distance, rayColor);
                Debug.DrawLine(origin - right, origin - right + direction.normalized * distance, rayColor);

                Debug.DrawLine(origin + up, origin + up + direction.normalized * distance, rayColor);
                Debug.DrawLine(origin - up, origin - up + direction.normalized * distance, rayColor);
            }
        }

        RaycastHit[] narrowHits = Physics.RaycastAll(mainRay.origin, mainRay.direction, distance);

        List<RaycastHit> wideHitList = new List<RaycastHit>();

        if (rayWidth > 0f)
        {
            Vector3[] offsets = new Vector3[]
            {
        Vector3.zero,
        cam.transform.right * rayWidth,
        -cam.transform.right * rayWidth,
        cam.transform.up * rayWidth,
        -cam.transform.up * rayWidth
            };

            foreach (var offset in offsets)
            {
                Vector3 offsetOrigin = origin + offset;
                RaycastHit[] hits = Physics.RaycastAll(offsetOrigin, direction.normalized, distance);
                wideHitList.AddRange(hits);
            }
        }
        else
        {
            wideHitList.AddRange(narrowHits);
        }


        RaycastHit[] wideHits = wideHitList.ToArray();


        // Step 1: Handle collider-based hits
        foreach (var h in wideHits)
        {
            GameObject obj = h.collider.gameObject;

            if (ignoreLayers.Contains(LayerMask.LayerToName(obj.layer)))
                continue;

            if (!hitObjects.Contains(obj))
                hitObjects.Add(obj);
        }

        // Step 2: Handle non-collider renderers using bounds intersection
        Renderer[] allRenderers = FindObjectsOfType<Renderer>();
        Ray occlusionRay = mainRay;

        foreach (var rend in allRenderers)
        {
            GameObject obj = rend.gameObject;

            if (ignoreLayers.Contains(LayerMask.LayerToName(obj.layer)))
                continue;

            if (hitObjects.Contains(obj))
                continue; // already hit via collider

            if (rend.bounds.IntersectRay(occlusionRay))
            {
                float hitDist = Vector3.Distance(origin, rend.bounds.ClosestPoint(origin));
                if (hitDist <= distance)
                {
                    hitObjects.Add(obj);
                }
            }
        }

        bool hasVisualHit = hitObjects.Count > 0;
        // No hit -> disable sphere and reset
        if (!hasVisualHit)
        {
            ResetAll();
            sphere.gameObject.SetActive(false);
            return;
        }

        // Activate sphere if needed
        if (!sphere.gameObject.activeSelf)
        {
            sphere.gameObject.SetActive(true);
            sphere.localScale = Vector3.zero;
            scaleLerpTime = 0f;
            isScaling = true;
        }

        // Position sphere at first narrow hit
        Vector3 hitPoint = origin + direction.normalized * Mathf.Min(distance, 3f); // Fallback estimate

        if (narrowHits.Length > 0)
        {
            System.Array.Sort(narrowHits, (a, b) => a.distance.CompareTo(b.distance));
            hitPoint = narrowHits[0].point;
        }

        // Add camera-space offset
        Vector3 camF = cam.transform.forward;
        Vector3 camR = cam.transform.right;
        Vector3 camU = cam.transform.up;

        targetPosition =
            hitPoint +
            camF * positionOffset.z +
            camR * positionOffset.x +
            camU * positionOffset.y;

        // Collect occludable objects from raycasts

        foreach (var h in wideHits)
        {
            GameObject obj = h.collider.gameObject;

            // Skip ignored layers
            if (ignoreLayers.Contains(LayerMask.LayerToName(obj.layer)))
                continue;

            if (!hitObjects.Contains(obj))
                hitObjects.Add(obj);
        }

        // Add sphere-touch objects
        foreach (GameObject touched in sphereTouchedObjects)
        {
            if (!hitObjects.Contains(touched))
                hitObjects.Add(touched);
        }

        // Apply occludable layer to all active hits
        foreach (GameObject obj in hitObjects)
        {
            // Skip ignored
            if (ignoreLayers.Contains(LayerMask.LayerToName(obj.layer)))
                continue;

            if (!originalLayers.ContainsKey(obj))
            {
                originalLayers[obj] = obj.layer;
                obj.layer = LayerMask.NameToLayer(occludableLayer);
            }
        }

        // Restore objects not hit anymore
        for (int i = currentlyOccluded.Count - 1; i >= 0; i--)
        {
            GameObject obj = currentlyOccluded[i];

            // If no longer in active hit/touch list
            if (!hitObjects.Contains(obj))
            {
                if (originalLayers.ContainsKey(obj))
                {
                    obj.layer = originalLayers[obj];
                    originalLayers.Remove(obj);
                }
                currentlyOccluded.RemoveAt(i);
            }
        }

        currentlyOccluded.Clear();
        currentlyOccluded.AddRange(hitObjects);
    }

    // ----------------------------------------------
    // Sphere trigger detection
    // ----------------------------------------------
    private void OnTriggerEnter(Collider other)
    {
        GameObject obj = other.gameObject;

        if (ignoreLayers.Contains(LayerMask.LayerToName(obj.layer)))
            return;

        if (!sphereTouchedObjects.Contains(obj))
            sphereTouchedObjects.Add(obj);
    }

    private void OnTriggerExit(Collider other)
    {
        GameObject obj = other.gameObject;

        if (sphereTouchedObjects.Contains(obj))
            sphereTouchedObjects.Remove(obj);
    }

    // ----------------------------------------------
    // Reset all layers
    // ----------------------------------------------
    void ResetAll()
    {
        foreach (var kvp in originalLayers)
            kvp.Key.layer = kvp.Value;

        originalLayers.Clear();
        currentlyOccluded.Clear();
        sphereTouchedObjects.Clear();
    }
}
