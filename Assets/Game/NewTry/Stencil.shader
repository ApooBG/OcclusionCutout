Shader "Debug/Stencil"
{
    SubShader
    {
        Tags { "Queue"="Overlay" }
        Pass
        {
            ColorMask RGB
            ZTest Always
            ZWrite Off
            Cull Off

            Stencil
            {
                Ref 5
                Comp Equal
                Pass Keep
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct v2f { float4 pos : SV_POSITION; };
            v2f vert(appdata_base v) { v2f o; o.pos = UnityObjectToClipPos(v.vertex); return o; }
            fixed4 frag(v2f i) : SV_Target { return fixed4(1, 0, 0, 1); } // red if stencil == 1
            ENDHLSL
        }
    }
}
