Shader "Hidden/DebugStencilRead_NotEqual"
{
    SubShader
    {
        Tags{ "Queue"="Geometry" }
        Pass
        {
            ZTest LEqual
            ZWrite On
            Cull Back
            // Only draw where stencil != 1
            Stencil { Ref 1 Comp NotEqual Pass Keep ZFail Keep Fail Keep }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            struct A{ float4 pos:POSITION; };
            struct V{ float4 pos:SV_Position; };
            V vert(A i){ V o; o.pos = TransformObjectToHClip(i.pos.xyz); return o; }
            half4 frag(V i):SV_Target { return half4(0.6,0.6,0.7,1); } // flat color for clarity
            ENDHLSL
        }
    }
}
