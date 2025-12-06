Shader "Hidden/Cutout_Front"
{
    Properties
    {
        _NoiseScale ("Noise Scale", Float) = 1.0
        _NoiseThreshold ("Noise Threshold", Float) = 0.5
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            Cull Back
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

            // -------- Shared Structs --------
            struct Attributes { float4 positionOS : POSITION; };
            struct Varyings   { float4 positionHCS : SV_POSITION; float3 worldPos : TEXCOORD0; };

            // -------- Shared Uniforms --------
            float3 _SpherePosition;
            float  _SphereRadius;
            float  _NoiseScale;
            float  _NoiseThreshold;
            float3 _CameraWorldPos;
            float3 _PlayerWorldPos;

            // -------- Noise Helpers --------
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
                float n00 = hash(i + float2(0,0));
                float n10 = hash(i + float2(1,0));
                float n01 = hash(i + float2(0,1));
                float n11 = hash(i + float2(1,1));
                return lerp(lerp(n00,n10,u.x), lerp(n01,n11,u.x), u.y);
            }

            // -------- Vertex --------
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS);
                OUT.worldPos = TransformObjectToWorld(IN.positionOS.xyz);
                return OUT;
            }

            // -------- Fragment --------
            half4 frag(Varyings IN) : SV_Target
            {
                float dist = distance(IN.worldPos, _SpherePosition);

                float2 uv = IN.worldPos.xz * _NoiseScale;
                float n = (noise(uv) + noise(uv*2.3) + noise(uv*4.1)) / 3.0;

                float falloff = saturate((_SphereRadius - dist) / _SphereRadius);
                float blend = falloff + n * 0.5;
                float mask = smoothstep(_NoiseThreshold, _NoiseThreshold + 0.15, blend);

                if (mask < 0.5)
                    discard;

                return 0;
            }
            ENDHLSL
        }
    }
}
