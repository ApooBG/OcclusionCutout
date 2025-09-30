Shader "Hidden/OcclusionVolumeDepth"
{
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry-10" }
        Pass
        {
            ZTest Always
            ZWrite Off
            Cull Back
            ColorMask RGBA

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes { float4 positionOS : POSITION; };
            struct Varyings  { float4 positionCS : SV_Position; float3 posVS : TEXCOORD0; };

            Varyings vert (Attributes v)
            {
                Varyings o;
                float4 posWS = mul(GetObjectToWorldMatrix(), v.positionOS);
                o.positionCS = TransformWorldToHClip(posWS.xyz);
                o.posVS = mul(UNITY_MATRIX_V, posWS).xyz;  // view-space
                return o;
            }

            float4 frag (Varyings i) : SV_Target
            {
                // positive eye-depth
                float eye = -i.posVS.z;
                float farPlane = _ProjectionParams.z;
                float depth01 = saturate(eye / farPlane);
                // R = depth01, A = mask (1 = inside)
                return float4(depth01, 0, 0, 1);
            }
            ENDHLSL
        }
    }
    FallBack Off
}
