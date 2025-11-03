using System.Collections.Generic;
using UnityEngine;
using System.Linq;

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
    public string occludableLayerName = "Occludable";

    private readonly Dictionary<Transform, int> originalLayers = new();
    private List<Transform> currentOccluders = new();

    void Update()
    {
        if (!player || !mainCamera || !cylinderOcclusion)
            return;

        Vector3 camPos = mainCamera.transform.position;
        Vector3 playerHeadPos = player.position + Vector3.up * headHeight;
        Vector3 direction = (playerHeadPos - camPos).normalized;
        float distance = Vector3.Distance(camPos, playerHeadPos);

        // 🔹 Get all hits between camera and player
        RaycastHit[] hits = Physics.RaycastAll(camPos, direction, distance, ~0, QueryTriggerInteraction.Ignore);

        // Filter out player hits
        hits = hits.Where(h => h.transform != player && !h.transform.IsChildOf(player)).ToArray();

        if (hits.Length > 0)
        {
            Debug.DrawLine(camPos, playerHeadPos, occludedColor);

            if (!cylinderOcclusion.activeSelf)
                cylinderOcclusion.SetActive(true);

            // Handle layers for all occluding objects
            HandleOccluders(hits.Select(h => h.transform).ToList());

            // 🔹 Find entry and exit points through all occluders
            Vector3 entryPoint = hits.First().point;
            Vector3 exitPoint = hits.Last().point;
            float totalThickness = Vector3.Distance(entryPoint, exitPoint);
            Vector3 midPoint = (entryPoint + exitPoint) * 0.5f;

            // 🔹 Correct rotation and positioning along ray direction
            cylinderOcclusion.transform.position = Vector3.Lerp(
                cylinderOcclusion.transform.position, midPoint, Time.deltaTime * moveSmoothness);

            cylinderOcclusion.transform.rotation = Quaternion.LookRotation(direction, Vector3.up);
            cylinderOcclusion.transform.localScale = new Vector3(baseRadius, totalThickness * 0.5f, baseRadius);
        }
        else
        {
            ClearOccluders();
            HideCylinder(camPos, playerHeadPos);
        }
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
