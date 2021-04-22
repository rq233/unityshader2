Shader "Unlit/9.4.4 shadow&atten"
{
    Properties{
        _Color("Color Tint",Color) = (1,1,1,1)
        _Specular("Specular",Color) = (1,1,1,1)
        _Gloss("Gloss",Range(8.0,255)) = 20
    }

    SubShader{
        Tags{"RenderType" = "Opaque"}

        pass{
            Tags{"LightMode" = "ForwardBase"}

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            fixed4 _Color;
            fixed4 _Specular;
            float _Gloss;

            struct a2v{
                float4 vertex :POSITION;
                float3 normal :NORMAL;
            };

            struct v2f{
                float4 pos :SV_POSITION;
                float3 worldNormal :TEXCOORD0;
                float3 worldPos :TEXCOORD1;
                SHADOW_COORDS(2)
            };

            v2f vert (a2v v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                TRANSFER_SHADOW(o)
                return o;
            }
            
            fixed4 frag (v2f i) :SV_TARGET{
                fixed3 worldNormal = normalize(i.worldNormal);
                
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                
                fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0,dot(worldNormal,worldLightDir));

                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz-i.worldPos.xyz);
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow( max( 0 , dot(worldNormal,halfDir) ),_Gloss);

                UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);
                //UNITY _LIGHT _ATTENUATION Unity 内置的用于计算光照衰减和阴影，
                //返回三个参数 （atten，i，b）atten在内置函数中有定义，所以不用再定义
                //i:第二个参数是结构体 v2f  i.worldPos第三参数是世界空间的坐标 这个参数会用于计算光源空间下的坐标，对光照衰减纹理采样来得到光照衰减

                return fixed4 ( ambient + (diffuse + specular) * atten ,1.0);
            }
            ENDCG
        }

        pass{
            
            Tags{"LightMode" = "ForwardAdd"}

            Blend One One

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag 
            
            #pragma multi_compile_fwdadd

            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            fixed4 _Color;
            fixed3 _Specular;
            float _Gloss;

            struct a2v{
                float4 vertex :POSITION;
                float3 normal :NORMAL;
            };
            
            struct v2f{
                float4 pos :SV_POSITION;
                float3 worldNormal :TEXCOORD0;
                float3 worldPos :TEXCOORD1;
            };

            v2f vert (a2v v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                return o;
            };

            fixed4 frag (v2f i) :SV_TARGET{
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0,dot(worldNormal,worldLightDir));

                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz-i.worldPos.xyz);
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow( max( 0 , dot(worldNormal,halfDir) ),_Gloss);

                UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);

                return fixed4 ((diffuse + specular) * atten ,1.0);
            }
            ENDCG
        }
    }
    Fallback "Specular"
}