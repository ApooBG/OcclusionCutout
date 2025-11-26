using UnityEngine;

public class HideIfNotOccludable : MonoBehaviour
{
    public MeshRenderer pipe;
    public MeshRenderer pipeInterior;
    public LayerMask layerMaskOccludable;

    [Header("Collision Settings")]
    public BoxCollider box;        // assign in inspector
    public float overlapShrink = 0.05f;

    [HideInInspector] public bool isColliding;

    private void Reset()
    {
        box = GetComponent<BoxCollider>();
    }

    private void Start()
    {
        // we only use the box as a template for size/position
        if (box != null)
            box.enabled = false;
    }

    private void Update()
    {
        if (box == null)
            return;

        Vector3 center = transform.TransformPoint(box.center);
        Vector3 halfSize = Vector3.Scale(box.size * 0.5f, transform.lossyScale) - Vector3.one * overlapShrink;

        isColliding = Physics.CheckBox(
            center,
            halfSize,
            transform.rotation,
            layerMaskOccludable,
            QueryTriggerInteraction.Ignore
        );
    }

    public void Show()
    {
        pipe.enabled = true;
        pipeInterior.enabled = true;
    }

    public void Hide()
    {
        pipe.enabled = false;
        pipeInterior.enabled = false;
    }
}
