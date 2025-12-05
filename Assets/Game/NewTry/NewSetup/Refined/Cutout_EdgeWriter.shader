Shader "Hidden/Cutout_EdgeWriter"
{
    Properties
    {
        _NoiseScale ("Noise Scale", Float) = 1.0
        _NoiseThreshold ("Noise Threshold", Float) = 0.5
        _ViewConeCos("View Cone Cosine", Range(0,1)) = 0.8
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
                Ref 3
                Comp Always
                Pass Replace
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes { float4 positionOS : POSITION; };
            struct Varyings   { float4 positionHCS : SV_POSITION; float3 worldPos : TEXCOORD0; };

            float3 _SpherePosition;
            float  _SphereRadius;
            float  _NoiseScale;
            float  _NoiseThreshold;
            float3 _CameraWorldPos;
            float3 _PlayerWorldPos;
            float  _ViewConeCos;

            float hash(float2 p)
            {
                p = frac(p * 0.3183099 + float2(0.1,0.7));
                p *= 17.0;
                return frac(p.x*p.y*(p.x+p.y));
            }

            float noise(float2 p)
            {
                float2 i = floor(p);
                float2 f = frac(p);
                float2 u = f*f*(3.0 - 2.0*f);
                float n00 = hash(i);
                float n10 = hash(i + float2(1,0));
                float n01 = hash(i + float2(0,1));
                float n11 = hash(i + float2(1,1));
                return lerp(lerp(n00,n10,u.x), lerp(n01,n11,u.x), u.y);
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
                float2 uv = IN.worldPos.xz * _NoiseScale;

                float edgeFade = saturate((_SphereRadius - dist) / _SphereRadius);
                float n = (noise(uv) + noise(uv*2.3) + noise(uv*4.1)) / 3.0;
                float blend = edgeFade + n * 0.5;
                float mask = smoothstep(_NoiseThreshold, _NoiseThreshold + 0.15, blend);

                float outerFade = saturate(((_SphereRadius * 1.4) - dist) / (_SphereRadius * 1.4));
                float islands = smoothstep(0.6, 0.95, noise(uv*6.0 + 23.0)) * outerFade;

                float combined = max(mask, islands);

                float edge =
                    smoothstep(0.45, 0.55, combined) *
                    (1.0 - smoothstep(0.55, 0.65, combined));

                if (edge < 0.01)
                    discard;

                float3 viewDir = _PlayerWorldPos - _CameraWorldPos;
                float3 toPixel = IN.worldPos - _CameraWorldPos;

                float proj = dot(toPixel, normalize(viewDir));
                float viewLength = length(viewDir);
                if (proj < 0 || proj > viewLength)
                    discard;

                float cosAngle = dot(normalize(toPixel), normalize(viewDir));
                if (cosAngle < _ViewConeCos)
                    discard;

                return 0;
            }
            ENDHLSL
        }
    }
}
