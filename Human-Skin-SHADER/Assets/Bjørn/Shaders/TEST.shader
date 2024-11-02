Shader "TEST"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _SubsurfaceTex ("Subsurface (RGB)", 2D) = "white" {}
        _Thickness ("Thickness", Range(0,1)) = 0.5
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows

        struct Input
        {
            float2 uv_MainTex;
            float2 uv_SubsurfaceTex;
        };

        sampler2D _MainTex;
        sampler2D _SubsurfaceTex;

        fixed4 _Color;
        float _Thickness;
        float _Glossiness;
        float _Metallic;

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Calculate subsurface scattering
            fixed3 subsurface = tex2D(_SubsurfaceTex, IN.uv_SubsurfaceTex).rgb * _Thickness;

            // Combine albedo and subsurface colors
            fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb + subsurface;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}