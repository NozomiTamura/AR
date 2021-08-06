Shader "Hidden/Rcam2/Monokuro"
{
    Properties
    {
        _MainTex("", 2D) = "black" {}
        _textureY("", 2D) = "black" {}
        _textureCbCr("", 2D) = "black" {}
        _HumanStencil("", 2D) = "black" {}
        _EnvironmentDepth("", 2D) = "black" {}
    }

    SubShader
    {
        Cull off    //両面表示

        Pass
        {
            Cull Off ZTest Always ZWrite Off
            CGPROGRAM
            #pragma multi_compile RCAM_MULTIPLEXER RCAM_MONITOR
            #pragma vertex Vertex
            #pragma fragment Fragment
            #include "Monokuro.cginc"   //中身はMonokuro.cginc 
            ENDCG
        }
    }
}