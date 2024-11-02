Shader "Human skin"
{

Properties
	{
		_Color("Color", Color) = (0.5, 0.65, 1, 1)

        [HDR]
        _AmbientColor("Ambient Color", Color) = (0.4,0.4,0.4,1) //basically ambient reflection, since its just a color

        [HDR]
        _SpecularColor("Specular Color", Color) = (0.9,0.9,0.9,1)
        _Glossiness("Glossiness", Float) = 32

        [HDR]
        _RimColor("Rim Color", Color) = (1,1,1,1)
        _RimAmount("Rim Amount", Range(0, 1)) = 0.716

        _RimThreshold("Rim Threshold", Range(0,1)) = 0.1

        _TranslucencySpread ("Translucency Spread", Float) = 32
        _ScatterColor ("Scatter Color", Color) = (1,1,1,1)

        _BumpMap ("Normal Map", 2D) = "bump" {}
        
	}

    CGINCLUDE
    #include "UnityCG.cginc"
    #include "Lighting.cginc"

            uniform sampler2D _BumpMap;   //you need a sampler when working with textures
            uniform float4 _BumpMap_ST;    //uniform float that is used in collaboration with the sampler
            //tiling and offset parameter = tiling = xy, offset = zw


			struct appdata
			{
				float4 vertex : POSITION;				
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD1;
                float4 tangent : TANGENT;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
                float4 posWorld : TEXCOORD0;
                float3 tangentWorld : TEXCOORD3;  
                float3 normalWorld : NORMAL;
                float4 tex : TEXCOORD1;
                float3 binormalWorld : TEXCOORD4;
			};

			v2f vert (appdata v)
			{
				v2f o; //output

                float4x4 modelMatrix = unity_ObjectToWorld; //model matrix
                float4x4 modelMatrixInverse = unity_WorldToObject; //inverse model matrix

                o.tangentWorld = normalize(
                mul(modelMatrix, float4(v.tangent.xyz, 0.0)).xyz); //we transform the tangent to world space by multiplying tangent vector with the modelMatrix

                o.normalWorld = normalize(
                mul(float4(v.normal, 0.0), modelMatrixInverse).xyz); //we transform the normal to world space by multiplying normal vector with the transpoe of the inverse modelMatrix. 
                //We do this because the lights direction is provided in world space.
                
                //z = normal, x = tangent, y = binormal
                o.binormalWorld = normalize(
                cross(o.normalWorld, o.tangentWorld) //the binormal vector is the cross product between normal and tangent in world space
                * v.tangent.w); // tangent.w is specific to Unity

               
                o.pos = UnityObjectToClipPos(v.vertex); //the position of vertices in clip space
                o.posWorld = mul(modelMatrix, v.vertex); //the position of vertices in world space
                o.tex = v.texcoord; //vertex input texture coordinate channel is passed to vertex output - so that we now output what the fragment shader needs to use
				return o; //return output
			}
			
			float4 _Color;
            float4 _AmbientColor;
            float _Glossiness;
            float4 _SpecularColor;
            float4 _RimColor;
            float _RimAmount;
            float _RimThreshold;
            float4 _ScatterColor;
            float _TranslucencySpread;


			float4 frag (v2f i) : COLOR

			{

                //Normal mapping
                float4 encodedNormal = tex2D(_BumpMap, 
                _BumpMap_ST.xy * i.tex.xy + _BumpMap_ST.zw); //this is where it changes the surface normal vectors according to virtual "bumps". It encodes them into the texture image by performing lookup in a sampler at a given set of coordinates. 
                //i.xy is what changes across the surface and creates the difference in normal maps, but it needs to be float4 to have access to the g and a (or y and w) components. 
                float3 localCoords = float3(2.0 * encodedNormal.a - 1.0, 
                2.0 * encodedNormal.g - 1.0, 0.0); //we find x and y from the surface normal vector at a given point with this mapping method "formula"
                localCoords.z = sqrt(1.0 - dot(localCoords, localCoords)); //we can calculate z based on algebra of the formula for normalization

                float3x3 local2WorldTranspose = float3x3(
                i.tangentWorld, 
                i.binormalWorld, 
                i.normalWorld); //to transform the normals from the local point coordinate systems into world space, we first need to make a transpose of this matrix - because unity writes matrixes row by row
                float3 normalDirection = 
                normalize(mul(localCoords, local2WorldTranspose)); //This is the most important, because it replaces the regular normal vector - multiplies local coordinate vector with transpose of transposed coordinates matrix (so we switch their positions)
                //we now have normals that account for bump maps

                //General light
                //Light and diffuse reflection
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz); //light vector
                float NdotL = dot(lightDir, normalDirection); //dot product for normal and light vector - to make diffuse reflection. Makes sure that there's only light where the surface is lit.
                float lightIntensity = smoothstep(0, 0.9, NdotL); //diffuse with added interpolation - if NdotL is below 0 it returns 0 and if its above 0.9, it returns 1. Between the two values it blends smoothly.
                float4 light = lightIntensity * _LightColor0; //full diffuse reflection affected by light color

                //View direction vector
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.posWorld.xyz); //takes the vector between camera position and a given uv coordinate position in world space.

                //Specular reflection and rim
                float3 halfVector = normalize(lightDir + viewDir); //half vector that is used by Blinn-Phong
                float NdotH = dot(normalDirection, halfVector); //dot product for half vector and normal - defines strength of the specular reflection
                float specularIntensity = pow(NdotH * lightIntensity, _Glossiness * _Glossiness); //specular intensity. NdotH * lightintensity ensures the reflection only gets drawn where the urface is lit.
                float specularIntensitySmooth = smoothstep(0.1, 0.9, specularIntensity); //specular intensity with added interpolation. If the specular intensity is below 0.1 it returns 0, if its above 0.9, it returns 1. In between that range, it blends smoothly.
                float4 specular = specularIntensitySmooth * _SpecularColor; //final specular reflection
                float4 rimDot = 1 - dot(viewDir, normalDirection); //inverse of dot product for the view vector and normal - to make rim lighting, because it's surfaces that are facing away from the camera.
                float rimIntensity = rimDot * pow(NdotL, _RimThreshold); //intensity for rim light - makes sure that it only gets drawn on illuminated side of object. Changes based on value of _Rimthreshold. pow controls how far the rim extends along the lit surface.
                rimIntensity = smoothstep(_RimAmount - 0.5, _RimAmount + 0.5, rimIntensity);  //rim light intensity with added interpolation - same princple as before, it returns 0 or 1 if rimIntensity is below or above the threshold. And it blends smoothly between the two boundary values.
                float4 rim = rimIntensity * _RimColor; //final rim reflection affected by the rim color that is selected in the inspector
                float4 colors = _Color; //just a variable for regular color

                
                //Translucency
                
                    float3 diffuseTranslucency = 
                    _LightColor0.rgb 
                    * _ScatterColor.rgb 
                    * max(0.0, dot(lightDir, -normalDirection)); //diffuse translucency - multiplies light color with inspector color and max of dot product between lightDir and - negative normal dir
                    float diffuseTranslucencySmooth = smoothstep(0, 0.9, diffuseTranslucency); //uses smoothstep to interpolate just like before
                    float4 diffuseTranslucencyFinal = diffuseTranslucencySmooth * _ScatterColor;

                    float3 forwardTranslucency;
                    if (dot(normalDirection, lightDir) > 0.0) 
                    // light source on the wrong side?
                    {
                    forwardTranslucency = float3(0.0, 0.0, 0.0); 
                    // no forward-scattered translucency
                     }
                    else // light source on the right side
                    {
                    forwardTranslucency = _LightColor0.rgb
                    * (_Color.rgb) * pow(max(0.0, 
                    dot(-lightDir, viewDir)), _TranslucencySpread); //forward-scattered translucency - lightcolor multiplied with inspectorcolor (specular chosen for similar color)
                    //the last part is max of dot between -light dir and view to make it view dependant. Raised to the power of _TranslucencySpread to give the variable a larger impact.
                    }
                    float forwardTranslucencySmooth = smoothstep(0, 0.9, forwardTranslucency); //uses smoothstep to interpolate just like before
                    float4 forwardTranslucencyFinal = forwardTranslucencySmooth * _ScatterColor;

                //Combining
                float4 blinnPhong = colors * (_AmbientColor + light + specular + rim); //combines the elements that make blinn-phong
                float4 combined = blinnPhong + diffuseTranslucencyFinal + forwardTranslucencyFinal; //multiplies blinn-phong with both types of translucency
				return combined; //makes the final output from the fragment shader
			}
			ENDCG

	SubShader
	{
    
    Tags{ "LightMode" = "ForwardBase"       // Used in Forward rendering; applies ambient, main directional light, vertex/SH lights and lightmaps.
	        "PassFlags" = "OnlyDirectional" //Only allow directional light 
        }

		Pass
		{

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

            ENDCG
        }
    }
}
			
			

//float2 random2(float2 p) { //this function and the cellular noise part is burrowed from the voronoi shader code from the postprocessing and VFX lecture. Is used to make the "shapes" on surface.
     //return frac(sin(float(dot(p,float2(269.5, 183.3))))); //returns the decimal value that is obtained by sinus of the dot product between a given .xy coordinate and the float2 numbers
 //}

//Ambient reflection
//float3 ambientLighting = 
//UNITY_LIGHTMODEL_AMBIENT.rgb * _Color.rgb;


//Diffuse reflection
//float3 attenuation = 1.0; // no attenuation
//float3 diffuseReflection = 
//light * _Color.rgb
//* max(0.0, dot(normalDirection, lightDir));

//Specular reflection
//float3 specularReflection;
//if (dot(normalDirection, lightDir) < 0.0) 
// light source on the wrong side?
//{
//specularReflection = float3(0.0, 0.0, 0.0); 
// no specular reflection
 //}
//else // light source on the right side
//{
//specularReflection = light
//* _SpecColor.rgb * pow(max(0.0, dot(
//reflect(-lightDir, normalDirection), 
//viewDir)), _Glossiness);
// }
 //float3 normal = normalize(i.normalWorld); //normal vector

                //Cellular noise
                //float2 st = i.tex.xy; //variable for coordinates
                //st.x = st.x*100; //controls how many "shapes" that get drawn on the surface of the object
                //st.y = st.y*100;

                    // tiles the space - makes sure no points overlap
               // float2 i_st = floor(st); //rounds down to nearest whole number
                //float2 f_st = frac(st); //decimal

                //float m_dist = 1; //minimum distance
                //float2 pointt = float2(0.0,0.0); //point of interest start value

                //for(int y =-1; y<=1; y++) { //these for loops check a point and all it´s eight negighbours.
                    //for(int x =-1; x<=1; x++) {
                        //float2 neighbor = float2(float(x), float(y)); //neighbor to the point of interest
                        //pointt = random2(i_st + neighbor); //point of interest which is found by using the random2() function to find fraction of the point i_st+neighbor
                        //float2 diff = float2(neighbor + pointt - f_st); //approximate difference between these two points which we find by subtracting the decimal number
                        //float dist = length(diff); //distance of this difference
                        //m_dist = min(m_dist, dist*0.05); //returns the smallest number to rewrite minimum distance - which is either its previous value or distance multiplied by the chosen number (which controls interpolation)
                   // }
                //}

                //float4 colors = _Color; //gets the value of _Color in the inspector
                //colors = colors + m_dist; //adds the new value of m_dist to this - it makes the interpolation colors between the "shapes"*/

                //float4 blinnPhong = colors * float4(ambientLighting + diffuseReflection + specularReflection + _AmbientColor,0); //combines the elements that make blinn-phong


                //Cellular noise
                //float2 st = i.tex.xy; //variable for coordinates
                //st.x = st.x*100; //controls how many "shapes" that get drawn on the surface of the object
               // st.y = st.y*100;

                    // tiles the space - makes sure no points overlap
                //float2 i_st = floor(st); //rounds down to nearest whole number
                //float2 f_st = frac(st); //decimal

                //float m_dist = 1; //minimum distance
                //float2 pointt = float2(0.0,0.0); //point of interest start value

                //for(int y =-1; y<=1; y++) { //these for loops check a point and all it´s eight negighbours.
                    //for(int x =-1; x<=1; x++) {
                        //float2 neighbor = float2(float(x), float(y)); //neighbor to the point of interest
                        //pointt = random2(i_st + neighbor); //point of interest which is found by using the random2() function to find fraction of the point i_st+neighbor
                        //float2 diff = float2(neighbor + pointt - f_st); //approximate difference between these two points which we find by subtracting the decimal number
                        //float dist = length(diff); //distance of this difference
                        //m_dist = min(m_dist, dist*0.05); //returns the smallest number to rewrite minimum distance - which is either its previous value or distance multiplied by the chosen number (which controls interpolation)
                    //}
                //}

                //float4 colors = _Color; //gets the value of _Color in the inspector
                //colors = colors + m_dist; //adds the new value of m_dist to this - it makes the interpolation colors between the "shapes"*/

                //float _Distortion = 1;
                //float _Power = 1;
                //float refractiveIndex = 1.5; //IOR that was found to be approximate for human skin
                //float air = 1.0;
                //float3 transLightDir = lightDir + normalDirection; //* _Distortion; //vector for translucent light direction - is scaled by the value of _Distortion in the inspector
                //float transDot = ( max (0, dot (lightDir, transLightDir ))) / _Thickness; //dot product for the light vector and translucent light vector (so they go in instead of out). Affected by value of _Power and _Thickness in inspector
                //float3 transLight = (air/refractiveIndex) * ( transDot ) * colors * _ScatterColor; //translucent light that is emitted from the surface - is affected by the colors from the cellular noise and the other values listed.
                //float3 transFinal = light * transLight; //final translucent emission



                //float _Distortion = 1;
                //float _Power = 1;
                //float refractiveIndex = 1.5; //IOR that was found to be approximate for human skin
                //float air = 1.0;
                //float3 transLightDir = lightDir + normalDirection; //* _Distortion; //vector for translucent light direction - is scaled by the value of _Distortion in the inspector
                //float transDot = ( max (0, dot (lightDir, transLightDir ))) / _Thickness; //dot product for the light vector and translucent light vector (so they go in instead of out). Affected by value of _Power and _Thickness in inspector
                //float3 transLight = (air/refractiveIndex) * ( transDot ) * colors * _ScatterColor; //translucent light that is emitted from the surface - is affected by the colors from the cellular noise and the other values listed.
                //float3 transFinal = light * transLight; //final translucent emission