Shader "Custom/StencilMaskInvisibleDoubleSided_DepthFixed"
{
    Properties
    {
        [IntRange]_StencilID("Stencil ID", Range(0,255)) = 2
    }

    SubShader
    {
        Tags { "Queue"="Geometry-20" "RenderPipeline"="UniversalPipeline" }

        Cull Off

        Pass
        {
            ColorMask 0
            ZWrite On
            ZTest LEqual
            Stencil
            {
                Ref [_StencilID]
                Comp Always
                Pass Replace
            }
        }
    }
}
