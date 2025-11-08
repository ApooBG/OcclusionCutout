using UnityEngine;

public class HideIfNotOccludable : MonoBehaviour
{
    public MeshRenderer pipe;
    public MeshRenderer pipeInterior;
    public LayerMask layerMaskOccludable;

    public bool isColliding = false;

    private void OnTriggerEnter(Collider other)
    {
        if (((1 << other.gameObject.layer) & layerMaskOccludable) != 0)
        {
            //Show();
            isColliding = true;
        }
    }

    private void OnTriggerExit(Collider other)
    {
        if (((1 << other.gameObject.layer) & layerMaskOccludable) != 0)
        {
            //Hide();
            isColliding = false;
        }
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
