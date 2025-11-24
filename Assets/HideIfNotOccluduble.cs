using UnityEngine;

public class HideIfNotOccludable : MonoBehaviour
{
    public MeshRenderer pipe;
    public MeshRenderer pipeInterior;

    public bool IsVisible { get; private set; }

    public void Show()
    {
        if (!IsVisible)
        {
            IsVisible = true;
            pipe.enabled = true;
            pipeInterior.enabled = true;
        }
    }

    public void Hide()
    {
        if (IsVisible)
        {
            IsVisible = false;
            pipe.enabled = false;
            pipeInterior.enabled = false;
        }
    }
}
