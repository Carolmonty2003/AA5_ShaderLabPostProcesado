using UnityEngine;
using UnityEngine.InputSystem;

public class PostProcessingController : MonoBehaviour
{
    [Header("Pixelated Effect")]
    [SerializeField] private Material pixelatedMaterial;
    [SerializeField] private Key pixelatedKey = Key.Digit6;

    [Header("CRT Lines Effect")]
    [SerializeField] private Material crtLinesMaterial;
    [SerializeField] private Key crtLinesKey = Key.Digit5;

    private bool pixelatedEnabled = false;
    private bool crtLinesEnabled = false;

    private const string PixelatedKeyword = "_PIXELATED_ON";
    private const string CRTLinesKeyword = "_CRT_LINES_ON";

    private void Start()
    {
        SetKeyword(pixelatedMaterial, PixelatedKeyword, pixelatedEnabled);
        SetKeyword(crtLinesMaterial, CRTLinesKeyword, crtLinesEnabled);
    }

    private void Update()
    {
        if (Keyboard.current == null)
            return;

        if (Keyboard.current[pixelatedKey].wasPressedThisFrame)
        {
            pixelatedEnabled = !pixelatedEnabled;
            SetKeyword(pixelatedMaterial, PixelatedKeyword, pixelatedEnabled);
        }

        if (Keyboard.current[crtLinesKey].wasPressedThisFrame)
        {
            crtLinesEnabled = !crtLinesEnabled;
            SetKeyword(crtLinesMaterial, CRTLinesKeyword, crtLinesEnabled);
        }
    }

    private void SetKeyword(Material material, string keyword, bool enabled)
    {
        if (material == null)
            return;

        if (enabled)
            material.EnableKeyword(keyword);
        else
            material.DisableKeyword(keyword);
    }
}