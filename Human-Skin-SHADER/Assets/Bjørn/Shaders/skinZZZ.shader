// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "voronoi" {
	Properties{}
		SubShader{
			Pass{
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag



			float2 random2( float2 p ) {
    			return frac(sin(float2(dot(p,float2(127.1,311.7)),dot(p,float2(269.5,183.3))))*43758.5453);
			}

			struct appdata{
				float4 vertPositions:POSITION;
				float4 texcoords : TEXCOORD0;
				float3 normals:NORMAL;
			};

			struct v2f{
				float4 vertPositionsNew:SV_POSITION;
				float4 texcoords: TEXCOORD0;
				float3 normals:NORMAL;
			};



			// vertex shader
			v2f vert(appdata vIn){
				v2f vOut;
				vOut.vertPositionsNew = UnityObjectToClipPos(vIn.vertPositions);
				vOut.texcoords = vIn.texcoords;
				vOut.normals = vIn.normals;
				return vOut;
			}


			// fragment shader
			float4 frag(v2f fIn):COLOR{

				float2 st = fIn.texcoords.xy;
				st.x = st.x*100;
				st.y = st.y*100;

				// tile the space
				float2 i_st = floor(st);
				float2 f_st = frac(st);

				float m_dist = 5;
				float2 pointt = float2(0.0,0.0);

				for(int y =-1; y<=1; y++) {
					for(int x =-1; x<=1; x++) {
						float2 neighbor = float2(float(x), float(y));
						pointt = random2(i_st + neighbor);
						//pointt = 0.42 + 0.42*sin(_Time.y + 6.2831*pointt);
						float2 diff = float2(neighbor + pointt - f_st);
						float dist = length(diff);
						m_dist = min(m_dist, dist*0.3);
					}
				}
		
				float4 colors = float4(1.0,0.0,0.0,0.0);
				colors = colors + m_dist;
				//colors = colors + 1. - step(0.03, m_dist);
				//colors.r += step(0.98, f_st.x) + step(.98, f_st.y);
				//return float4(pow(colors.xy, 1.0),pointt.y,1.0);
				return float4(pow(colors.xy, 1.0),0.0,1.0);

			}
			ENDCG
			}
		}
}







//decompose behavior of effect
//this is your fail safe job skill 