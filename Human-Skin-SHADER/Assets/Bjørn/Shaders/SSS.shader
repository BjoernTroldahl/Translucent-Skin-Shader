Shader "Custom/SSS"
{
    Properties {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Thickness ("Thickness", Range(0.01, 1.0)) = 0.1
        _ScatterColor ("Scatter Color", Color) = (1,1,1,1)
    }

    SubShader {
        Tags {"RenderType"="Opaque"}

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f {
                float4 worldPos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldRefl : TEXCOORD1;
                float3 worldRefr : TEXCOORD2;
                float3 worldReflCtrl : TEXCOORD3;
                float3 worldNormal : NORMAL;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Thickness;
            float4 _ScatterColor;

            v2f vert (appdata v) {
                v2f o;
                o.worldPos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                //o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz
                //o.worldReflCtrl = o.worldRefl;
                return o;
            }

            float4 frag (v2f i) : SV_Target {
                float3 normal = normalize(i.worldNormal);
                float4 col = tex2D(_MainTex, i.uv);
                float3 worldRefl = normalize(i.worldRefl);
                float3 worldRefr = normalize(i.worldRefr);
                float3 lightDir = _WorldSpaceLightPos0.xyz;
                float lightFalloff = max(0, dot(lightDir, normal));

                float3 camPos = _WorldSpaceCameraPos;
                float3 fragToCam = camPos - i.worldPos;
                float3 viewDir = normalize(fragToCam);
                worldRefl = reflect(-viewDir, normal);
                worldRefr = refract(viewDir, normal, _Thickness);

                col.rgb *= max(0, dot(worldRefl, normalize(i.worldPos)));
                col.rgb += _ScatterColor.rgb * max(0.0, dot(worldRefr, normalize(i.worldPos)));
                float3 sss = col * lightFalloff;
                //return col;

                float4 subsurface = _ScatterColor * _Thickness * tex2D(_MainTex, i.uv).r;
                //float4 col = tex2D(_MainTex, i.uv);
                return float4(sss + subsurface.rgb, col.a);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
