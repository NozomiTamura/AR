#include "UnityCG.cginc"

// Uniforms from AR Foundation　　　
sampler2D _textureY;
sampler2D _textureCbCr;
sampler2D _HumanStencil;
sampler2D _EnvironmentDepth;
float4x4 _UnityDisplayTransform;

// Rcam parameters
float2 _DepthRange;
float _AspectFix;

// Hue encoding
float3 Hue2RGB(float hue)
{
    float h = hue * 6 - 2;
    float r = abs(h - 1) - 1;
    float g = 2 - abs(h);
    float b = 2 - abs(h - 2);
    return saturate(float3(r, g, b));
}

// yCbCr decoding
float3 YCbCrToSRGB(float y, float2 cbcr)
{
    float b = y + cbcr.x * 1.772 - 0.886;
    float r = y + cbcr.y * 1.402 - 0.701;
    float g = y + dot(cbcr, float2(-0.3441, -0.7141)) + 0.5291;
    return float3(r, g, b);
}

// Common vertex shader

void Vertex(float4 vertex : POSITION,
            float2 texCoord : TEXCOORD,
            out float4 outVertex : SV_Position,
            out float2 outTexCoord : TEXCOORD)
{
    outVertex = UnityObjectToClipPos(vertex);
    outTexCoord = texCoord;
}

//RGBA値からグレースケール値を求める関数
float gray (float3 c)
{
    return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b;
}

// YCbCr テクスチャの uv 座標から RGBA を求める関数

float4 rgba (float2 uv)
{
    float y = tex2D(_textureY, uv).x;
    float4 ycbcr = float4(y, tex2D(_textureCbCr, uv).xy, 1.0);
    const float4x4 ycbcrToRGBTransform = float4x4(
        float4(1.0, +0.0000, +1.4020, -0.7010),
        float4(1.0, -0.3441, -0.7141, +0.5291),
        float4(1.0, +1.7720, +0.0000, -0.8860),
        float4(0.0, +0.0000, +0.0000, +1.0000)
        );

    float4 result = mul(ycbcrToRGBTransform, ycbcr);
#if !UNITY_COLORSPACE_GAMMA
    result = float4(GammaToLinearSpace(result.xyz), result.w);
#endif // !UNITY_COLORSPACE_GAMMA
    return result;
}

// Fragment shader
float4 Fragment(float4 vertex : SV_Position,
                float2 texCoord : TEXCOORD) : SV_Target
{
#ifdef RCAM_MULTIPLEXER

    float4 tc = frac(texCoord.xyxy * float4(1, 1, 2, 2));

    // Aspect ration compensation & vertical flip

    tc.yw = (0.5 - tc.yw) * _AspectFix + 0.5;

    // Texture samples　　　
    float y = tex2D(_textureY, tc.zy).x;
    float2 cbcr = tex2D(_textureCbCr, tc.zy).xy;
    float mask = tex2D(_HumanStencil, tc.zw).x;
    float depth = tex2D(_EnvironmentDepth, tc.zw).x;

    // Color plane

    float3 c1 = YCbCrToSRGB(y, cbcr);

    // Depth plane

    depth = (depth - _DepthRange.x) / (_DepthRange.y - _DepthRange.x);
    float3 c2 = Hue2RGB(clamp(depth, 0, 0.8));

    // Mask plane

    float3 c3 = mask;

    // Output
    float3 srgb = tc.x < 0.5 ? c1 : (tc.y < 0.5 ? c2 : c3);
    return float4(GammaToLinearSpace(srgb), 1);

#endif

#ifdef RCAM_MONITOR

    // Texture transform

    float2 uv = mul(float3(texCoord, 1), _UnityDisplayTransform).xy;

    //エッジ検出

    int _ImageWidth = 1125;
    int _ImageHeight = 2436;

    float2 texcoord = uv;

    //ピクセル幅の算出

    float dx = 1.0 / _ImageWidth;
    float dy = 1.0 / _ImageHeight;

    //対象ピクセルの周囲の画素値を取得
    float4 c00 = rgba(texcoord.xy + float2(-dx, -dy));
    float4 c01 = rgba(texcoord.xy + float2(-dx, 0.0));
    float4 c02 = rgba(texcoord.xy + float2(-dx, +dy));
    float4 c10 = rgba(texcoord.xy + float2(0.0, +dy));
    float4 c11 = rgba(texcoord.xy);
    float4 c12 = rgba(texcoord.xy + float2(0.0, +dy));
    float4 c20 = rgba(texcoord.xy + float2(+dx, -dy));
    float4 c21 = rgba(texcoord.xy + float2(+dx, 0.0));
    float4 c22 = rgba(texcoord.xy + float2(+dx, +dy));

    //Sobel フィルタの係数を基に横方向と縦方向の値を求める

    float4 sx = 1.0 * c00 + 2.0 * c10 + 1.0 * c20
                + -1.0 * c02 + -2.0 * c12 + -1.0 * c22;
    float4 sy = 1.0 * c00 + 2.0 * c01 + 1.0 * c02
                + -1.0 * c20 + -2.0 * c21 + -1.0 * c22;

    //横方向と縦方向の値の二乗和と平方根を求め、グレースケール化でfloatにする

    float g = gray(sqrt(sx*sx + sy*sy));

    // Output
    // 閾値を複数設定して色を変える   赤青黒

    if (g > 0.4) {
        return fixed4(0.25, 0.25, 0.25, 1);
    } else if (g > 0.3) {
        return fixed4(0.3, 0.5, 1, 1);
    } else if (g > 0.2) {
        return fixed4(1, 0.25, 0.25, 1);
    } else {
        return fixed4(1, 1, 1, 1);
    }

#endif
}
