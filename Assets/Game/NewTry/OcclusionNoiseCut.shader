Shader "Custom/OcclusionNoiseCut"
{
    Properties
    {
        _MainTex    ("Base Texture", 2D) = "white" {}
        _NoiseScale ("Noise Scale", Float) = 10.0
        _Cutoff     ("Transparent Cutoff", Range(0,1)) = 0.4
        _Darken     ("Darken Factor", Range(0,1)) = 0.6
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
            // Stencil is controlled by the RenderObjects feature, so no Stencil{} here.

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
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;

            float _NoiseScale;
            float _Cutoff;
            float _Darken;

            // Simple hash-based 2D noise in [0,1]
            float hash21(float2 p)
            {
                p = frac(p * float2(123.34, 345.45));
                p += dot(p, p + 34.345);
                return frac(p.x * p.y);
            }

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                return OUT;
            }

            float4 frag (Varyings IN) : SV_Target
            {
                // Base wall color
                float4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);

                // UV-based noise
                float n = hash21(IN.uv * _NoiseScale);

                // Some pixels -> fully transparent (hole)
                if (n < _Cutoff)
                    clip(-1); // discard fragment

                // Others -> show wall but darkened based on noise
                float dark = lerp(1.0, _Darken, n); // 1.._Darken
                col.rgb *= dark;

                // Still opaque where we didn't clip
                return col;
            }

            ENDHLSL
        }
    }
}
