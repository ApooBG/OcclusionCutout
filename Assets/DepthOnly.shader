Shader "Hidden/DepthOnly"
{
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        Pass
        {
            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Back

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct A { float4 posOS : POSITION; };
            struct V { float4 posCS : SV_Position; };

            V vert(A v)
            {
                V o;
                o.posCS = TransformObjectToHClip(v.posOS.xyz);
                return o;
            }
            float4 frag(V i) : SV_Target { return 0; } // ColorMask 0, never written.
            ENDHLSL
        }
    }
}
