Shader "Hidden/OcclusionStencilWrite" {
  SubShader {
    Tags { "Queue"="Geometry-20" "RenderType"="Opaque" } //-20 means 2000-20 which means that the stencil is written before the normal wall and opther stuff.
    Pass {
      ZTest Always //every covered pixel passes the depth test, even if the sphere is “behind” other geometry
      ZWrite Off //don’t modify the depth buffer. We’re not trying to occlude anything—only tagging stencil
      ColorMask 0 //write no color channels

      //ref is the value we compare against
      //comp means the stencil test always passes (no check)
      //replace means on a passing pixel, write 1 into the stencil buffer.
      Stencil { Ref 1 Comp Always Pass Replace } 
      HLSLPROGRAM
      #pragma vertex vert
      #pragma fragment frag
      #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
      /*
        Vertex: standard object, clip-space transform so Unity can rasterize the sphere.

        Fragment: returns a color, but it’s ignored because ColorMask 0. We only needed the fragment stage so the pipeline will run and apply the stencil write per-pixel.
      */
      struct A{float4 pos:POSITION;}; // vertex input from the mesh
      struct V{float4 pos:SV_Position;}; // vertex output to the rasterizer

      //TransformObjectToHClip(...) (from Core.hlsl) multiplies the object-space position by Unity’s matrices: object → world → view → projection  =  clip space
      //The result (SV_Position) tells the GPU where on screen this vertex lands. The rasterizer then fills the triangle and generates fragments (candidate pixels) for the fragment stage.
      V vert(A v){ V o; o.pos = TransformObjectToHClip(v.pos.xyz); return o; }


      //SV_Target = “this is the color I’d write to the color buffer.”
      //We return 0 (black/transparent), but earlier in the pass we set:
      half4 frag(V i):SV_Target{ return 0; }
      ENDHLSL
    }
  }
  FallBack Off //No fallback—if this can’t run, don’t try another shader.
}
