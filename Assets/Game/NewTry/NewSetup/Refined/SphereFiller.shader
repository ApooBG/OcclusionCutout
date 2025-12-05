Shader "Hidden/SphereFiller"
{
    SubShader
    {
        Tags { "Queue"="Geometry" }

        Pass
        {
            Cull Off
            ZWrite Off
            ZTest LEqual
            ColorMask RGB

            Stencil
            {
                Ref 1
                Comp Equal
                Pass Keep
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes { float4 positionOS : POSITION; };
            struct Varyings { float4 posHCS : SV_POSITION; };

            float3 _SpherePosition;
            float _SphereRadius;

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.posHCS = TransformObjectToHClip(IN.positionOS);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                // You can color this however you want.
                // A darkened version of the wall color works best.
                return half4(0.1, 0.1, 0.1, 1.0);
            }
            ENDHLSL
        }
    }
}
