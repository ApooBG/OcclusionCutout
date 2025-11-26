Shader "Hidden/DarkenPipeOverlay" {
    SubShader {
        Tags { "Queue"="Transparent+2" "RenderType"="Transparent" }

        Pass {
            ZTest Always
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            ColorMask RGBA
            Cull Off

            Stencil {
                Ref 2
                Comp Equal
                Pass Keep
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes { float4 positionOS : POSITION; }; //Defines the input data that comes into the vertex shader from the mesh.
            struct Varyings { float4 positionHCS : SV_Position; }; //struct Varyings { float4 positionHCS : SV_Position; };

            //This is the vertex shader, which transforms each vertex from object space → clip space.
            Varyings vert(Attributes IN) {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                return OUT;
            }

            //This is the fragment (pixel) shader, which determines the final color of each pixel.
            half4 frag(Varyings i) : SV_Target {
                return half4(0, 0, 0, 0.4); // darken overlay
            }
            ENDHLSL
        }
    }
    FallBack Off
}
