using UnityEngine;

public class PlayerOcclusionDetector : MonoBehaviour
{
    [Header("References")]
    public Transform player;     // Assign your player transform
    public Camera mainCamera;    // Assign your main camera

    [Header("Settings")]
    public Color visibleColor = Color.green;
    public Color occludedColor = Color.red;
    public float headHeight = 1.0f; // Adjust for your player height

    private void Update()
    {
        if (player == null || mainCamera == null)
            return;

        Vector3 camPos = mainCamera.transform.position;
        Vector3 playerHeadPos = player.position + Vector3.up * headHeight;
        Vector3 direction = playerHeadPos - camPos;
        float distance = direction.magnitude;

        // Perform raycast
        if (Physics.Raycast(camPos, direction.normalized, out RaycastHit hit, distance))
        {
            // If the ray hits something before reaching the player
            if (hit.transform != player && !hit.transform.IsChildOf(player))
            {
                Debug.DrawLine(camPos, hit.point, occludedColor); // Draw red to hit point
                Debug.Log($"🔴 Player occluded by: {hit.transform.name}");
            }
            else
            {
                Debug.DrawLine(camPos, playerHeadPos, visibleColor); // Green to player
                Debug.Log("🟢 Player visible");
            }
        }
        else
        {
            // If nothing blocks the ray
            Debug.DrawLine(camPos, playerHeadPos, visibleColor);
            Debug.Log("🟢 Player visible");
        }
    }
}
