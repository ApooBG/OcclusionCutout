Shader "Hidden/OcclusionStencilWrite" {
  SubShader {
    Tags { "Queue"="Geometry-20" "RenderType"="Opaque" }
    Pass {
      ZTest Always
      ZWrite Off
      ColorMask 0
      Stencil { Ref 1 Comp Always Pass Replace }
      HLSLPROGRAM
      #pragma vertex vert
      #pragma fragment frag
      #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
      struct A{float4 pos:POSITION;};
      struct V{float4 pos:SV_Position;};
      V vert(A v){ V o; o.pos = TransformObjectToHClip(v.pos.xyz); return o; }
      half4 frag(V i):SV_Target{ return 0; }
      ENDHLSL
    }
  }
  FallBack Off
}
