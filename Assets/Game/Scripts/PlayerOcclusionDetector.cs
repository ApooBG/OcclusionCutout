using System.Collections.Generic;
using UnityEngine;
using System.Linq;
using System.Collections;
using UnityEngine.ProBuilder.Shapes;

public class PlayerOcclusionDetector : MonoBehaviour
{
    [Header("References")]
    public Transform player;
    public Camera mainCamera;
    public GameObject cylinderOcclusion;

    [Header("Settings")]
    public Color visibleColor = Color.green;
    public Color occludedColor = Color.red;
    public float headHeight = 1.0f;
    public float moveSmoothness = 10f;
    public float baseRadius = 1.0f;
    public float scaleUpTime = 0.3f;
    [SerializeField, Tooltip("How wide the raycast should be to detect nearby walls.")]
    private float occlusionCheckRadius = 0.3f; // You can tune this in the inspector
    public string occludableLayerName = "Occludable";

    [Header("Fine-tune alignment")]
    [SerializeField] private float offsetUp = 0.5f;       // Moves it vertically
    [SerializeField] private float offsetForward = 0.0f;  // Moves it along the ray

    private readonly Dictionary<Transform, int> originalLayers = new();
    private List<Transform> currentOccluders = new();
    Vector3 targetScale;


    private Coroutine currentAnim;

    private void Start()
    {
        targetScale = cylinderOcclusion.transform.localScale;
    }

    void Update()
    {
        if (!player || !mainCamera || !cylinderOcclusion)
            return;

        Vector3 camPos = mainCamera.transform.position;
        Vector3 playerHeadPos = player.position + Vector3.up * headHeight;
        Vector3 direction = (playerHeadPos - camPos).normalized;
        float distance = Vector3.Distance(camPos, playerHeadPos);

        // get all hits along the ray
        // use spherecast instead of single ray to catch nearby geometry
        RaycastHit[] hits;

        if (occlusionCheckRadius > 0f)
        {
            // SphereCastAll detects wider walls / corners
            hits = Physics.SphereCastAll(camPos, occlusionCheckRadius, direction, distance, ~0, QueryTriggerInteraction.Ignore);
        }
        else
        {
            // fallback to regular raycast if radius = 0
            hits = Physics.RaycastAll(camPos, direction, distance, ~0, QueryTriggerInteraction.Ignore);
        }

        hits = hits
            .Where(h => h.transform != player && !h.transform.IsChildOf(player))
            .OrderBy(h => h.distance)
            .ToArray();

        hits = hits.Where(h => h.transform != player && !h.transform.IsChildOf(player)).OrderBy(h => h.distance).ToArray();

        if (hits.Length > 0)
        {
            Debug.DrawLine(camPos, playerHeadPos, occludedColor);

            if (!cylinderOcclusion.activeSelf)
            {
                cylinderOcclusion.SetActive(true);

                // start scale-up animation each time it’s activated
                if (currentAnim != null)
                    StopCoroutine(currentAnim);
                currentAnim = StartCoroutine(ScaleUpCylinderAnimation(cylinderOcclusion));
            }

            HandleOccluders(hits.Select(h => h.transform).ToList());

            Vector3 entryPoint = hits.First().point;
            Vector3 exitPoint;

            // ✅ if there are multiple occluding colliders, use the farthest one
            if (hits.Length > 1)
                exitPoint = hits.Last().point;
            else
            {
                // ✅ otherwise, shoot a second ray *through the same collider*
                Collider c = hits[0].collider;
                Vector3 insideStart = entryPoint + direction * 0.01f;
                if (c.Raycast(new Ray(insideStart, direction), out RaycastHit exitHit, distance))
                    exitPoint = exitHit.point;
                else
                    // fallback: extend a small distance so thickness never becomes zero
                    exitPoint = entryPoint + direction * 0.5f;
            }

            float totalThickness = Mathf.Max(Vector3.Distance(entryPoint, exitPoint), 0.05f);
            Vector3 midPoint = (entryPoint + exitPoint) * 0.5f;

            // rotation and scale
            //cylinderOcclusion.transform.rotation = Quaternion.LookRotation(direction, Vector3.up);
            //cylinderOcclusion.transform.localScale = new Vector3(baseRadius, totalThickness * 0.5f, baseRadius);

            // small manual vertical tweak (if you still need it)
            Vector3 targetPos = midPoint + Vector3.up * offsetUp + direction * offsetForward;

            //cylinderOcclusion.transform.position = Vector3.Lerp(
            //    cylinderOcclusion.transform.position, targetPos, Time.deltaTime * moveSmoothness);
        }
        else
        {
            ClearOccluders();
            HideCylinder(camPos, playerHeadPos);
        }
    }

    private IEnumerator ScaleUpCylinderAnimation(GameObject cylinder)
    {
        // Store original (target) scale

        // Start from tiny
        cylinder.transform.localScale = new Vector3(0.01f, 0.01f, 0.01f);

        float elapsed = 0f;
        while (elapsed < scaleUpTime)
        {
            elapsed += Time.deltaTime;
            float t = Mathf.Clamp01(elapsed / scaleUpTime);
            t = Mathf.SmoothStep(0, 1, t); // ease-in-out curve
            cylinder.transform.localScale = Vector3.Lerp(cylinder.transform.localScale, targetScale, t);
            yield return null;
        }

        cylinder.transform.localScale = targetScale;
    }

    private void HandleOccluders(List<Transform> occluders)
    {
        // Restore all old occluders
        foreach (var prev in currentOccluders)
        {
            if (!occluders.Contains(prev))
                RestoreLayer(prev);
        }

        currentOccluders.Clear();
        currentOccluders.AddRange(occluders);

        int occludableLayer = LayerMask.NameToLayer(occludableLayerName);
        if (occludableLayer == -1)
        {
            Debug.LogWarning($"Layer '{occludableLayerName}' not found. Please create it in Project Settings > Tags and Layers.");
            return;
        }

        foreach (var o in occluders)
        {
            if (!originalLayers.ContainsKey(o))
                originalLayers[o] = o.gameObject.layer;

            o.gameObject.layer = occludableLayer;
        }
    }

    private void ClearOccluders()
    {
        foreach (var t in currentOccluders)
            RestoreLayer(t);

        currentOccluders.Clear();
    }

    private void RestoreLayer(Transform t)
    {
        if (t && originalLayers.TryGetValue(t, out int oldLayer))
        {
            t.gameObject.layer = oldLayer;
            originalLayers.Remove(t);
        }
    }

    private void HideCylinder(Vector3 camPos, Vector3 playerHeadPos)
    {
        Debug.DrawLine(camPos, playerHeadPos, visibleColor);
        if (cylinderOcclusion.activeSelf)
            cylinderOcclusion.SetActive(false);
    }
}
