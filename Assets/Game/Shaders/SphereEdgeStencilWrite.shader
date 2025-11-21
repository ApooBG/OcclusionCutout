Shader "Hidden/SphereEdgeStencilWrite"
{
    Properties
    {
        _EdgeThickness   ("Base Edge Thickness", Float) = 0.01
        _NoiseTex        ("Edge Noise", 2D) = "white" {}
        _NoiseScale      ("Noise Scale (world)", Float) = 0.3
        _NoiseCutoff     ("Noise Cutoff", Range(0,1)) = 0.5
    }

    SubShader
    {
        Tags{
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
            float _NoiseCutoff;

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
                // --- depth band (where sphere touches occluder) ---
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

                float diff = abs(sphereDepth - occluderDepth);
                if (diff > _EdgeThickness)
                    discard;          // outside contact band

                // --- noisy mask inside that band ---
                // world-space so the pattern follows geometry
                float2 noiseUV = IN.positionWS.xz * _NoiseScale;
                float  noise   = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, noiseUV).r;

                // tweak shape a bit (optional)
                // noise = pow(noise, 1.5); // uncomment to bias

                if (noise < _NoiseCutoff)
                    discard;          // create holes / broken chunks

                // surviving pixels write stencil = 5
                return 0;
            }
            ENDHLSL
        }
    }
}
