using System.Collections.Generic;
using UnityEngine;
using UnityEngine.XR.ARFoundation;
using UnityEngine.XR.ARSubsystems;
using UnityEngine.EventSystems;

[RequireComponent(typeof(ARRaycastManager))]
public class ARPlaneController : MonoBehaviour
{
    [SerializeField] private GameObject planeObject = null;
    [SerializeField] private ARCameraBackground arCameraBackground = null;
    //[SerializeField] private Material material = null;
    [SerializeField] private RenderTexture renderTexture = null;
    private GameObject generateObject;
    private ARRaycastManager raycastManager;
    private static List<ARRaycastHit> hits = new List<ARRaycastHit>();

    void Awake()
    {
        raycastManager = GetComponent<ARRaycastManager>();
    }

    void Update()
    {
        if (generateObject)
        {
            UpdateObjectTexture();
        }

        //何らかのボタンが押された場合は反応しないようにする
        if (EventSystem.current.currentSelectedGameObject != null)
        {
            return;
        }

        //Planeを生成
        if (Input.touchCount > 0)
        {
            Vector3 touchPosition = Input.GetTouch(0).position;
            if (raycastManager.Raycast(touchPosition, hits, TrackableType.Planes))
            {
                var hitPose = hits[0].pose;

                if (generateObject)
                {
                    generateObject.transform.position = hitPose.position;
                }
                else
                {
                    generateObject = Instantiate(planeObject, hitPose.position, Quaternion.identity);
                    Quaternion q = generateObject.transform.rotation;
                    //縦にするために回転
                    float x = q.eulerAngles.x - 90f;
                    float y = q.eulerAngles.y;
                    float z = q.eulerAngles.z;
                    generateObject.transform.rotation = Quaternion.Euler(x, y, z);
                }
            }
        }
    }

    //テクスチャ 
    private void UpdateObjectTexture()
    {
        Graphics.Blit(null, renderTexture, arCameraBackground.material);
    }
}