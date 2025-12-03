Shader "Hidden/Cutout"
{
    Properties
    {
        _NoiseScale("Noise Scale", Float) = 1.0
        _NoiseThreshold("Noise Threshold", Float) = 0.5
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Pass
        {
            Cull Off
            ZWrite Off
            ColorMask 0
            Stencil
            {
                Ref 1
                Comp Always
                Pass Replace
            }

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
                float4 positionHCS : SV_POSITION;
                float3 worldPos : TEXCOORD0;
            };

            float3 _SpherePosition;
            float _SphereRadius;
            float _NoiseScale;
            float _NoiseThreshold;

            // 2D value noise (cheap & smooth)
            float hash(float2 p)
            {
                p = frac(p * 0.3183099 + float2(0.1, 0.7));
                p *= 17.0;
                return frac(p.x * p.y * (p.x + p.y));
            }

            float noise(float2 p)
            {
                float2 i = floor(p);
                float2 f = frac(p);
                float2 u = f * f * (3.0 - 2.0 * f);

                float n00 = hash(i + float2(0, 0));
                float n10 = hash(i + float2(1, 0));
                float n01 = hash(i + float2(0, 1));
                float n11 = hash(i + float2(1, 1));

                return lerp(lerp(n00, n10, u.x), lerp(n01, n11, u.x), u.y);
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS);
                OUT.worldPos = TransformObjectToWorld(IN.positionOS.xyz);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float dist = distance(IN.worldPos, _SpherePosition);
                float2 noiseUV = IN.worldPos.xz * _NoiseScale;

                // Main reveal edge
                float edgeFade = saturate((_SphereRadius - dist) / _SphereRadius);
                float n = (noise(noiseUV * 1.0) + noise(noiseUV * 2.3) + noise(noiseUV * 4.1)) * 0.3333;
                float blend = edgeFade + n * 0.5;
                float mask = smoothstep(_NoiseThreshold, _NoiseThreshold + 0.15, blend);

                // Floating islands
                float outerFade = saturate(((_SphereRadius * 1.4) - dist) / (_SphereRadius * 1.4));
                float noiseOuter = noise(noiseUV * 6.0 + 23.0);
                float islandMask = smoothstep(0.6, 0.95, noiseOuter) * outerFade;

                // Final combined mask
                if (max(mask, islandMask) < 0.5)
                    discard;

                return 0;
            }
            ENDHLSL
        }
    }
}
