Shader "Hidden/SphereEdgeStencilWrite_Enhanced"
{
    Properties
    {
        _EdgeThickness   ("Base Edge Thickness", Float) = 0.01
        _Move   ("Texture Movement", Range(0,9)) = 0.5
        _NoiseTex        ("Edge Noise", 2D) = "white" {}
        _NoiseScale      ("Noise Scale (world)", Float) = 0.3
        _NoiseCutoffMin  ("Noise Cutoff Min", Range(0,1)) = 0.3
        _NoiseCutoffMax  ("Noise Cutoff Max", Range(0,1)) = 0.7
        _GapCellSize     ("Gap Cell Size (world)", Float) = 0.5
        _GapKeepMin      ("Gap Keep Min", Range(0,1)) = 0.3
        _GapKeepMax      ("Gap Keep Max", Range(0,1)) = 0.9
    }

    SubShader
    {
        Tags {
            "RenderPipeline"="UniversalRenderPipeline"
            "Queue"="Geometry+20"
            "RenderType"="Opaque"
        }

        Pass
        {
            Name "SphereEdgeStencilWrite"
            ZWrite Off
            ZTest Always
            ColorMask 0
            Cull Front

            Stencil
            {
                Ref 5
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
                float4 positionCS : SV_POSITION;
                float4 screenPos  : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
            };

            TEXTURE2D_X(_OccludableDepthTex);
            SAMPLER(sampler_OccludableDepthTex);
            TEXTURE2D(_NoiseTex);
            SAMPLER(sampler_NoiseTex);

            float _EdgeThickness;
            float _NoiseScale;
            float _NoiseCutoffMin;
            float _NoiseCutoffMax;
            float _GapCellSize;
            float _GapKeepMin;
            float _GapKeepMax;
            float _Move;

            float hash21(float2 p)
            {
                p = frac(p * float2(123.34, 345.45));
                p += dot(p, p + 34.345);
                return frac(p.x * p.y);
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.positionCS = TransformWorldToHClip(OUT.positionWS);
                OUT.screenPos  = ComputeScreenPos(OUT.positionCS);
                return OUT;
            }

            float4 frag(Varyings IN) : SV_Target
            {
                float3 posVS = TransformWorldToView(IN.positionWS);
                float  sphereDepth = -posVS.z;

                float2 uv = IN.screenPos.xy / IN.screenPos.w;
                float  occluderDepth = SAMPLE_TEXTURE2D_X(
                    _OccludableDepthTex,
                    sampler_OccludableDepthTex,
                    uv
                ).r;

                if (occluderDepth <= 0.0001)
                    discard;

                float delta = sphereDepth - occluderDepth;
                if (delta > _EdgeThickness || delta < -_EdgeThickness * 2.0)
                    discard;

                if (_GapCellSize > 0.0001)
                {
                    float2 cellCoord = floor(IN.positionWS.xz / _GapCellSize);
                    float  cellRand  = hash21(cellCoord * 3.17);
                    float  keepChance = lerp(_GapKeepMin, _GapKeepMax, cellRand);
                    if (cellRand > keepChance)
                        discard;
                }

                float2 noiseUV = IN.positionWS.xz * _NoiseScale;

                float timeShift = _Time.y * 0.1 * _Move;
                noiseUV += float2(timeShift, -timeShift);

                float n0 = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, noiseUV).r;
                float n1 = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, noiseUV * 2.3).r;
                float n2 = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, noiseUV * 5.1).r;
                float noise = (n0 + 0.6 * n1 + 0.3 * n2) / (1.0 + 0.6 + 0.3);

                float randVal = hash21(IN.positionWS.xz * 0.73);
                float localCutoff = lerp(_NoiseCutoffMin, _NoiseCutoffMax, randVal);
                if (noise < localCutoff)
                    discard;

                return 0;
            }

            ENDHLSL
        }
    }
}
