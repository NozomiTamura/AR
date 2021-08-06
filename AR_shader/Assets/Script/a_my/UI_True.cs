using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class UI_True : MonoBehaviour
{
    //表示するUI
    [SerializeField] private GameObject UI_all = null;
    [SerializeField] private GameObject button = null;

    [SerializeField] private GameObject rawImage = null;    //画面タッチしたかを、これで試す

    public void onClickAct()
    {
        //表示
        UI_all.SetActive(true);
        button.SetActive(true);

        //非表示
        rawImage.SetActive(false);
    }
}
