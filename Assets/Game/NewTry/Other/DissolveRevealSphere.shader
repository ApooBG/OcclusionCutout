Shader "Custom/DissolveRevealSphere"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _NoiseTex ("Noise Texture", 2D) = "white" {}
        _SphereCenter ("Sphere Center (World)", Vector) = (0,0,0,0)
        _Radius ("Radius", Float) = 3
        _EdgeThickness ("Edge Thickness", Float) = 1
        _NoiseScale ("Noise Scale", Float) = 1
        _NoiseOffset ("Noise Offset", Float) = 0
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        LOD 100
        Cull Off
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            sampler2D _NoiseTex;
            float4 _MainTex_ST;
            float4 _SphereCenter;
            float _Radius;
            float _EdgeThickness;
            float _NoiseScale;
            float _NoiseOffset;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float dist = distance(i.worldPos, _SphereCenter.xyz);
                float dissolveEdge = saturate((dist - _Radius) / _EdgeThickness);

                float2 noiseUV = i.worldPos.xz * _NoiseScale;
                float noise = tex2D(_NoiseTex, noiseUV).r;

                float mask = dissolveEdge - noise + _NoiseOffset;

                clip(1.0 - mask); // Invert visibility: only show intersected/noisy edge

                float4 col = tex2D(_MainTex, i.uv);
                col.a = 1.0 - dissolveEdge;
                return col;
            }
            ENDCG
        }
    }
}
