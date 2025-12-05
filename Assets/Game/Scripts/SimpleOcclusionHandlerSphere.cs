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
    [SerializeField] private List<string> ignoreLayers = new List<string>();
    [SerializeField] private float sphereRange = 2f;

    [Header("Cutout Adjustments")]
    [SerializeField] private Vector3 positionOffset = Vector3.zero;
    [SerializeField] private float smoothSpeed = 12f;
    [SerializeField] private float scaleUpTime = 0.16f;
    [SerializeField] private float normalScale = 1.3f;

    [Header("Debug")]
    [SerializeField] private bool drawRay = true;
    [SerializeField] private Color rayColor = Color.red;

    private Dictionary<GameObject, int> originalLayers = new Dictionary<GameObject, int>();
    private List<GameObject> currentlyOccluded = new List<GameObject>();
    private List<GameObject> hitObjects = new List<GameObject>();

    private Vector3 targetPosition;
    private Vector3 originalScale;
    private float scaleLerpTime = 0f;
    private bool isScaling = false;

    void Start()
    {
        if (sphere != null)
        {
            originalScale = sphere.localScale * normalScale;
            sphere.localScale = Vector3.zero;

            SphereCollider col = sphere.GetComponent<SphereCollider>();
            if (col == null)
                col = sphere.gameObject.AddComponent<SphereCollider>();

            col.isTrigger = true;
        }
    }

    void Update()
    {
        HandleOcclusion();

        if (sphere.gameObject.activeSelf)
        {
            sphere.position = Vector3.Lerp(sphere.position, targetPosition, Time.deltaTime * smoothSpeed);

            if (isScaling)
            {
                scaleLerpTime += Time.deltaTime / scaleUpTime;
                sphere.localScale = Vector3.Lerp(Vector3.zero, originalScale, scaleLerpTime);

                if (scaleLerpTime >= 1f)
                    isScaling = false;
            }
        }
    }

    void HandleOcclusion()
    {
        hitObjects.Clear();

        Vector3 origin = player.position + Vector3.up * yOffset;
        Vector3 direction = cam.transform.position - origin;
        float maxDistance = direction.magnitude;
        Ray mainRay = new Ray(origin, direction.normalized);

        if (drawRay)
            Debug.DrawRay(origin, direction, rayColor);

        RaycastHit hit;
        Vector3 hitPoint = origin + direction.normalized * maxDistance * 0.5f;
        if (Physics.Raycast(mainRay, out hit, maxDistance))
            hitPoint = hit.point;

        if (!sphere.gameObject.activeSelf)
        {
            sphere.gameObject.SetActive(true);
            sphere.localScale = Vector3.zero;
            scaleLerpTime = 0f;
            isScaling = true;
        }

        Vector3 camF = cam.transform.forward;
        Vector3 camR = cam.transform.right;
        Vector3 camU = cam.transform.up;

        targetPosition =
            hitPoint +
            camF * positionOffset.z +
            camR * positionOffset.x +
            camU * positionOffset.y;

        Collider[] overlaps = Physics.OverlapSphere(hitPoint, sphereRange);

        foreach (var col in overlaps)
        {
            GameObject obj = col.gameObject;

            if (ignoreLayers.Contains(LayerMask.LayerToName(obj.layer)))
                continue;

            Renderer rend = obj.GetComponent<Renderer>();
            if (rend == null)
                continue;

            Vector3 closestPoint = rend.bounds.ClosestPoint(origin);
            Vector3 toPoint = closestPoint - origin;
            float proj = Vector3.Dot(toPoint.normalized, direction.normalized);

            if (proj > -0.2f && toPoint.magnitude <= maxDistance)
            {
                if (!hitObjects.Contains(obj))
                    hitObjects.Add(obj);
            }
        }

        foreach (GameObject obj in hitObjects)
        {
            if (!originalLayers.ContainsKey(obj))
            {
                originalLayers[obj] = obj.layer;
                obj.layer = LayerMask.NameToLayer(occludableLayer);
            }
        }

        for (int i = currentlyOccluded.Count - 1; i >= 0; i--)
        {
            GameObject obj = currentlyOccluded[i];

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

    void OnDrawGizmos()
    {
        if (!Application.isPlaying) return;
        Gizmos.color = Color.green;
        Gizmos.DrawWireSphere(targetPosition, sphereRange);
    }

    void ResetAll()
    {
        foreach (var kvp in originalLayers)
            kvp.Key.layer = kvp.Value;

        originalLayers.Clear();
        currentlyOccluded.Clear();
    }
}