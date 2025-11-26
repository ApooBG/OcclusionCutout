Shader "Custom/OcclusionNoiseCut_SceneColor_Fixed"
{
    Properties
    {
        _NoiseTex ("Noise Texture", 2D) = "gray" {}
        _WorldScale ("World Noise Scale", Float) = 0.2
        _Cutoff ("Transparent Cutoff", Range(0,1)) = 0.5
        _Feather ("Edge Feather", Range(0.1,10)) = 4.0
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalRenderPipeline" "RenderType"="Opaque" "Queue"="Geometry" }

        Pass
        {
            Name "OcclusionNoiseCut"
            Cull Back
            ZWrite On
            ZTest LEqual

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float4 screenPos : TEXCOORD1;
            };

            TEXTURE2D(_NoiseTex);
            SAMPLER(sampler_NoiseTex);

            TEXTURE2D(_CameraOpaqueTexture);
            SAMPLER(sampler_CameraOpaqueTexture);

            float _WorldScale;
            float _Cutoff;
            float _Feather;

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.screenPos = ComputeScreenPos(OUT.positionCS);
                return OUT;
            }

            float4 frag (Varyings IN) : SV_Target
            {
                float2 screenUV = saturate(IN.screenPos.xy / IN.screenPos.w);

                float4 col = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, screenUV);

                float2 baseUV = IN.positionWS.xz * _WorldScale;

                float n0 = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, baseUV).r;
                float n1 = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, baseUV * 2.7).r;
                float n2 = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, baseUV * 5.3).r;

                float noise = (n0 + 0.6 * n1 + 0.3 * n2) / (1.0 + 0.6 + 0.3);

                float mask = saturate((noise - _Cutoff) * _Feather + 0.5);

                if (mask <= 0.001)
                    clip(-1);

                return col;
            }

            ENDHLSL
        }
    }
}
