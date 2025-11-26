using System.Collections.Generic;
using UnityEngine;

public class PlayerOcclusionSphereController : MonoBehaviour
{
    [Header("Stencil Material")]
    public Material sphereStencilMaterial;

    [Header("References")]
    [Tooltip("The player transform (usually the character root or head).")]
    public Transform player;

    [Tooltip("The main camera that looks at the player.")]
    public Camera mainCamera;

    [Tooltip("The sphere object used as the occlusion volume.")]
    public Transform occlusionSphere;

    [Header("Settings")]
    [Tooltip("Radius used for the sphere cast (and roughly the visual radius of the sphere).")]
    public float sphereRadius = 0.5f;

    [Tooltip("Layers that can block the view between player and camera.")]
    public LayerMask blockingLayers = ~0;

    [Tooltip("Layer name that should be used for occludable objects.")]
    public string occludableLayerName = "Occludable";

    [Tooltip("Optional offset from player position (e.g., head height).")]
    public Vector3 playerOffset = Vector3.up;

    private int occludableLayer;
    private readonly Dictionary<Transform, int> originalLayers = new Dictionary<Transform, int>();
    private readonly List<Transform> frameOccluders = new List<Transform>();
    private readonly List<Transform> toRemove = new List<Transform>();

    private void Awake()
    {
        if (player == null)
        {
            Debug.LogError($"{nameof(PlayerOcclusionSphereController)}: Player reference not set.");
        }

        if (mainCamera == null)
        {
            mainCamera = Camera.main;
        }

        if (occlusionSphere == null)
        {
            Debug.LogError($"{nameof(PlayerOcclusionSphereController)}: Occlusion sphere reference not set.");
        }

        occludableLayer = LayerMask.NameToLayer(occludableLayerName);
        if (occludableLayer < 0)
        {
            Debug.LogError($"{nameof(PlayerOcclusionSphereController)}: Layer '{occludableLayerName}' does not exist. Create it in the Tag & Layers settings.");
        }
    }

    private void LateUpdate()
    {
        if (player == null || mainCamera == null || occlusionSphere == null || occludableLayer < 0)
            return;

        Vector3 playerPos = player.position + playerOffset;
        Vector3 camPos = mainCamera.transform.position;

        Vector3 dir = camPos - playerPos;        // player -> camera (IMPORTANT: this direction)
        float dist = dir.magnitude;

        if (dist <= 0.01f)
        {
            occlusionSphere.gameObject.SetActive(false);
            ClearAllOccluders();
            return;
        }

        dir /= dist; // normalize

        // Sphere cast from player towards camera
        RaycastHit[] hits = Physics.SphereCastAll(
            playerPos,
            sphereRadius,
            dir,
            dist,
            blockingLayers,
            QueryTriggerInteraction.Ignore
        );

        if (hits.Length == 0)
        {
            occlusionSphere.gameObject.SetActive(false);
            ClearAllOccluders();
            return;
        }

        // Sort hits by distance from player (we want the first hit from PLAYER -> CAMERA)
        System.Array.Sort(hits, (a, b) => a.distance.CompareTo(b.distance));

        // First blocking object (player -> camera perspective)
        RaycastHit firstHit = hits[0];

        // Make sure the hit is actually between player and camera
        if (firstHit.distance <= 0.0f || firstHit.distance >= dist)
        {
            occlusionSphere.gameObject.SetActive(false);
            ClearAllOccluders();
            return;
        }

        // Position the sphere at the hit point (you said: use that point as the middle of the sphere)
        occlusionSphere.position = firstHit.point;
        occlusionSphere.gameObject.SetActive(true);

        // Track occluders for this frame
        frameOccluders.Clear();

        foreach (var hit in hits)
        {
            // Only consider hits between player and camera
            if (hit.distance <= 0.0f || hit.distance >= dist)
                continue;

            Transform t = hit.collider.transform;

            if (!originalLayers.ContainsKey(t))
            {
                originalLayers[t] = t.gameObject.layer;
            }

            t.gameObject.layer = occludableLayer;
            frameOccluders.Add(t);
        }

        // Revert any previous occluders that are no longer blocking this frame
        RevertNonBlocking();
    }

    private void ClearAllOccluders()
    {
        foreach (var kvp in originalLayers)
        {
            if (kvp.Key != null)
                kvp.Key.gameObject.layer = kvp.Value;
        }
        originalLayers.Clear();
    }

    private void RevertNonBlocking()
    {
        toRemove.Clear();

        foreach (var kvp in originalLayers)
        {
            Transform t = kvp.Key;
            if (t == null)
            {
                toRemove.Add(t);
                continue;
            }

            if (!frameOccluders.Contains(t))
            {
                t.gameObject.layer = kvp.Value;
                toRemove.Add(t);
            }
        }

        foreach (var t in toRemove)
        {
            originalLayers.Remove(t);
        }
    }
}
