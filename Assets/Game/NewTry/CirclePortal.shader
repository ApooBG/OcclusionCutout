Shader "Custom/PipeWallOnly"
{
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Pass
        {
            Cull Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            struct appdata {
                float4 vertex : POSITION;
                float4 color : COLOR;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float4 color : COLOR;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.color = v.color;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // Render only inside-wall part (white vertices)
                if (i.color.r > 0.5)
                    return fixed4(0.8, 0.8, 0.8, 1);

                // Remove pixel
                discard;

                // Dummy fallback to satisfy compiler:
                return fixed4(0, 0, 0, 0);
            }

            ENDCG
        }
    }
}
