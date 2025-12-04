Shader "Hidden/SphereCollisionStencil"
{
    SubShader
    {
        Tags { "Queue"="Geometry-10" }

        Pass
        {
            ZWrite Off
            ColorMask 0

            Stencil
            {
                Ref 3
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
            float  _SphereRadius;

            float3 _CameraWorldPos;
            float3 _PlayerWorldPos;
            float  _SphereSideSign; // +1 front, -1 back, 0 = all

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS);
                OUT.worldPos = TransformObjectToWorld(IN.positionOS.xyz);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                // Distance check: only pixels INSIDE sphere volume
                float dist = distance(IN.worldPos, _SpherePosition);
                if (dist > _SphereRadius)
                    discard;

                // Optional sphere-side selection
                if (abs(_SphereSideSign) > 0.01)
                {
                    float3 dirToPixel = normalize(IN.worldPos - _SpherePosition);
                    float3 dirToCam   = normalize(_CameraWorldPos - _SpherePosition);

                    // dot > 0 → front half
                    float side = dot(dirToPixel, dirToCam);

                    // If we wanted camera-facing side:
                    if (_SphereSideSign > 0 && side < 0)
                        discard;

                    // If we wanted backside of sphere:
                    if (_SphereSideSign < 0 && side > 0)
                        discard;
                }

                return 0;
            }
            ENDHLSL
        }
    }
}
