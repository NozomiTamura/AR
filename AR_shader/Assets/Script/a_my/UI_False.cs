using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class UI_False : MonoBehaviour
{
    //消すUI
    [SerializeField] private GameObject UI_all = null;
    [SerializeField] private GameObject button = null;

    [SerializeField] private GameObject rawImage = null;    //画面タッチしたかを、これで試す

    //UIを消す
    public void UI_F()
    {
        //非表示
        UI_all.SetActive(false);
        button.SetActive(false);

        //表示
        rawImage.SetActive(true);
    }
}
