Shader "Cg shader using blending" {
    Properties {
      _Color ("Color", Color) = (1, 1, 1, 0.5) 
         // user-specified RGBA color including opacity
   }
   SubShader {
      Tags { "Queue" = "Transparent" } 
         // draw after all opaque geometry has been drawn
      Pass {
         Cull Front // first pass renders only back faces 
             // (the "inside")
         ZWrite Off // don't write to depth buffer 
            // in order not to occlude other objects
         Blend SrcAlpha OneMinusSrcAlpha // use alpha blending

         CGPROGRAM 
 
         #pragma vertex vert 
         #pragma fragment frag

         #include "UnityCG.cginc"

         uniform float4 _Color; // define shader property for shaders
 
         float4 vert(float4 vertexPos : POSITION) : SV_POSITION 
         {
            return UnityObjectToClipPos(vertexPos);
         }
 
         float4 frag(void) : COLOR 
         {
            return float4(1.0, 0.0, 0.0, 0.8);
               // the fourth component (alpha) is important: 
               // this is semitransparent red
         }
 
         ENDCG  
      }

      Pass {
         Cull Back // second pass renders only front faces 
             // (the "outside")
         ZWrite Off // don't write to depth buffer 
            // in order not to occlude other objects
         Blend SrcAlpha OneMinusSrcAlpha // use alpha blending

         CGPROGRAM 
 
         #pragma vertex vert 
         #pragma fragment frag
 
         float4 vert(float4 vertexPos : POSITION) : SV_POSITION 
         {
            return UnityObjectToClipPos(vertexPos);
         }
 
         float4 frag(void) : COLOR 
         {
            return float4(0.0, 1.0, 0.0, 0.3);
               // the fourth component (alpha) is important: 
               // this is semitransparent green
         }
 
         ENDCG  
      }
   }
}