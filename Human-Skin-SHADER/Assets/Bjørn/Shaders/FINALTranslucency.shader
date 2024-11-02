

Shader "Custom/FINALTranslucency" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
        _OcclusionTex("Occlusion Map", 2D) = "white" {}
        //changed to black from white for more of a subsurface coloring
        _SubsurfaceTex ("Subsurface Precalc", 2D) = "black" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
        Distortion("Distortion", Range(0,2)) = 0.0
        Power("Power", Range(0,50)) = 1.0
        Scale("Scale", Range(0,10)) = 1.0
        LightAttentuation("Attentuation", Range(0,10)) = 1.0
        cAmbient("Ambient", Color) = (0,0,0,1)
        _lightPosition("LightPosition", Vector) = (0,0,0,0) 
    }
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		// Physically based Standard lighting model that enables shadows on all light types
		#pragma surface surf Standard fullforwardshadows

		// Shader model 3.0 target is used to get nicer looking lighting
		#pragma target 3.0

        //We only need these 3 samplers NOT _ThicknessTex
		sampler2D _MainTex;
        sampler2D _SubsurfaceTex;
        sampler2D _OcclusionTex;

        float Distortion;
        float Scale;
        float Power;
        fixed4 cAmbient;
        float LightAttentuation;
        float4 _lightPosition;

        //Only need these 3 float types as input - NOT uv_SubsurefaceTex
		struct Input {
			float2 uv_MainTex;
		    float3 viewDir;
            float3 worldPos;
        };

		half _Glossiness;
		half _Metallic;
		fixed4 _Color;

        //We can omit the vertex shader completely, since we are using a surface shader that essentially combines elements from both a vertex and fragment shader

        void surf (Input IN, inout SurfaceOutputStandard o) {

            // Calculate subsurface scattering color - changed to uv_MainTex instead since that's what will be outputted
            fixed4 subsurface = tex2D(_SubsurfaceTex, IN.uv_MainTex);

            // Combine albedo and subsurface colors to a new color
            fixed4 combined = tex2D(_MainTex, IN.uv_MainTex) * _Color;
			
            //This new color will be the Albedo and the rest assigns colors/texturing to what their name indicates.
            o.Albedo = combined.rgb + subsurface;
            o.Occlusion = tex2D(_OcclusionTex, IN.uv_MainTex);
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = combined.a;

            //This is added for better SSS. r gets the red color channel in RGB which looks more realistic.
            float Thickness = subsurface.r;

            // Light emission - it starts by getting normalized vectors for the light direction and camera view direction.
            float3 lightDir = normalize(_lightPosition.xyz - IN.worldPos);
            float3 Cam =  normalize(_WorldSpaceCameraPos - IN.worldPos);

            //We then calculate light on the surface normals multiplied with Distortion
            half3 affectedLight = lightDir + o.Normal.xyz * Distortion;

            //Dot product returns a scalar between the camera vector and affectedLight, so it's only a regular half. 
            //The Power and Scale variables from before determine this dot product, saturate clamps the value to be between 0 and 1.
            //pow() raises the first input parameter to the power of the second input parameter.
            half Dot = pow(saturate(dot(Cam, -affectedLight)), Power) * Scale;

            //The Light Diffuse is then calculated here, to output its scattering. This is done by multipling the LighAtteniation with the
            //(Dot product scalar added with colors from the Ambient property) and then multiplied with the Thickness variable from before. 
            half3 LightDiffuse = LightAttentuation * (Dot + cAmbient.rgb) * Thickness;
            
            //This is then finally added to to the overall surface albedo and outputted as its emission.
            o.Emission = o.Albedo * LightDiffuse;
        }
		ENDCG
	} 
	FallBack "Diffuse"
}