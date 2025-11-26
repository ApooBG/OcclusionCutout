using UnityEngine;

public class LookAtCamera : MonoBehaviour
{
    [Header("References")]
    public Camera mainCamera;

    [Header("Settings")]
    [Tooltip("The local axis that should face the camera (X, Y, or Z).")]
    [SerializeField] private Axis faceAxis = Axis.Z;

    public enum Axis { X, Y, Z }

    private void LateUpdate()
    {
        if (!mainCamera)
        {
            mainCamera = Camera.main;
            if (!mainCamera)
                return;
        }

        // Get direction toward camera
        Vector3 directionToCam = mainCamera.transform.position - transform.position;

        if (directionToCam.sqrMagnitude < 0.001f)
            return;

        Quaternion lookRot = Quaternion.LookRotation(directionToCam.normalized, Vector3.up);

        // Adjust rotation based on which local axis should face the camera
        switch (faceAxis)
        {
            case Axis.X:
                transform.rotation = lookRot * Quaternion.Euler(0f, 90f, 0f);
                break;
            case Axis.Y:
                transform.rotation = lookRot * Quaternion.Euler(90f, 0f, 0f);
                break;
            case Axis.Z:
                transform.rotation = lookRot;
                break;
        }
    }
}
