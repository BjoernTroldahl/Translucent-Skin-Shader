Shader "GLSL translucent surfaces" {
   Properties {
      _Color ("Diffuse Material Color", Color) = (1,1,1,1) 
      _SpecColor ("Specular Material Color", Color) = (1,1,1,1) 
      _Shininess ("Shininess", Float) = 10
      _DiffuseTranslucentColor ("Diffuse Translucent Color", Color) 
         = (1,1,1,1) 
      _ForwardTranslucentColor ("Forward Translucent Color", Color) 
         = (1,1,1,1) 
      _Sharpness ("Sharpness", Float) = 10
   }
   SubShader {
      Pass {      
         Tags { "LightMode" = "ForwardBase" } 
            // pass for ambient light and first light source
         Cull Off // show frontfaces and backfaces
 
         GLSLPROGRAM
 
         // User-specified properties
         uniform vec4 _Color; 
         uniform vec4 _SpecColor; 
         uniform float _Shininess;
         uniform vec4 _DiffuseTranslucentColor; 
         uniform vec4 _ForwardTranslucentColor; 
         uniform float _Sharpness;
 
         // The following built-in uniforms (except _LightColor0) 
         // are also defined in "UnityCG.glslinc", 
         // i.e. one could #include "UnityCG.glslinc" 
         uniform vec3 _WorldSpaceCameraPos; 
            // camera position in world space
         uniform mat4 _Object2World; // model matrix
         uniform mat4 _World2Object; // inverse model matrix
         uniform vec4 _WorldSpaceLightPos0; 
            // direction to or position of light source
         uniform vec4 _LightColor0; 
            // color of light source (from "Lighting.cginc")
 
         varying vec4 position; 
            // position of the vertex (and fragment) in world space 
         varying vec3 varyingNormalDirection; 
            // surface normal vector in world space
 
         #ifdef VERTEX
 
         void main()
         {                                
            mat4 modelMatrix = _Object2World;
            mat4 modelMatrixInverse = _World2Object; // unity_Scale.w 
               // is unnecessary because we normalize vectors
 
            position = modelMatrix * gl_Vertex;
            varyingNormalDirection = normalize(vec3(
               vec4(gl_Normal, 0.0) * modelMatrixInverse));
 
            gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
         }
 
         #endif
 
         #ifdef FRAGMENT
 
         void main()
         {
            vec3 normalDirection = normalize(varyingNormalDirection);
            if (!gl_FrontFacing) // do we look at the backface?
            {
               normalDirection = -normalDirection; // flip normal
            }
 
            vec3 viewDirection = 
               normalize(_WorldSpaceCameraPos - vec3(position));
            vec3 lightDirection;
            float attenuation;
 
            if (0.0 == _WorldSpaceLightPos0.w) // directional light?
            {
               attenuation = 1.0; // no attenuation
               lightDirection = normalize(vec3(_WorldSpaceLightPos0));
            } 
            else // point or spot light
            {
               vec3 vertexToLightSource = 
                  vec3(_WorldSpaceLightPos0 - position);
               float distance = length(vertexToLightSource);
               attenuation = 1.0 / distance; // linear attenuation 
               lightDirection = normalize(vertexToLightSource);
            }

            vec3 ambientLighting = 
               vec3(gl_LightModel.ambient) * vec3(_Color);
 
            vec3 diffuseReflection = 
               attenuation * vec3(_LightColor0) * vec3(_Color) 
               * max(0.0, dot(normalDirection, lightDirection));
 
            vec3 specularReflection;
            if (dot(normalDirection, lightDirection) < 0.0) 
               // light source on the wrong side?
            {
               specularReflection = vec3(0.0, 0.0, 0.0); 
                  // no specular reflection
            }
            else // light source on the right side
            {
               specularReflection = attenuation * vec3(_LightColor0) 
                  * vec3(_SpecColor) * pow(max(0.0, dot(
                  reflect(-lightDirection, normalDirection), 
                  viewDirection)), _Shininess);
            }

            vec3 diffuseTranslucency = attenuation * vec3(_LightColor0) 
               * vec3(_DiffuseTranslucentColor) 
               * max(0.0, dot(lightDirection, -normalDirection));
 
            vec3 forwardTranslucency;
            if (dot(normalDirection, lightDirection) > 0.0) 
               // light source on the wrong side?
            {
               forwardTranslucency = vec3(0.0, 0.0, 0.0); 
                  // no forward-scattered translucency
            }
            else // light source on the right side
            {
               forwardTranslucency = attenuation * vec3(_LightColor0) 
                  * vec3(_ForwardTranslucentColor) * pow(max(0.0, 
                  dot(-lightDirection, viewDirection)), _Sharpness);
            }
 
            gl_FragColor = vec4(ambientLighting 
               + diffuseReflection + specularReflection 
               + diffuseTranslucency + forwardTranslucency, 1.0);
         }
 
         #endif
 
         ENDGLSL
      }
 
      Pass {      
         Tags { "LightMode" = "ForwardAdd" } 
            // pass for additional light sources
         Cull Off
         Blend One One // additive blending 
 
        GLSLPROGRAM
 
         // User-specified properties
         uniform vec4 _Color; 
         uniform vec4 _SpecColor; 
         uniform float _Shininess;
         uniform vec4 _DiffuseTranslucentColor; 
         uniform vec4 _ForwardTranslucentColor; 
         uniform float _Sharpness;
 
         // The following built-in uniforms (except _LightColor0) 
         // are also defined in "UnityCG.glslinc", 
         // i.e. one could #include "UnityCG.glslinc" 
         uniform vec3 _WorldSpaceCameraPos; 
            // camera position in world space
         uniform mat4 _Object2World; // model matrix
         uniform mat4 _World2Object; // inverse model matrix
         uniform vec4 _WorldSpaceLightPos0; 
            // direction to or position of light source
         uniform vec4 _LightColor0; 
            // color of light source (from "Lighting.cginc")
 
         varying vec4 position; 
            // position of the vertex (and fragment) in world space 
         varying vec3 varyingNormalDirection; 
            // surface normal vector in world space
 
         #ifdef VERTEX
 
         void main()
         {                                
            mat4 modelMatrix = _Object2World;
            mat4 modelMatrixInverse = _World2Object; // unity_Scale.w 
               // is unnecessary because we normalize vectors
 
            position = modelMatrix * gl_Vertex;
            varyingNormalDirection = normalize(vec3(
               vec4(gl_Normal, 0.0) * modelMatrixInverse));
 
            gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
         }
 
         #endif
 
         #ifdef FRAGMENT
 
         void main()
         {
            vec3 normalDirection = normalize(varyingNormalDirection);
            if (!gl_FrontFacing) // do we look at the backface?
            {
               normalDirection = -normalDirection; // flip normal
            }
 
            vec3 viewDirection = 
               normalize(_WorldSpaceCameraPos - vec3(position));
            vec3 lightDirection;
            float attenuation;
 
            if (0.0 == _WorldSpaceLightPos0.w) // directional light?
            {
               attenuation = 1.0; // no attenuation
               lightDirection = normalize(vec3(_WorldSpaceLightPos0));
            } 
            else // point or spot light
            {
               vec3 vertexToLightSource = 
                  vec3(_WorldSpaceLightPos0 - position);
               float distance = length(vertexToLightSource);
               attenuation = 1.0 / distance; // linear attenuation 
               lightDirection = normalize(vertexToLightSource);
            }
 
            vec3 diffuseReflection = 
               attenuation * vec3(_LightColor0) * vec3(_Color) 
               * max(0.0, dot(normalDirection, lightDirection));
 
            vec3 specularReflection;
            if (dot(normalDirection, lightDirection) < 0.0) 
               // light source on the wrong side?
            {
               specularReflection = vec3(0.0, 0.0, 0.0); 
                  // no specular reflection
            }
            else // light source on the right side
            {
               specularReflection = attenuation * vec3(_LightColor0) 
                  * vec3(_SpecColor) * pow(max(0.0, dot(
                  reflect(-lightDirection, normalDirection), 
                  viewDirection)), _Shininess);
            }
 
            vec3 diffuseTranslucency = attenuation * vec3(_LightColor0) 
               * vec3(_DiffuseTranslucentColor) 
               * max(0.0, dot(lightDirection, -normalDirection));
 
            vec3 forwardTranslucency;
            if (dot(normalDirection, lightDirection) > 0.0) 
               // light source on the wrong side?
            {
               forwardTranslucency = vec3(0.0, 0.0, 0.0); 
                  // no forward-scattered translucency
            }
            else // light source on the right side
            {
               forwardTranslucency = attenuation * vec3(_LightColor0) 
                  * vec3(_ForwardTranslucentColor) * pow(max(0.0, 
                  dot(-lightDirection, viewDirection)), _Sharpness);
            }
 
            gl_FragColor = vec4(diffuseReflection + specularReflection 
               + diffuseTranslucency + forwardTranslucency, 1.0);
         }
 
         #endif
 
         ENDGLSL
      }
   } 
   // The definition of a fallback shader should be commented out 
   // during development:
   // Fallback "Specular"
}