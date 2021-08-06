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
    return saturate(float3(r, g, b));   //saturate(x) xを0-1にクランプ
}

// yCbCr decoding
float3 YCbCrToSRGB(float y, float2 cbcr)
{
    float b = y + cbcr.x * 1.772 - 0.886;
    float r = y + cbcr.y * 1.402 - 0.701;
    float g = y + dot(cbcr, float2(-0.3441, -0.7141)) + 0.5291; //dot(x,y) ２ベクトルの内積を求める//
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
    float3 c2 = Hue2RGB(clamp(depth, 0, 0.8));  //clamp(x,a,b) xをa-bにクランプ

    // Mask plane    
    float3 c3 = mask;

    // Output
    float3 srgb = tc.x < 0.5 ? c1 : (tc.y < 0.5 ? c2 : c3);
    return float4(GammaToLinearSpace(srgb), 1);

#endif

#ifdef RCAM_MONITOR

    // Texture transform

    float2 uv = mul(float3(texCoord, 1), _UnityDisplayTransform).xy;    //mul(x,y) 行列乗算

    // Texture samples

    float y = tex2D(_textureY, uv);
    float2 cbcr = tex2D(_textureCbCr, uv).xy;
    float mask = tex2D(_HumanStencil, uv).x;
    float depth = tex2D(_EnvironmentDepth, uv).x;

    // Color
    float3 srgb = YCbCrToSRGB(y, cbcr);

    // Composite stencil/depth
    srgb = lerp(srgb, float3(y, 0, 0), saturate(depth / 2));
    //srgb = lerp(float3(0.2, 0.2, 0.0) * y, srgb, mask);    
    srgb = lerp(y, srgb, mask);

    // Letterboxing with 16:9

    srgb *= abs(uv.y - 0.5) * 2 < _AspectFix ? 1 : 0.5; //abs(x) 絶対値を返す

    float3 c11 = YCbCrToSRGB(y, cbcr);   //そのままの色

    //グレースケール化

    float g = gray(c11);

    // Output
    //return float4(GammaToLinearSpace(srgb), 1);

    // 閾値を複数設定して色を変える (0,51,102,153,204,255)
    if (g < 0.2) {
        return fixed4(1, 0.5, 0.5, 1);
    } else if (g < 0.4) {
        return fixed4( 0.75,  0.5,  1, 1);
    } else if (g < 0.6) {
        return fixed4(0.5, 1, 1, 1);
    } else if (g < 0.8) {
        return fixed4(0.5, 1, 0.5, 1);
    } else {
        return fixed4(1, 1, 0.5, 1);
    }

#endif
}
