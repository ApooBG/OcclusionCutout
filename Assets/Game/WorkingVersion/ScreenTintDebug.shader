Shader "Hidden/DebugStencilRead_NotEqual"
{
    SubShader
    {
        Tags{ "Queue"="Geometry" } //draws with the normal world
        Pass
        {
            ZTest LEqual //ZTest LEqual: the pixel is drawn only if it is in front of or equal to what’s already in the depth buffer. So it respects scene depth (won’t draw through nearer geometry).
            ZWrite On //updates depth as it draws (behaves like a normal opaque).
            Cull Back //standard back-face culling.
            
            //compare against value 1 (the value your sphere wrote).
            // Only draw where stencil != 1
            // never modify the stencil; this pass just reads it.

            Stencil { Ref 1 Comp NotEqual Pass Keep ZFail Keep Fail Keep }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            //Minimal vertex/fragment pair, like before, but here the fragment color does go to the color buffer (no ColorMask 0). We return a flat grey so the “outside” area is obvious.

            struct A{ float4 pos:POSITION; };
            struct V{ float4 pos:SV_Position; };
            V vert(A i){ V o; o.pos = TransformObjectToHClip(i.pos.xyz); return o; }
            half4 frag(V i):SV_Target { return half4(0.6,0.6,0.7,1); } // flat color for clarity
            ENDHLSL
        }
    }
}
