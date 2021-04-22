// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'

Shader "Unlit/ForwardRenderingMat"
{
    Properties{
        _Color("Color Tint",Color) = (1,1,1,1)
        _Specular("Specular",Color) = (1,1,1,1)
        _Gloss("Gloss",Range(8.0,255)) = 20
    }

    SubShader{
        Tags{"RenderType" = "Opaque"}

        //定义第一个pass 储存g缓冲区信息，设置其渲染路径
        pass{
            Tags{"LightMode" = "ForwardBase"}

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            //保证我们在 Shader 中使用光照衰减等光照变量可以被正确赋值。

            #include "Lighting.cginc"

            fixed4 _Color;
            fixed4 _Specular;
            float _Gloss;

            //定义顶点着色器输入结构
            struct a2v{
                float4 vertex :POSITION;
                float3 normal :NORMAL;
            };
            //定义顶点着色器输出
            struct v2f{
                float4 pos :SV_POSITION;
                float3 worldNormal :TEXCOORD0;
                float3 worldPos :TEXCOORD1;
            };

            //定义顶点着色器
            v2f vert (a2v v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                return o;
            }
            //定义片元着色器
            //如果场景中包含了多个平行光， Unity 会选择最亮的平行光传递给 Base Pass 进行逐像素处理
            //其他平行光会按照逐顶点或在 Additional Pass 中按逐像素的方式处理。如果场景中没有任何平行光， 那么 Base Pass 会当成全黑的光源处理。
            fixed4 frag (v2f i) :SV_TARGET{
                fixed3 worldNormal = normalize(i.worldNormal);
                //得到平行光的方向，可以用_WorldSpaceLightPos0
                //平行光颜色直接用_ColorLight 这里的_LightColorO 已经是颜色和强度相乘后的结果
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                //环境光只计算这里的一次即可
                fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0,dot(worldNormal,worldLightDir));

                //这里的视角方向是=用相机的位置-到目标点的位置
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz-i.worldPos.xyz);
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow( max( 0 , dot(worldNormal,halfDir) ),_Gloss);

                //定义光照衰减，平行光没有光照属性，所以这里直接令衰减为1
                fixed atten = 1.0;

                return fixed4 ( ambient +(diffuse + specular) * atten ,1.0);
            }
            ENDCG
        }

        //为场景中其他逐像素光源定义 Additional pass 。
        pass{
            //设置渲染路径
            Tags{"LightMode" = "ForwardAdd"}

            //使用 Blend 命令开启和设置了混合模式。
            //如果没有使用 Blend 命令的话， AdditionalPass 会直接覆盖掉之前的光照结果
            Blend One One

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag 
            //保证我 Additional Pass 中访问到正确的光照变址
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
            //定义顶点着色器输出
            struct v2f{
                float4 pos :SV_POSITION;
                float3 worldNormal :TEXCOORD0;
                float3 worldPos :TEXCOORD1;
            };

            //定义顶点着色器
            v2f vert (a2v v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                return o;
            };
            //定义片元着色器
            //这里的光源是点光源，要注意光源的5个基本要素：位置，方向，强度，颜色，衰减
            //环境光已经计算过一次了，所以不需要在计算
            fixed4 frag (v2f i) :SV_TARGET{
                fixed3 worldNormal = normalize(i.worldNormal);
                
                //首先，这里的道光强还有颜色依然可以用_LightColor
                //光照方向需要判断得到
                #ifdef USING_DIRECTIONAL_LIGHT
                       fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                #else 
                       fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos.xyz);
                #endif

                fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0,dot(worldNormal,worldLightDir));

                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz-i.worldPos.xyz);
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow( max( 0 , dot(worldNormal,halfDir) ),_Gloss);

                //判断光照衰减
                #ifdef USIING_DIRECTIONAL_LIGHT
                       fixed atten = 1.0;
                #else
                    #if defined (PIONT)
                           float3 LightCoord = mul(unity_WorldToLight.float4(i.worldPos,1.0)).xyz;
                           fixed atten = tex2D(_LightTexture0, dot(LightCoord,LightCoord).rr).UNITY_ATTEN_CHANNEL;
                    #elif defined (SPOT)
				           float4 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1));
				           fixed atten = (lightCoord.z > 0) * tex2D(_LightTexture0, lightCoord.xy / lightCoord.w + 0.5).w * tex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
				    #else
				        fixed atten = 1.0;
				    #endif 
                #endif

                return fixed4 ((diffuse + specular) * atten ,1.0);
            }
            ENDCG
        }
    }
    Fallback "Specular"
    //回调specular，Fallback调用了 Vertex.Lit, 它会继续回调，并最终回调到内置的 VertexLit。内置的pass里有shadow的pass
   /*  pass{
        Name "ShadowCaster"
        Tags{"LightMode" = "ShadowCaster"}
        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        #pragma multi_compile_shadowcaster
        #include "UnityCG.cginc"

        struct v2f{
            V2F_SHADOW_CASTER;
        };
        
        v2f vert(a2v v){
            v2f o;
            TRANSFER_SHADOW_CASTER_NORMALOFFSET(o);
            return o;
        }

        float4 frag (v2f i):SV_TARGET{
            SHADOW_CASTER_FRAGMENT(i);
        }
        ENDCG
    } */
}
