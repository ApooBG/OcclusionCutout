using UnityEngine;
using UnityEditor;

public class MissingRefCleaner
{
    [MenuItem("Tools/Cleanup Missing Scripts In Scene")]
    static void CleanupScene()
    {
        GameObject[] go = GameObject.FindObjectsOfType<GameObject>();
        int count = 0;

        foreach (GameObject g in go)
        {
            SerializedObject so = new SerializedObject(g);
            SerializedProperty prop = so.FindProperty("m_Component");

            int removed = GameObjectUtility.RemoveMonoBehavioursWithMissingScript(g);
            if (removed > 0) count += removed;
        }

        Debug.Log($"Removed {count} missing script references.");
    }
}
