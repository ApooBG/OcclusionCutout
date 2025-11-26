Shader "Hidden/SphereEdgeStencilWrite"
{
    Properties
    {
        _EdgeThickness   ("Base Edge Thickness", Float) = 0.01
        _NoiseTex        ("Edge Noise", 2D) = "white" {}
        _NoiseScale      ("Noise Scale (world)", Float) = 0.3
        _NoiseCutoffMin  ("Noise Cutoff Min", Range(0,1)) = 0.3
        _NoiseCutoffMax  ("Noise Cutoff Max", Range(0,1)) = 0.7
        _GapCellSize     ("Gap Cell Size (world)", Float) = 0.5
        _GapKeepMin      ("Gap Keep Min", Range(0,1)) = 0.3
        _GapKeepMax      ("Gap Keep Max", Range(0,1)) = 0.9
        _Radius          ("Edge Radius", Float) = 1.0
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
            #pragma shader_feature _ANIMATE_VERTS_ON
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
            float _Radius;
            float _AnimateVerts;

            float hash21(float2 p)
            {
                p = frac(p * float2(123.34, 345.45));
                p += dot(p, p + 34.345);
                return frac(p.x * p.y);
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                float3 worldPos = TransformObjectToWorld(IN.positionOS.xyz);
                float3 centerWS = _WorldSpaceCameraPos;

            #if defined(_ANIMATE_VERTS_ON)
                float2 noiseUV = worldPos.xz * _NoiseScale;
                //noiseUV += float2(_Time.y * 0.1, -_Time.y * 0.1);

                float mip = 0.0;
                float n0 = tex2Dlod(sampler_NoiseTex, float4(noiseUV * 0.5, 0, mip)).r;
                float n1 = tex2Dlod(sampler_NoiseTex, float4(noiseUV * 1.3 + 11.7, 0, mip)).r;
                float noise = saturate(n0 * 0.6 + n1 * 0.4);
                noise = pow(noise, 3.0);

                float3 dir = normalize(worldPos - centerWS);
                worldPos += dir * (noise - 0.5) * _EdgeThickness * 2.0;
            #endif

                OUT.positionWS = worldPos;
                OUT.positionCS = TransformWorldToHClip(worldPos);
                OUT.screenPos  = ComputeScreenPos(OUT.positionCS);
                return OUT;
            }


            float4 frag(Varyings IN) : SV_Target
            {
                float3 posVS = TransformWorldToView(IN.positionWS);
                float sphereDepth = -posVS.z;

                float2 uv = IN.screenPos.xy / IN.screenPos.w;
                float occluderDepth = SAMPLE_TEXTURE2D_X(_OccludableDepthTex, sampler_OccludableDepthTex, uv).r;
                if (occluderDepth <= 0.0001) discard;

                float delta = sphereDepth - occluderDepth;
                if (abs(delta) > _EdgeThickness)
                    discard;

                float2 noiseUV = IN.positionWS.xz * _NoiseScale;
                //noiseUV += float2(_Time.y * 0.1, _Time.y * -0.1);

                float noise = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, noiseUV).r;
                noise = pow(noise, 2.5);

                float randVal = hash21(IN.positionWS.xz * 3.1);
                float localCutoff = lerp(_NoiseCutoffMin, _NoiseCutoffMax, randVal);

                if (noise < localCutoff)
                    discard;

                return 0;
            }

            ENDHLSL
        }
    }
}
