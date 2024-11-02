// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader "click-me"
{
    Properties{
        _Color("Color", Color) = (1,1,1,1)
        _Gloss("Gloss", Float) = 1
    }
    SubShader
    {
        Tags{"Rendertype"="Opaque"}

        Pass{
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            //Mesh data: vertex position, vertex normal, UVs, tangents, vertex colors
            //Can also call this VertexInput
            //use float2 for UVs
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv0 : TEXCOORD0;
                float3 normal: NORMAL;


                //float4 colors : COLOR;
                //float4 tangent : TANGENT; 
                //float2 uv1 : TEXCOORD1;
            };

            float4 _Color;
            float _Gloss;

            //Can also call this VertexOutput
            //Clip-space position
            //TEXCOORDs are used here as interpolators
            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float3 normal : NORMAL;
                float3 worldPos : TEXCOORD1;
            };

            //Vertex shader
            v2f vert (appdata v)
            {
                v2f o;
                o.uv0 = v.uv0;
                o.normal = v.normal;
                //Clip space position
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            //x = red channel
            //y = green channel
            //z = blue channel
            float4 frag(v2f o) : SV_Target
            {
                //float3 clipPos = o.vertex.xyz;
                float2 uv = o.uv0;
                float3 normal = normalize(o.normal); //without normalize they would be very blocky and not smooth
                //Lighting
                float3 lightDir = _WorldSpaceLightPos0.xyz;
                float3 lightColor = _LightColor0.rgb;

                //Direct diffuse light
                float lightFalloff = max(0, dot(lightDir, normal));
                //lightFalloff = step(0.1,lightFalloff);
                float3 directDiffuseLight = lightColor * lightFalloff;

                //Ambient light
                float3 ambientLight = float3(0.1, 0.1, 0.1);

                //Direct specular light
                float3 camPos = _WorldSpaceCameraPos;
                float3 fragToCam = camPos - o.worldPos;
                float3 viewDir = normalize(fragToCam);

                float3 viewReflect = reflect(-viewDir, normal);
                float3 specularFalloff = max(0, dot(viewReflect, lightDir));
                specularFalloff = pow(specularFalloff, _Gloss); //modify gloss
                //specularFalloff = step(0.1,specularFalloff);
                float3 directSpecular = specularFalloff * lightColor;

                //return float4 (specularFalloff.xxx,0);

                //Phong
                //Blinn-phong

                //Composite 
                float3 diffuseLight = ambientLight + directDiffuseLight;
                float3 finalSurfaceColor = diffuseLight * _Color.rgb + directSpecular;

                return float4(finalSurfaceColor, 0);
            }
            ENDCG
        }
    }
}
