Shader "Custom/OcclusionNoiseCut"
{
    Properties
    {
        _MainTex        ("Base Texture", 2D) = "white" {}
        _NoiseTex       ("Noise Texture", 2D) = "gray" {}
        _WorldScale     ("World Noise Scale", Float) = 0.2
        _Cutoff         ("Transparent Cutoff", Range(0,1)) = 0.5
        _Feather        ("Edge Feather", Range(0.1,10)) = 4.0
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalRenderPipeline"
            "RenderType"     = "Opaque"
            "Queue"          = "Geometry"
        }

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
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv         : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;

            TEXTURE2D(_NoiseTex);
            SAMPLER(sampler_NoiseTex);

            float _WorldScale;
            float _Cutoff;
            float _Feather;

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv         = TRANSFORM_TEX(IN.uv, _MainTex);
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                return OUT;
            }

            float4 frag (Varyings IN) : SV_Target
            {
                // sample wall texture
                float4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);

                // multi-scale noise in world space for nice varied chunks
                float2 baseUV = IN.positionWS.xz * _WorldScale;

                float n0 = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, baseUV).r;
                float n1 = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, baseUV * 2.7).r;
                float n2 = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, baseUV * 5.3).r;

                float noise = (n0 + 0.6 * n1 + 0.3 * n2) / (1.0 + 0.6 + 0.3);

                // sharpen noise around cutoff so shapes are crisp
                float mask = saturate((noise - _Cutoff) * _Feather + 0.5);

                // transparent vs wall: ONLY alpha, no black
                if (mask <= 0.001)
                    clip(-1);   // fully transparent, see through

                // just return the wall color (maybe tiny variation if you want)
                // col.rgb *= lerp(0.95, 1.05, noise); // optional subtle variation
                return col;
            }

            ENDHLSL
        }
    }
}
