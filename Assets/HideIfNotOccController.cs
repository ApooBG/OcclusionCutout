using System.Collections.Generic;
using UnityEngine;

public class HideIfNotOccController : MonoBehaviour
{
    [SerializeField] List<HideIfNotOccludable> pipes;
    bool renderedBeforeCamera = false;
    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        
    }

    // Update is called once per frame
    void LateUpdate()
    {
        CheckCollision();
    }

    void CheckCollision()
    {
        int i = -1;
        foreach (var pipe in pipes)
        {
            i++;
            if (pipe.isColliding)
            {
                pipe.Show();
                ShowPrevious(i);
            }
            else
            {
                pipe.Hide();
            }
        }   
    }

    void ShowPrevious(int numberInList)
    {
        for (int i = numberInList; i > 0; i--)
        {
            pipes[i].Show();
        }
    }
}
