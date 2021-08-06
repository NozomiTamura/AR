using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.XR.ARFoundation;

public class BackgroundShaderChange : MonoBehaviour
{
    //ARCameraBackgroundMy の設定
    [SerializeField] ARCameraBackgroundMy _cameraBackground = null;
    //それぞれ適応するシェーダーの設定
    //UIControllerにこのScriptをつけているのでそこで何が適応されているか見れる
    [SerializeField] Shader ao_shader = null;
    [SerializeField] Shader monokuro_shader = null;
    [SerializeField] Shader Otameshi_shader = null;
    [SerializeField] Shader green_shader = null;
    [SerializeField] Shader Edge_shader = null;

    Material _bgMaterial;   //背景の設定用マテリアル
    Material _muxMaterial;

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {

    }

    //なしにする
    public void Nothing()
    {
        _bgMaterial = null; //設定をnullにする
        _cameraBackground.customMaterial = _bgMaterial;
        _cameraBackground.useCustomMaterial = false;    //無効にする
    }

    //青色にする
    public void Blue()
    {
        StoM(ao_shader);

        Debug.Log("Blue Push");
    }

    //Monokuroを適用する
    public void Monokuro()
    {
        StoM(monokuro_shader);

        Debug.Log("Monokuro Push");
    }

    //Otameshi
    public void Otameshi()
    {
        StoM(Otameshi_shader);

        Debug.Log("Otameshi Push");
    }

    //エッジ検出
    public void Edge()
    {
        StoM(Edge_shader);

        Debug.Log("Otameshi Push");
    }

    //グリーンバック
    public void Green()
    {
        StoM(green_shader);

        Debug.Log("Otameshi Push");
    }

    void StoM(Shader shader)    //シェーダーをマテリアルにする
    {
        // Shader setup
        _bgMaterial = new Material(shader);
        _bgMaterial.EnableKeyword("RCAM_MONITOR");

        _muxMaterial = new Material(shader);
        _muxMaterial.EnableKeyword("RCAM_MULTIPLEXER");

        // Custom background material
        _cameraBackground.customMaterial = _bgMaterial;
        if (_cameraBackground.useCustomMaterial == false)
            _cameraBackground.useCustomMaterial = true;
    }
}
