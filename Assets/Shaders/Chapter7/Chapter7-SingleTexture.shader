// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 7/Single Texture" {
	Properties {
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		_MainTex ("Main Tex", 2D) = "white" {}
		_Specular ("Specular", Color) = (1, 1, 1, 1)
		_Gloss ("Gloss", Range(8.0, 256)) = 20
	}
	SubShader {		
		Pass { 
			Tags { "LightMode"="ForwardBase" }
		
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag

			#include "Lighting.cginc"
			
			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _Specular;
			float _Gloss;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				float2 uv : TEXCOORD2;
			};
			
			v2f vert(a2v v) {
				v2f o;

				//将顶点坐标从模型空间转换到齐次裁剪空间
				o.pos = UnityObjectToClipPos(v.vertex);
				
				//将法线向量从模型空间转换到世界空间
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				
				//将顶点坐标从模型空间转换到世界空间
				//方便后续使用这个变量计算光源向量和视点向量
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				
				//使用贴图顶点信息、位移、缩放计算uv
				o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				// Or just call the built-in function
//				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				//归一化法线向量
				fixed3 worldNormal = normalize(i.worldNormal);

				//计算顶点到光源的方向向量
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

				//计算顶点到视点的方向向量
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				
				// Use the texture to sample the diffuse color
				//贴图采样
				//对采样结果乘以颜色属性作为材质的反射率
				//     反射率          对贴图采样              颜色属性
				//     ______   _________________________   __________
				fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
				
				//计算环境光
				//      环境光          环境光源                 反射率
				//     _______   ____________________________   ______
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				
				//计算漫反射
				//光源乘以反射率
				//法线方向与光源方向的点积大小控制反射的强度
				//      漫反射        光源颜色       反射率              反射强度
				//     _______   ________________   ______   ________________________________________
				fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));
				
				
				//计算高光反射
				//Blinn-Phong模型(布林材质模型)，使用光源方向+视点方向作为参考方向 h
				//使用 h 方向和法线方向的点乘 参与计算控制反射的强度
				//     反射方向               光源方向       视口方向
				//     _______			   _____________   _______
				fixed3 halfDir = normalize(worldLightDir + viewDir);
				//     高光反射         光源颜色        高光颜色属性                    反射强度
				//     ________   ________________   _____________   ______________________________________________
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);
				
				return fixed4(ambient + diffuse + specular, 1.0);
			}
			
			ENDCG
		}
	} 
	FallBack "Specular"
}
