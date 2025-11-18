using System.Collections.Generic;
using UnityEngine;

public class HideIfNotOccController : MonoBehaviour
{
    [SerializeField] private List<HideIfNotOccludable> pipes;

    [Header("Smoothing")]
    [SerializeField] private float smoothSpeed = 12f;

    // index boundary between visible and hidden segments
    private float smoothedLastOccIndex;

    private void Start()
    {
        // start with all visible
        smoothedLastOccIndex = pipes.Count - 1;
    }

    private void LateUpdate()
    {
        UpdateVisibility();
    }

    private void UpdateVisibility()
    {
        int lastOccIndex = -1;

        // find last pipe that collides with an occludable object
        for (int i = 0; i < pipes.Count; i++)
        {
            if (pipes[i].isColliding)
                lastOccIndex = i;
        }

        // if nothing is colliding: keep everything ON
        if (lastOccIndex == -1)
        {
            smoothedLastOccIndex = Mathf.Lerp(
                smoothedLastOccIndex,
                pipes.Count - 1,
                Time.deltaTime * smoothSpeed
            );
        }
        else
        {
            smoothedLastOccIndex = Mathf.Lerp(
                smoothedLastOccIndex,
                lastOccIndex,
                Time.deltaTime * smoothSpeed
            );
        }

        ApplyVisibility();
    }

    private void ApplyVisibility()
    {
        for (int i = 0; i < pipes.Count; i++)
        {
            if (i <= smoothedLastOccIndex)
            {
                // from camera up to last occluder → visible
                pipes[i].Show();
            }
            else
            {
                // between last occluder and player → hidden
                pipes[i].Hide();
            }
        }
    }
}
