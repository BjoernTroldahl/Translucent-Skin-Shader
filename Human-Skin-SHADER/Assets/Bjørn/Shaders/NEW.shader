Shader "Custom/BSSRDF Translucency"
{
    Properties
    {
        // The color of the surface
        _Color ("Color", Color) = (1,1,1,1)

        // The scale factor for the sub surface scattering
        _ScatterScale ("Scatter Scale", Range(0, 1)) = 0.5

        // The distance over which the scattering occurs
        _ScatterDistance ("Scatter Distance", Range(0, 1)) = 0.1

        // The roughness of the surface
        _Roughness ("Roughness", Range(0, 1)) = 0.5
    }
    SubShader
    {
        // Set the render queue to transparent
        Queue 100

        // Set the blending mode to blend
        Blend SrcAlpha OneMinusSrcAlpha

        // Declare the material pass
        Pass
        {
            CGPROGRAM

            // Include the surface function
            #include "UnityCG.cginc"

            // Declare the surface inputs
            struct SurfaceInputs
            {
                float3 worldNormal;
                float3 viewDir;
                float3 worldPos;
                float2 uv_MainTex;
            };

            // Declare the surface function
            void SurfaceFunction(SurfaceInputs IN, inout SurfaceOutput o)
            {
                // Calculate the diffuse lighting
                float3 diffuseLight = _Color * saturate(dot(IN.worldNormal, _WorldSpaceLightPos0.xyz));

                // Calculate the specular lighting
                float3 halfDir = normalize(_WorldSpaceLightPos0.xyz + IN.viewDir);
                float specular = pow(saturate(dot(IN.worldNormal, halfDir)), _Shininess);
                float3 specularLight = _SpecColor * specular;

                // Calculate the BSSRDF scattering
                float3 scatter = _ScatterScale * diffuseLight * CalculateBSSRDF(IN.worldPos, IN.worldNormal, _ScatterDistance, _Roughness);

                // Output the final color
                o.Albedo = diffuseLight + scatter;
                o.Specular = specularLight;
                o.Alpha = 1.0;
            }

            ENDCG
        }
    }
}
