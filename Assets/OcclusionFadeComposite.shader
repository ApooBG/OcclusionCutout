Shader "Hidden/OcclusionFadeComposite"
{
    Properties
    {
        _FadeAmount ("Fade Amount", Range(0,1)) = 1
        _DitherScale("Dither Scale", Range(0.5,8)) = 3
    }
    SubShader
    {
        Tags{ "Queue"="Overlay" }
        Pass
        {
            ZTest Always
            ZWrite Off
            Cull Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            // FullScreenPass binds the scene color into _CameraOpaqueTexture
            TEXTURE2D_X(_CameraOpaqueTexture);
            SAMPLER(sampler_CameraOpaqueTexture);

            // We set this globally from the VolumeDepth pass
            TEXTURE2D_X(_OccDepthTex);
            SAMPLER(sampler_OccDepthTex);

            CBUFFER_START(UnityPerMaterial)
                float _FadeAmount;
                float _DitherScale;
            CBUFFER_END

            struct VOut { float4 posCS:SV_Position; float2 uv:TEXCOORD0; };
            VOut vert(uint id:SV_VertexID)
            {
                float2 p = float2((id==1)?3.0:-1.0, (id==2)?-3.0:1.0);
                VOut o; o.posCS=float4(p,0,1); o.uv=p*0.5+0.5; return o;
            }

            float bayer4x4(float2 p)
            {
                int2 ip = int2(floor(p)) & 3;
                static const float m[16] = {0,8,2,10, 12,4,14,6, 3,11,1,9, 15,7,13,5};
                return m[ip.y*4+ip.x]/16.0;
            }

            float Linear01FromRaw(float rawZ)
            {
                float eye = LinearEyeDepth(rawZ, _ZBufferParams);
                return saturate(eye / _ProjectionParams.z);
            }

            float4 frag(VOut i):SV_Target
            {
                float4 col = SAMPLE_TEXTURE2D_X(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, i.uv);

                // scene depth (linear 0..1)
                float sceneRaw = SampleSceneDepth(i.uv);
                float scene01  = Linear01FromRaw(sceneRaw);

                // volume depth+mask
                float4 occ   = SAMPLE_TEXTURE2D_X(_OccDepthTex, sampler_OccDepthTex, i.uv);
                float occ01  = occ.r;
                float mask   = occ.a;

                // Hide only pixels IN FRONT of the volume (so you see things behind)
                if (mask > 0.5 && scene01 < occ01 - 1e-4)
                {
                    float keep = 1.0 - _FadeAmount;
                    float th = bayer4x4(i.uv * _ScreenParams.xy / _DitherScale);
                    if (th > keep) discard;  // punch hole
                }
                return col;
            }
            ENDHLSL
        }
    }
    FallBack Off
}
