Shader "Unlit/8.7 S T"
{
    Properties{
        _Color("Main Tint",Color) = (1,1,1,1)
        _MainTex("Main Tex",2D) = "white"{}
        _Cutoff("Alpha Cutoff",Range(0,1)) = 0.5
    }

    SubShader{
        Tags{"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout" }
            
        pass{
            Tags{"LightMode" = "ForwardBase"}
            //与alpha test相比 只多了这个
            Cull Off
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _Cutoff;

            struct a2v{
                float4 vertex :POSITION;
                float3 normal :NORMAL;
                float4 texcoord :TEXCOORD0;
            };

            struct v2f{
                float4 pos :SV_POSITION;
                float3 worldNormal :TEXCOORD0;
                float3 worldPos :TEXCOORD1;
                float2 uv :TEXCOORD2;
            };

            v2f vert(a2v v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);
                return o;
            }

            //片元着色器需要计算的diffuse、ambient、specular 这里只需要计算diffuse
            //计算diffuse公式 光自己*自己材质*max（0，saturated（法线，光线）
            fixed4 frag (v2f i) :SV_TARGET{
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed4 texColor = tex2D(_MainTex,i.uv);
                
                //深度测试
                clip(texColor.a - _Cutoff);
                /* if( (texColor.a - _Cutoff ) < 0.0 ){
                    discard;
                } *///或者用这个也可以
                
                fixed3 albedo = texColor.rgb * _Color.rgb;
                fixed3 diffuse = _LightColor0.rgb * albedo * max( 0 , dot(worldNormal,worldLightDir));
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz *albedo;

                return fixed4 (diffuse + ambient,1.0);
            }
            ENDCG
        }
    }Fallback "Transparent/Cuout/VertexLit"
}
