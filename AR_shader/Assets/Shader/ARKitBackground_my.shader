Shader "Unlit/ARKitBackground_my"
{
    Properties
    {
        _textureY ("TextureY", 2D) = "white" {}
        _textureCbCr ("TextureCbCr", 2D) = "black" {}
        _HumanStencil ("HumanStencil", 2D) = "black" {}
        _HumanDepth ("HumanDepth", 2D) = "black" {}
        _EnvironmentDepth ("EnvironmentDepth", 2D) = "black" {}
        _ImageWidth ("ImageWidth", Int) = 0
        _ImageHeight ("ImageWidth", Int) = 0
    }
    SubShader
    {
        Tags
        {
            "Queue" = "Background"
            "RenderType" = "Background"
            "ForceNoShadowCasting" = "True"
        }

        Pass
        {
            Cull Off
            ZTest Always
            ZWrite On
            Lighting Off
            LOD 100
            Tags
            {
                //"LightMode" = "Always"

                "RenderType"="Opaque"
            }


            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_local __ ARKIT_BACKGROUND_URP ARKIT_BACKGROUND_LWRP
            #pragma multi_compile_local __ ARKIT_HUMAN_SEGMENTATION_ENABLED ARKIT_ENVIRONMENT_DEPTH_ENABLED


#if ARKIT_BACKGROUND_URP

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            //#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

            #define ARKIT_TEXTURE2D_HALF(texture) TEXTURE2D(texture)
            #define ARKIT_SAMPLER_HALF(sampler) SAMPLER(sampler)
            #define ARKIT_TEXTURE2D_FLOAT(texture) TEXTURE2D(texture)
            #define ARKIT_SAMPLER_FLOAT(sampler) SAMPLER(sampler)
            #define ARKIT_SAMPLE_TEXTURE2D(texture,sampler,texcoord) SAMPLE_TEXTURE2D(texture,sampler,texcoord)

#elif ARKIT_BACKGROUND_LWRP

            #include "Packages/com.unity.render-pipelines.lightweight/ShaderLibrary/Core.hlsl"
            //#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

            #define ARKIT_TEXTURE2D_HALF(texture) TEXTURE2D(texture)
            #define ARKIT_SAMPLER_HALF(sampler) SAMPLER(sampler)
            #define ARKIT_TEXTURE2D_FLOAT(texture) TEXTURE2D(texture)
            #define ARKIT_SAMPLER_FLOAT(sampler) SAMPLER(sampler)
            #define ARKIT_SAMPLE_TEXTURE2D(texture,sampler,texcoord) SAMPLE_TEXTURE2D(texture,sampler,texcoord)

#else // Legacy RP

            #include "UnityCG.cginc"

            #define real4 half4
            #define real4x4 half4x4
            #define TransformObjectToHClip UnityObjectToClipPos
            #define FastSRGBToLinear GammaToLinearSpace

            #define ARKIT_TEXTURE2D_HALF(texture) UNITY_DECLARE_TEX2D_HALF(texture)
            #define ARKIT_SAMPLER_HALF(sampler)
            #define ARKIT_TEXTURE2D_FLOAT(texture) UNITY_DECLARE_TEX2D_FLOAT(texture)
            #define ARKIT_SAMPLER_FLOAT(sampler)
            #define ARKIT_SAMPLE_TEXTURE2D(texture,sampler,texcoord) UNITY_SAMPLE_TEX2D(texture,texcoord)

#endif


            struct appdata  //vertex
            {
                float3 position : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f  //texcoordInOut
            {
                float4 position : SV_POSITION;
                float2 texcoord : TEXCOORD0;
            };

            CBUFFER_START(UnityARFoundationPerFrame)
            // Device display transform is provided by the AR Foundation camera background renderer.

            float4x4 _UnityDisplayTransform;
            CBUFFER_END


            v2f vert (appdata v)    //TexCoordInOut vert (Vertex vertex)
            {
                // Transform the position from object space to clip space. 
                float4 position = TransformObjectToHClip(v.position);

                // Remap the texture coordinates based on the device rotation.
                float2 texcoord = mul(float3(v.texcoord, 1.0f), _UnityDisplayTransform).xy;

                v2f o;
                o.position = position;
                o.texcoord = texcoord;
                return o;
            }

            ARKIT_TEXTURE2D_HALF(_textureY);
            ARKIT_SAMPLER_HALF(sampler_textureY);
            ARKIT_TEXTURE2D_HALF(_textureCbCr);
            ARKIT_SAMPLER_HALF(sampler_textureCbCr);

            int _ImageWidth;
            int _ImageHeight;

            CBUFFER_START(ARKitColorTransformations)
            static const real4x4 s_YCbCrToSRGB = real4x4(
                real4(1.0h,  0.0000h,  1.4020h, -0.7010h),
                real4(1.0h, -0.3441h, -0.7141h,  0.5291h),
                real4(1.0h,  1.7720h,  0.0000h, -0.8860h),
                real4(0.0h,  0.0000h,  0.0000h,  1.0000h)
            );
            CBUFFER_END

            //RGBA値からグレースケール値を求める関数
            float gray (float4 c)
            {
                return 0.2126*c.r + 0.7152*c.g + 0.0722*c.b;
            }

            inline float ConvertDistanceToDepth(float d)
            {
                // Clip any distances smaller than the near clip plane, and compute the depth value from the distance.
                return (d < _ProjectionParams.y) ? 0.0f : ((0.5f / _ZBufferParams.z) * ((1.0f / d) - _ZBufferParams.w));
            }

            //ARKIT_TEXTURE2D_HALF(_textureY);
            //ARKIT_SAMPLER_HALF(sampler_textureY);
            //ARKIT_TEXTURE2D_HALF(_textureCbCr);
            //ARKIT_SAMPLER_HALF(sampler_textureCbCr);
            
#if ARKIT_ENVIRONMENT_DEPTH_ENABLED
            ARKIT_TEXTURE2D_FLOAT(_EnvironmentDepth);
            ARKIT_SAMPLER_FLOAT(sampler_EnvironmentDepth);
#elif ARKIT_HUMAN_SEGMENTATION_ENABLED
            ARKIT_TEXTURE2D_HALF(_HumanStencil);
            ARKIT_SAMPLER_HALF(sampler_HumanStencil);
            ARKIT_TEXTURE2D_FLOAT(_HumanDepth);
            ARKIT_SAMPLER_FLOAT(sampler_HumanDepth);
#endif // ARKIT_HUMAN_SEGMENTATION_ENABLED

            //YCbCrテクスチャのuv座標からRGBAを求める関数

            float4 rgba (float2 texcoord)
            {
                float y = ARKIT_SAMPLE_TEXTURE2D(_textureY, sampler_textureY, texcoord).r;
                float4 ycbcr_a = float4(y, ARKIT_SAMPLE_TEXTURE2D(_textureCbCr, sampler_textureCbCr, texcoord).rg, 1.0);

                float4 result = mul(s_YCbCrToSRGB, ycbcr_a);
#if !UNITY_COLORSPACE_GAMMA
                result = float4(GammaToLinearSpace(result.xyz), result.w);
#endif //!UNITY_COLORSPACE_GAMMA
                return result;
            }


           fixed frag (v2f i) : SV_Target
           {
                float2 texcoord = i.texcoord;

                //ピクセル幅の算出
                float dx = 1.0 / _ImageWidth;
                float dy = 1.0 / _ImageHeight;

                //対称ピクセルの周囲の画素値を取得

                float4 c00 = rgba(texcoord + float2(-dx, -dy));
                float4 c01 = rgba(texcoord + float2(-dx, 0.0));
                float4 c02 = rgba(texcoord + float2(-dx, +dy));
                float4 c10 = rgba(texcoord + float2(0.0, -dy));
                float4 c11 = rgba(texcoord);
                float4 c12 = rgba(texcoord + float2(0.0, +dy));
                float4 c20 = rgba(texcoord + float2(+dx, -dy));
                float4 c21 = rgba(texcoord + float2(+dx, 0.0));
                float4 c22 = rgba(texcoord + float2(+dx, +dy));

                //Sobelフィルタの係数を基の方向と縦方向の値を求める

                float4 sx = 1.0*c00 + 2.0*c10 + 1.0*c20
                            + (-1.0*c02) + (-2.0*c12) + (-1.0*c22);
                float4 sy = 1.0*c00 + 2.0*c01 + 1.0*c02
                            + (-1.0*c20) + (-2.0*c21) + (-1.0*c22);

                //横方向と縦方向の値の二乗和の平方根を求め、グレースケールでfloatにする

                float g = gray(sqrt(sx*sx + sy*sy));

                //求めた閾値より大きければエッジとして黒、それ以外は白で描画

                return g > 0.3 ? fixed4(0, 0, 0, 1) : fixed4(1, 1, 1, 1);
            }

            ENDHLSL
        }
    }
}
