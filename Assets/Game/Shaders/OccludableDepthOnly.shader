Shader "Hidden/OccludableDepthOnly"
{
    SubShader
    {
        Tags{
            "RenderPipeline"="UniversalRenderPipeline"
            "RenderType"="Opaque"
            "Queue"="Geometry"
        }

        Pass
        {
            Name "DepthOnly"
            ZWrite On
            ColorMask R   // store depth in R channel

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.positionCS = TransformWorldToHClip(OUT.positionWS);
                return OUT;
            }

            float4 frag(Varyings IN) : SV_Target
            {
                // View-space position
                float3 posVS = TransformWorldToView(IN.positionWS);
                // Unity looks down -Z, so make distance positive
                float depth = -posVS.z;
                return float4(depth, 0, 0, 0);
            }

            ENDHLSL
        }
    }
}
