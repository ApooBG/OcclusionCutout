Shader "Hidden/Cutout"
{
    // Values you can tweak from the material inspector or via C#
    Properties
    {
        _NoiseScale     ("Noise Scale", Float)          = 1.0   // How zoomed in / out the noise is
        _NoiseThreshold ("Noise Threshold", Float)      = 0.5   // How strong the noise+falloff must be to keep a pixel
        _ViewConeCos("View Cone Cosine", Range(0,1)) = 0.8
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }

        // =====================================================================
        // PASS 1: FRONT FACES OF THE SPHERE (writes stencil = 1)
        // Same idea as pass 0, but now for the front side.
        // =====================================================================
        Pass
        {
            Cull Back       // draw front faces
            ZWrite Off
            ColorMask 0

            Stencil
            {
                Ref 1
                Comp Always
                Pass Replace
            }

            HLSLPROGRAM
            #pragma vertex   vert
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
            float _ViewConeCos;   // cosine of max angle between camera->player and camera->pixel

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

                return lerp( lerp(n00, n10, u.x),
                             lerp(n01, n11, u.x),
                             u.y );
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS);
                OUT.worldPos    = TransformObjectToWorld(IN.positionOS.xyz);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float dist    = distance(IN.worldPos, _SpherePosition);
                float2 noiseUV = IN.worldPos.xz * _NoiseScale;

                // Main radial falloff (center → radius)
                float edgeFade = saturate((_SphereRadius - dist) / _SphereRadius);

                // Core cutout noise (same idea as pass 0)
                float n = ( noise(noiseUV) +
                            noise(noiseUV * 2.3) +
                            noise(noiseUV * 4.1) ) * 0.3333;

                float blend = edgeFade + n * 0.5;
                float mask  = smoothstep(_NoiseThreshold,
                                         _NoiseThreshold + 0.15,
                                         blend);

                // Extra high-frequency debris around the edge
                float outerFade = saturate(((_SphereRadius * 1.5) - dist) / (_SphereRadius * 1.5));
                float highFreqNoise = ( noise(noiseUV * 7.0 + 13.0) +
                                        noise(noiseUV * 15.0 + 47.0) ) * 0.5;

                float islandMask = smoothstep(0.45, 0.9, highFreqNoise) * outerFade;

                // Skip pixels that don't contribute to cutout or islands
                if (max(mask, islandMask) < 0.5)
                    discard;

                // Same camera→player segment test as in pass 0
                float3 viewDir   = _PlayerWorldPos - _CameraWorldPos;
                float3 toPixel   = IN.worldPos - _CameraWorldPos;
                float  viewLength = length(viewDir);
                float  proj       = dot(toPixel, normalize(viewDir));

                if (proj < 0 || proj > viewLength)
                    discard;

                    //--------------------------------------------------
                    // Angle test: pixel must be roughly behind player
                    //--------------------------------------------------

                    float3 camToPlayer = _PlayerWorldPos - _CameraWorldPos;
                    float3 camToPixel  = IN.worldPos - _CameraWorldPos;

                    // Normalize both directions
                    float3 dirToPlayer = normalize(camToPlayer);
                    float3 dirToPixel  = normalize(camToPixel);

                    // Cosine of angle between pixel direction and player direction
                    float cosAngle = dot(dirToPixel, dirToPlayer);

                    // Threshold for acceptable angle (0.8 ≈ 36 degrees)
                    // Put this at top of shader:
                    // float _ViewConeCos;
                    if (cosAngle < _ViewConeCos)
                        discard;


                return 0;
            }
            ENDHLSL
        }

         // =====================================================================
        // PASS 1: FRONT FACES OF THE SPHERE (writes stencil = 1)
        // Same idea as pass 0, but now for the front side.
        // =====================================================================
        Pass
        {
            Cull Front       // draw front faces
            ZWrite Off
            ColorMask 0

            Stencil
            {
                Ref 2
                Comp Always
                Pass Replace
            }

            HLSLPROGRAM
            #pragma vertex   vert
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
            float _ViewConeCos;   // cosine of max angle between camera->player and camera->pixel

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

                return lerp( lerp(n00, n10, u.x),
                             lerp(n01, n11, u.x),
                             u.y );
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS);
                OUT.worldPos    = TransformObjectToWorld(IN.positionOS.xyz);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float dist    = distance(IN.worldPos, _SpherePosition);
                float2 noiseUV = IN.worldPos.xz * _NoiseScale;

                // Main radial falloff (center → radius)
                float edgeFade = saturate((_SphereRadius - dist) / _SphereRadius);

                // Core cutout noise (same idea as pass 0)
                float n = ( noise(noiseUV) +
                            noise(noiseUV * 2.3) +
                            noise(noiseUV * 4.1) ) * 0.3333;

                float blend = edgeFade + n * 0.5;
                float mask  = smoothstep(_NoiseThreshold,
                                         _NoiseThreshold + 0.15,
                                         blend);

                // Extra high-frequency debris around the edge
                float outerFade = saturate(((_SphereRadius * 1.5) - dist) / (_SphereRadius * 1.5));
                float highFreqNoise = ( noise(noiseUV * 7.0 + 13.0) +
                                        noise(noiseUV * 15.0 + 47.0) ) * 0.5;

                float islandMask = smoothstep(0.45, 0.9, highFreqNoise) * outerFade;

                // Skip pixels that don't contribute to cutout or islands
                if (max(mask, islandMask) < 0.5)
                    discard;

                // Same camera→player segment test as in pass 0
                float3 viewDir   = _PlayerWorldPos - _CameraWorldPos;
                float3 toPixel   = IN.worldPos - _CameraWorldPos;
                float  viewLength = length(viewDir);
                float  proj       = dot(toPixel, normalize(viewDir));

                if (proj < 0 || proj > viewLength)
                    discard;

                    //--------------------------------------------------
                    // Angle test: pixel must be roughly behind player
                    //--------------------------------------------------

                    float3 camToPlayer = _PlayerWorldPos - _CameraWorldPos;
                    float3 camToPixel  = IN.worldPos - _CameraWorldPos;

                    // Normalize both directions
                    float3 dirToPlayer = normalize(camToPlayer);
                    float3 dirToPixel  = normalize(camToPixel);

                    // Cosine of angle between pixel direction and player direction
                    float cosAngle = dot(dirToPixel, dirToPlayer);

                    // Threshold for acceptable angle (0.8 ≈ 36 degrees)
                    // Put this at top of shader:
                    // float _ViewConeCos;
                    if (cosAngle < _ViewConeCos)
                        discard;


                return 0;
            }
            ENDHLSL
        }

        // =====================================================================
        // PASS 2: EDGE STENCIL WRITER (writes stencil = 3 only on a thin band)
        // Used if you want a special effect right on the noisy edge.
        // =====================================================================
        Pass
        {
            Cull Off        // draw both front and back faces
            ZWrite Off
            ColorMask 0

            Stencil
            {
                Ref 3
                Comp Always
                Pass Replace
            }

            HLSLPROGRAM
            #pragma vertex   vert
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
            float _ViewConeCos;   // cosine of max angle between camera->player and camera->pixel

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

                return lerp( lerp(n00, n10, u.x),
                             lerp(n01, n11, u.x),
                             u.y );
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS);
                OUT.worldPos    = TransformObjectToWorld(IN.positionOS.xyz);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float dist    = distance(IN.worldPos, _SpherePosition);
                float2 noiseUV = IN.worldPos.xz * _NoiseScale;

                // Same basic mask as pass 0/1
                float edgeFade = saturate((_SphereRadius - dist) / _SphereRadius);

                float n = ( noise(noiseUV) +
                            noise(noiseUV * 2.3) +
                            noise(noiseUV * 4.1) ) * 0.3333;

                float blend = edgeFade + n * 0.5;
                float mask  = smoothstep(_NoiseThreshold,
                                         _NoiseThreshold + 0.15,
                                         blend);

                float outerFade  = saturate(((_SphereRadius * 1.4) - dist) / (_SphereRadius * 1.4));
                float noiseOuter = noise(noiseUV * 6.0 + 23.0);
                float islandMask = smoothstep(0.6, 0.95, noiseOuter) * outerFade;

                float combined = max(mask, islandMask);

                // ------------------------------------------------------------
                // Extract only a narrow band of "combined" values as the edge.
                // Two smoothsteps combine to create a ring-like region:
                //   - first grows from 0→1 (inner edge),
                //   - second shrinks from 1→0 (outer edge).
                // ------------------------------------------------------------
                float edge = smoothstep(0.45, 0.55, combined) *
                             (1 - smoothstep(0.55, 0.65, combined));

                // If we are not in that narrow band, skip the pixel.
                if (edge < 0.01)
                    discard;

                // Again, only between camera and player
                float3 viewDir   = _PlayerWorldPos - _CameraWorldPos;
                float3 toPixel   = IN.worldPos - _CameraWorldPos;
                float  viewLength = length(viewDir);
                float  proj       = dot(toPixel, normalize(viewDir));

                if (proj < 0 || proj > viewLength)
                    discard;

                    //--------------------------------------------------
// Angle test: pixel must be roughly behind player
//--------------------------------------------------

float3 camToPlayer = _PlayerWorldPos - _CameraWorldPos;
float3 camToPixel  = IN.worldPos - _CameraWorldPos;

// Normalize both directions
float3 dirToPlayer = normalize(camToPlayer);
float3 dirToPixel  = normalize(camToPixel);

// Cosine of angle between pixel direction and player direction
float cosAngle = dot(dirToPixel, dirToPlayer);

// Threshold for acceptable angle (0.8 ≈ 36 degrees)
// Put this at top of shader:
// float _ViewConeCos;
if (cosAngle < _ViewConeCos)
    discard;


                return 0;
            }
            ENDHLSL
        }
    }
}
