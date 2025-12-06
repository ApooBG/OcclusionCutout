Shader "Hidden/Cutout_Edge"
{
    Properties
    {
        // How “full” the edge is with fragments (0 = almost empty, 1 = solid)
        _NoiseThreshold   ("Fragment Fill Threshold", Range(0,1)) = 0.35

        // World-space thickness of the spherical edge band where fragments appear
        _EdgeThickness    ("Edge Band Thickness", Float) = 0.4

        // Controls how many pieces there are (higher = more, smaller pieces)
        _CellDensity      ("Piece Density", Float) = 4.0

        // Radius of each Voronoi piece (in noise space, not world units)
        _FragmentRadius   ("Piece Radius", Range(0.01,1)) = 0.25

        // Softness of the piece edge (0 = razor sharp)
        _FragmentFeather  ("Piece Feather", Range(0,0.5)) = 0.05

        // 0 = grid-ish, 1 = fully random positions of pieces
        _CellJitter       ("Piece Randomness", Range(0,1)) = 1.0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }

        // BACK faces of the sphere write stencil = 2 with noisy fragments
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
            #pragma vertex   vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // -------- Shared Structs --------
            struct Attributes
            {
                float4 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 worldPos    : TEXCOORD0;
            };

            // -------- Uniforms from C# --------
            float3 _SpherePosition;
            float  _SphereRadius;

            float  _NoiseThreshold;
            float  _EdgeThickness;
            float  _CellDensity;
            float  _FragmentRadius;
            float  _FragmentFeather;
            float  _CellJitter;

            float3 _CameraWorldPos;
            float3 _PlayerWorldPos;

            // -------- Hash helpers (3D) --------
            float3 hash31(float3 p)
            {
                // simple, cheap 3D hash → [0,1]^3
                p = frac(p * 0.1031);
                p += dot(p, p.yzx + 33.33);
                return frac((p.xxy + p.yzz) * p.zyx);
            }

            // -------- 3D Voronoi: distance to nearest random feature point --------
            float voronoi3(float3 p, float jitter)
            {
                float3 i = floor(p);
                float3 f = frac(p);

                float minDist = 10.0;

                [unroll]
                for (int z = -1; z <= 1; z++)
                {
                    [unroll]
                    for (int y = -1; y <= 1; y++)
                    {
                        [unroll]
                        for (int x = -1; x <= 1; x++)
                        {
                            float3 cell = float3(x, y, z);
                            float3 rnd  = hash31(i + cell);

                            // move feature point inside the cell
                            rnd = (rnd * 2.0 - 1.0) * jitter;

                            float3 diff = cell + rnd - f;
                            float d = dot(diff, diff);  // squared distance is fine

                            minDist = min(minDist, d);
                        }
                    }
                }

                return sqrt(minDist); // actual distance
            }

            // -------- Vertex --------
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS);
                OUT.worldPos    = TransformObjectToWorld(IN.positionOS.xyz);
                return OUT;
            }

            // -------- Fragment --------
            half4 frag(Varyings IN) : SV_Target
            {
                // radial distance from sphere center
                float dist = distance(IN.worldPos, _SpherePosition);

                // Edge band around the sphere surface where we allow fragments
                // edge = 1 at sphere surface, 0 outside the band
                float edge = 1.0 - saturate(abs(dist - _SphereRadius) / max(_EdgeThickness, 1e-4));

                // 3D Voronoi noise for shatter pieces (no projection stretching)
                float3 p = IN.worldPos * _CellDensity;
                float d = voronoi3(p, _CellJitter);

                // Small islands around each Voronoi seed → individual debris pieces
                float islands = 1.0 - smoothstep(_FragmentRadius,
                                                 _FragmentRadius + _FragmentFeather,
                                                 d);

                // Combine edge band & islands
                float debrisMask = edge * islands;

                // Control fill amount with slider
                float mask = step(_NoiseThreshold, debrisMask);

                if (mask < 0.5)
                    discard;

                // We only care about stencil, not color
                return 0;
            }
            ENDHLSL
        }
    }
}
