using System.Collections.Generic;
using UnityEngine;

public class HideIfNotOccController : MonoBehaviour
{
    [SerializeField] List<HideIfNotOccludable> pipes;
    [SerializeField] LayerMask occludableMask;

    // same box size for all pipes
    [SerializeField] Vector3 overlapHalfSize = new Vector3(0.5f, 0.5f, 0.5f);

    void LateUpdate()
    {
        UpdateVisibility();
    }

    void UpdateVisibility()
    {
        int lastCollidingIndex = -1;

        for (int i = 0; i < pipes.Count; i++)
        {
            HideIfNotOccludable pipe = pipes[i];

            // perform overlap box test at pipe position
            bool colliding = Physics.CheckBox(
                pipe.transform.position,
                overlapHalfSize,
                pipe.transform.rotation,
                occludableMask
            );

            if (colliding)
                lastCollidingIndex = i;
        }

        // apply visibility rules
        for (int i = 0; i < pipes.Count; i++)
        {
            if (i <= lastCollidingIndex)
                pipes[i].Show();
            else
                pipes[i].Hide();
        }
    }

    void OnDrawGizmosSelected()
    {
        // visualize boxes for debugging
        Gizmos.color = Color.yellow;
        foreach (var pipe in pipes)
        {
            Gizmos.DrawWireCube(pipe.transform.position, overlapHalfSize * 2f);
        }
    }
}
