using UnityEngine;

[ExecuteAlways]
public class PlayerPosDepth : MonoBehaviour
{
    [Header("References")]
    [Tooltip("The transform used as the 'player' position for depth comparison.")]
    public Transform player;

    [Header("Shader Property")]
    [Tooltip("Global shader property name for the player world position.")]
    public string playerWorldPosProperty = "_PlayerWorldPos";

    private int _playerWorldPosID;

    private void Awake()
    {
        _playerWorldPosID = Shader.PropertyToID(playerWorldPosProperty);
    }

    private void LateUpdate()
    {
        if (player == null)
            return;

        // Send player world position to all shaders that use _PlayerWorldPos
        Shader.SetGlobalVector(_playerWorldPosID, player.position);
    }
}
