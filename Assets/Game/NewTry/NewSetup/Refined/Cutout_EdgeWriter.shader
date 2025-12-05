Shader "Hidden/Cutout_Back"
{
    Properties
    {
        _NoiseScale("Noise Scale", Float) = 1.0
        _NoiseThreshold("Noise Threshold", Float) = 0.5
        _ViewConeCos("View Cone Cosine", Range(0,1)) = 0.8
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
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
            float _ViewConeCos;

            // noise functions ...

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS);
                OUT.worldPos = TransformObjectToWorld(IN.positionOS.xyz);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                // your noise, island, cone logic
                // final action:
                discard;
                return 0;
            }
            ENDHLSL
        }
    }
}
