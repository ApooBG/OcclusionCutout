Shader "Hidden/OcclusionStencilWritePipe" {
    SubShader {
        Tags { "Queue"="Geometry-20" "RenderType"="Opaque" }
        Pass {
            ZWrite Off
            ColorMask 0
            Cull Front

            Stencil {
                Ref 2
                Comp Always
                Pass Replace
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            float3 _CameraWorldPos;
            float _StartDistance;
            float _EndDistance;

            struct Attributes {
                float4 positionOS : POSITION;
            };

            struct Varyings {
                float4 positionCS : SV_POSITION;
                float3 worldPos : TEXCOORD0;
            };

            Varyings vert(Attributes input) {
                Varyings output;
                output.worldPos = TransformObjectToWorld(input.positionOS.xyz);
                output.positionCS = TransformWorldToHClip(output.worldPos);
                return output;
            }

            half4 frag(Varyings i) : SV_Target {
                float d = distance(i.worldPos, _CameraWorldPos);
if (d > _EndDistance) discard;
                return 0;
            }
            ENDHLSL
        }
    }
    FallBack Off
}
