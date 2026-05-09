using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// POST PROCESS CONTROLLER
/// ═══════════════════════
/// TECLAS:
///   1  →  Vignette
///   2  →  Chromatic Aberration
///   0  →  Todos OFF
///  Tab →  Todos ON
///
/// AÑADIR EFECTO: una línea en BuildRegistry()
/// </summary>
public class PostProcessController : MonoBehaviour
{
    [System.Serializable]
    public class EffectEntry
    {
        public string Keyword;   // Nombre exacto del Boolean Keyword en Shader Graph
        public Material Material; // Material que usa ese shader
        public KeyCode Key;
    }

    public List<EffectEntry> Effects = new();

    private readonly Dictionary<EffectEntry, bool> _states = new();

    private void Awake()
    {
        // Estado inicial: todos OFF
        foreach (var e in Effects)
        {
            _states[e] = false;
            SetEffect(e, false);
        }
    }

    private void Update()
    {
        foreach (var e in Effects)
            if (Input.GetKeyDown(e.Key)) Toggle(e);

        if (Input.GetKeyDown(KeyCode.Alpha0)) SetAll(false);
        if (Input.GetKeyDown(KeyCode.Tab)) SetAll(true);
    }

    private void Toggle(EffectEntry e)
    {
        bool next = !_states[e];
        SetEffect(e, next);
        Debug.Log($"[PP] {e.Keyword} → {(next ? "ON" : "OFF")}");
    }

    private void SetEffect(EffectEntry e, bool active)
    {
        if (e.Material == null) return;
        _states[e] = active;

        if (active) e.Material.EnableKeyword(e.Keyword);
        else e.Material.DisableKeyword(e.Keyword);
    }

    private void SetAll(bool active)
    {
        foreach (var e in Effects) SetEffect(e, active);
    }
}