using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.XR.ARFoundation;

public class PlaneShaderChange : MonoBehaviour
{
    //ARCameraBackground の設定
    [SerializeField] ARCameraBackground _cameraBackground = null;
    //それぞれ適応するシェーダーの設定
    //UIControllerにこのScriptをつけているのでそこで何が適応されているか見れる
    [SerializeField] Shader ao_shader = null;
    [SerializeField] Shader monokuro_shader = null;
    [SerializeField] Shader Otameshi_shader = null;
    [SerializeField] Shader Edge_shader = null;

    Material _bgMaterial;
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
        _bgMaterial = null;
        _cameraBackground.customMaterial = _bgMaterial;
        _cameraBackground.useCustomMaterial = false;
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

    //シェーダーをマテリアルにする
    void StoM(Shader shader)
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

    //削除する
    public void Delete()
    {
        GameObject plane = GameObject.FindGameObjectWithTag("Player");  //消すものを選択
        Destroy(plane); //削除
    }
}
