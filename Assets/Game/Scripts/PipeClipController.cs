using UnityEngine;

[ExecuteAlways]
public class PipeClipController : MonoBehaviour
{
    public Material pipeMat;
    public Transform playerCam;
    public Transform player;
    public LayerMask occlusionMask;
    public float maxDistance = 100f;
    public float endOffset = 1f; // Adjustable in inspector

    void Update()
    {
        if (!pipeMat || !playerCam || !player) return;

        Vector3 camOrigin = playerCam.position;
        Vector3 playerOrigin = player.position;
        Vector3 dir = (player.position - camOrigin).normalized;

        pipeMat.SetVector("_CameraWorldPos", camOrigin);

        bool camHit = Physics.Raycast(camOrigin, dir, out RaycastHit camRayHit, maxDistance, occlusionMask);
        bool playerHit = Physics.Raycast(playerOrigin, -dir, out RaycastHit playerRayHit, maxDistance, occlusionMask);

        if (camHit && playerHit)
        {
            float start = Vector3.Distance(camOrigin, camRayHit.point);
            float end = Vector3.Distance(camOrigin, playerRayHit.point) + endOffset;

            if (end < start) (start, end) = (end, start);

            pipeMat.SetFloat("_StartDistance", start);
            pipeMat.SetFloat("_EndDistance", end);
        }
        else
        {
            pipeMat.SetFloat("_StartDistance", 0f);
            pipeMat.SetFloat("_EndDistance", 0f);
        }
    }
}
