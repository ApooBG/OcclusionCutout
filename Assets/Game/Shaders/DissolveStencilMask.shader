Shader "Hidden/PipeDissolve_DarkenCombined"
{
    Properties
    {
        _NoiseTex("Noise Texture", 2D) = "white" {}
        _BackgroundTex("Background", 2D) = "white" {}
        _DissolveThreshold("Dissolve Threshold", Range(0,1)) = 0.5
        _EdgeWidth("Edge Width", Range(0,0.2)) = 0.05
        _EdgeColor("Edge Color", Color) = (1,1,1,1)
        _DarkenAlpha("Darken Alpha", Range(0,1)) = 0.4
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
            sampler2D _BackgroundTex;
            float _DissolveThreshold;
            float _EdgeWidth;
            float4 _EdgeColor;
            float _DarkenAlpha;

            struct Attributes
            {
                float4 positionOS : POSITION;
            };


            //Defines the data passed from the vertex shader to the fragment shader.
            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float4 screenPos : TEXCOORD1;
            };


            //This is the vertex shader, which transforms each vertex from object space to various coordinate spaces needed later.
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.worldPos = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.screenPos = ComputeScreenPos(OUT.positionHCS);
                return OUT;
            }

            //This is the fragment (pixel) shader, which determines the final color and transparency of each pixel.
            /*
                Samples a noise texture based on world position to create a random dissolve pattern.

                Compares the noise value to _DissolveThreshold to determine which pixels dissolve (using discard).

                Uses smoothstep() to create a soft transition (edge effect) around the dissolve boundary.

                Samples a background texture using the screen-space position.

                Blends (lerp) between the edge color and background based on how close the pixel is to the dissolve edge.

                Adjusts the pixel’s alpha (transparency) for a fading effect.

                Returns the final RGBA color to render.
            */
            half4 frag(Varyings IN) : SV_Target
            {
                float2 noiseUV = IN.worldPos.xz * 0.5;
                float noise = tex2D(_NoiseTex, noiseUV).r;

                float diff = _DissolveThreshold - noise;
                float edge = smoothstep(0.0, _EdgeWidth, diff);

                if (noise > _DissolveThreshold)
                    discard;

                float2 screenUV = IN.screenPos.xy / IN.screenPos.w;
                float3 bg = tex2D(_BackgroundTex, screenUV).rgb;

                float3 finalColor = lerp(_EdgeColor.rgb, bg, edge);
                float finalAlpha = lerp(_DarkenAlpha, 1.0, edge);

                return float4(finalColor, finalAlpha);
            }
            ENDHLSL
        }
    }
    FallBack Off
}
