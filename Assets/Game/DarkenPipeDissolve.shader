Shader "Hidden/DarkenPipeDissolve"
{
    Properties
    {
        _NoiseTex("Noise Texture", 2D) = "white" {}
        _DissolveThreshold("Dissolve Threshold", Range(0,1)) = 0.5
        _EdgeWidth("Edge Width", Range(0,0.2)) = 0.05
        _EdgeColor("Edge Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "Queue"="Transparent+3" "RenderType"="Transparent" }
        Pass
        {
ZWrite Off
ZTest LEqual
Cull Off
Blend SrcAlpha OneMinusSrcAlpha
ColorMask RGBA

            Stencil
            {
                Ref 2
                Comp Equal
                Pass Keep
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            sampler2D _NoiseTex;
            float _DissolveThreshold;
            float _EdgeWidth;
            float4 _EdgeColor;

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 worldPos : TEXCOORD0;
            };

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.worldPos = TransformObjectToWorld(IN.positionOS.xyz);
                return OUT;
            }

            half4 frag (Varyings IN) : SV_Target
            {
                float2 noiseUV = IN.worldPos.xz * 0.5;
                float noise = tex2D(_NoiseTex, noiseUV).r;

                float diff = _DissolveThreshold - noise;
                float edge = smoothstep(0.0, _EdgeWidth, diff);

                if (noise > _DissolveThreshold)
                    discard;

                float alpha = lerp(0.4, 1.0, edge);
                float3 color = lerp(_EdgeColor.rgb, float3(0,0,0), edge);
                return float4(color, alpha);
            }
            ENDHLSL
        }
    }
    FallBack Off
}
