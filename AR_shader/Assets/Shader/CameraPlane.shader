Shader "Custom/CameraPlane"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
    }

    SubShader
    {
        Cull off    //両面表示

        Pass
        {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata_t
            {
                float4 vertex : POSITION;
                float4 color : COLOR;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : POSITION;
                float4 color : COLOR;
                float2 uv : TEXCOORD0;
                float2 screenpos : TEXCOORD1;
            };

            sampler2D _MainTex;

            v2f vert(appdata_t IN)
            {
                v2f OUT;

                float4 _vertex = IN.vertex;

                //ゆらゆら部分

                float ampX = 0.1f * sin(_Time * 100 + IN.vertex.x);
                float ampZ = 0.1f * sin(_Time * 100 + IN.vertex.z);

                _vertex.xyz = float3(IN.vertex.x + ampX, IN.vertex.y, IN.vertex.z + ampZ);

                OUT.vertex = UnityObjectToClipPos(_vertex);
                OUT.uv = IN.uv;
                OUT.color = IN.color;

                float4 objectToClipPos = UnityObjectToClipPos(IN.vertex);
                float4 spreenPos = ComputeScreenPos(objectToClipPos);
                float2 uv = spreenPos.xy/spreenPos.w;

                OUT.screenpos = uv;
                return OUT;
            }

            fixed4 frag(v2f IN) : COLOR
            {
                float2 xy = IN.screenpos.xy;
                half4 c = tex2D(_MainTex, xy);
                return c;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}