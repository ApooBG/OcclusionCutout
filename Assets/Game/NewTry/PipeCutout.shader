Shader "Hidden/PipeStencilWrite"
{
    Properties {}
    SubShader
    {
        Tags { "Queue"="Geometry" "RenderType"="Opaque" }
        Pass
        {
            Cull Front
            ZTest LEqual
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

            struct appdata { float4 vertex : POSITION; };
            struct v2f {
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
            };

            int _BoundsCount;
            float4 _BoundsCenters[32];
            float4 _BoundsExtents[32];

            v2f vert(appdata v)
            {
                v2f o;
                float3 wp = TransformObjectToWorld(v.vertex.xyz);
                o.pos = TransformWorldToHClip(wp);
                o.worldPos = wp;
                return o;
            }

            bool insideAnyBounds(float3 wp)
            {
                for (int i = 0; i < _BoundsCount; i++)
                {
                    float3 c = _BoundsCenters[i].xyz;
                    float3 e = _BoundsExtents[i].xyz;
                    if (all(abs(wp - c) <= e))
                        return true;
                }
                return false;
            }

            half4 frag(v2f i) : SV_Target
            {
                if (!insideAnyBounds(i.worldPos))
                    discard;
                return 0;
            }
            ENDHLSL
        }
    }
    FallBack Off
}
