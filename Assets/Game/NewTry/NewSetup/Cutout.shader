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

        // Pass 0: Back faces
        Pass
        {
            Cull Front
            ZWrite Off
            ColorMask 0
            Stencil
            {
                Ref 2
                Comp Always
                Pass Replace
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes { float4 positionOS : POSITION; };
            struct Varyings { float4 positionHCS : SV_POSITION; float3 worldPos : TEXCOORD0; };

            float3 _SpherePosition;
            float _SphereRadius;
            float _NoiseScale;
            float _NoiseThreshold;
            float3 _CameraWorldPos;
float3 _PlayerWorldPos;


            float hash(float2 p) {
                p = frac(p * 0.3183099 + float2(0.1, 0.7));
                p *= 17.0;
                return frac(p.x * p.y * (p.x + p.y));
            }

            float noise(float2 p) {
                float2 i = floor(p);
                float2 f = frac(p);
                float2 u = f * f * (3.0 - 2.0 * f);

                float n00 = hash(i + float2(0, 0));
                float n10 = hash(i + float2(1, 0));
                float n01 = hash(i + float2(0, 1));
                float n11 = hash(i + float2(1, 1));

                return lerp(lerp(n00, n10, u.x), lerp(n01, n11, u.x), u.y);
            }

            Varyings vert(Attributes IN) {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS);
                OUT.worldPos = TransformObjectToWorld(IN.positionOS.xyz);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target {
                float dist = distance(IN.worldPos, _SpherePosition);
                float2 noiseUV = IN.worldPos.xz * _NoiseScale;

                float edgeFade = saturate((_SphereRadius - dist) / _SphereRadius);
                float n = (noise(noiseUV) + noise(noiseUV * 2.3) + noise(noiseUV * 4.1)) * 0.3333;
                float blend = edgeFade + n * 0.5;
                float mask = smoothstep(_NoiseThreshold, _NoiseThreshold + 0.15, blend);

                float outerFade = saturate(((_SphereRadius * 1.4) - dist) / (_SphereRadius * 1.4));
                float noiseOuter = noise(noiseUV * 6.0 + 23.0);
                float islandMask = smoothstep(0.6, 0.95, noiseOuter) * outerFade;

                if (max(mask, islandMask) < 0.5)
                    discard;


                    // Check if current pixel is between camera and player (projected check)
// Check if the pixel is between the camera and the player
float3 viewDir = _PlayerWorldPos - _CameraWorldPos;
float3 toPixel = IN.worldPos - _CameraWorldPos;

float viewLength = length(viewDir);
float proj = dot(toPixel, normalize(viewDir));

// Only allow stencil write if pixel is between camera and player (along view direction)
if (proj < 0 || proj > viewLength)
    discard;
                return 0;
            }
            ENDHLSL
        }

        // Pass 1: Front faces
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

            // Same code as above
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes { float4 positionOS : POSITION; };
            struct Varyings { float4 positionHCS : SV_POSITION; float3 worldPos : TEXCOORD0; };

            float3 _SpherePosition;
            float _SphereRadius;
            float _NoiseScale;
            float _NoiseThreshold;
            float3 _CameraWorldPos;
float3 _PlayerWorldPos;

            float hash(float2 p) {
                p = frac(p * 0.3183099 + float2(0.1, 0.7));
                p *= 17.0;
                return frac(p.x * p.y * (p.x + p.y));
            }

            float noise(float2 p) {
                float2 i = floor(p);
                float2 f = frac(p);
                float2 u = f * f * (3.0 - 2.0 * f);

                float n00 = hash(i + float2(0, 0));
                float n10 = hash(i + float2(1, 0));
                float n01 = hash(i + float2(0, 1));
                float n11 = hash(i + float2(1, 1));

                return lerp(lerp(n00, n10, u.x), lerp(n01, n11, u.x), u.y);
            }

            Varyings vert(Attributes IN) {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS);
                OUT.worldPos = TransformObjectToWorld(IN.positionOS.xyz);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target {
            float dist = distance(IN.worldPos, _SpherePosition);
            float2 noiseUV = IN.worldPos.xz * _NoiseScale;

            // Main radial falloff
            float edgeFade = saturate((_SphereRadius - dist) / _SphereRadius);

            // Core cutout noise
            float n = (noise(noiseUV) + noise(noiseUV * 2.3) + noise(noiseUV * 4.1)) * 0.3333;
            float blend = edgeFade + n * 0.5;
            float mask = smoothstep(_NoiseThreshold, _NoiseThreshold + 0.15, blend);

            // Extra edge debris (high-frequency outer islands)
            float outerFade = saturate(((_SphereRadius * 1.5) - dist) / (_SphereRadius * 1.5));
            float highFreqNoise = (noise(noiseUV * 7.0 + 13.0) + noise(noiseUV * 15.0 + 47.0)) * 0.5;
            float islandMask = smoothstep(0.45, 0.9, highFreqNoise) * outerFade;

            // Combine both
            if (max(mask, islandMask) < 0.5)
                discard;

// Check if the pixel is between the camera and the player
float3 viewDir = _PlayerWorldPos - _CameraWorldPos;
float3 toPixel = IN.worldPos - _CameraWorldPos;

float viewLength = length(viewDir);
float proj = dot(toPixel, normalize(viewDir));

// Only allow stencil write if pixel is between camera and player (along view direction)
if (proj < 0 || proj > viewLength)
    discard;


                return 0;
            }
            ENDHLSL
        }

        // Pass 2: Edge stencil writer
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
    struct Varyings { float4 positionHCS : SV_POSITION; float3 worldPos : TEXCOORD0; };

    float3 _SpherePosition;
    float _SphereRadius;
    float _NoiseScale;
    float _NoiseThreshold;
    float3 _CameraWorldPos;
    float3 _PlayerWorldPos;

    float hash(float2 p) {
        p = frac(p * 0.3183099 + float2(0.1, 0.7));
        p *= 17.0;
        return frac(p.x * p.y * (p.x + p.y));
    }

    float noise(float2 p) {
        float2 i = floor(p);
        float2 f = frac(p);
        float2 u = f * f * (3.0 - 2.0 * f);

        float n00 = hash(i + float2(0, 0));
        float n10 = hash(i + float2(1, 0));
        float n01 = hash(i + float2(0, 1));
        float n11 = hash(i + float2(1, 1));

        return lerp(lerp(n00, n10, u.x), lerp(n01, n11, u.x), u.y);
    }

    Varyings vert(Attributes IN) {
        Varyings OUT;
        OUT.positionHCS = TransformObjectToHClip(IN.positionOS);
        OUT.worldPos = TransformObjectToWorld(IN.positionOS.xyz);
        return OUT;
    }

    half4 frag(Varyings IN) : SV_Target {
        float dist = distance(IN.worldPos, _SpherePosition);
        float2 noiseUV = IN.worldPos.xz * _NoiseScale;

        float edgeFade = saturate((_SphereRadius - dist) / _SphereRadius);
        float n = (noise(noiseUV) + noise(noiseUV * 2.3) + noise(noiseUV * 4.1)) * 0.3333;
        float blend = edgeFade + n * 0.5;
        float mask = smoothstep(_NoiseThreshold, _NoiseThreshold + 0.15, blend);

        float outerFade = saturate(((_SphereRadius * 1.4) - dist) / (_SphereRadius * 1.4));
        float noiseOuter = noise(noiseUV * 6.0 + 23.0);
        float islandMask = smoothstep(0.6, 0.95, noiseOuter) * outerFade;

        float combined = max(mask, islandMask);

        // Detect edge
        float edge = smoothstep(0.45, 0.55, combined) * (1 - smoothstep(0.55, 0.65, combined));
        if (edge < 0.01)
            discard;

        float3 viewDir = _PlayerWorldPos - _CameraWorldPos;
        float3 toPixel = IN.worldPos - _CameraWorldPos;
        float viewLength = length(viewDir);
        float proj = dot(toPixel, normalize(viewDir));
        if (proj < 0 || proj > viewLength)
            discard;

        return 0;
    }
    ENDHLSL
}
    }
}
