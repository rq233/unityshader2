Shader "Unlit/8.7 S B"
{
    Properties{
        _Color("Color Tint",Color) = (1,1,1,1)
        _MainTex("Main Tex",2D) = "white"{}
        _AlphaScale("Alpha Scale",Range(0,1)) = 0.5
    }

    SubShader{
        
        Tags{"Queue"="Transparent" "RanderType"="Transparent" "IgnoreProjector"="True"}

        pass{
            Tags{"Lightmode" = "ForwardBase"}
            
            Cull Front //剔除正面

            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _AlphaScale;

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

            v2f vert (a2v v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                o.uv = TRANSFORM_TEX(v.texcoord , _MainTex);
                return o;
            } 

            //片元着色器需要干的事 计算diffuse ambient 在a通道写入透明度
            fixed4 frag (v2f i):SV_TARGET{
                float3 worldNormal = normalize(i.worldNormal);
                fixed3 WorldLightDir = normalize (UnityWorldSpaceLightDir(i.worldPos));
                fixed4 MainColor = tex2D(_MainTex,i.uv);
                fixed3 albedo = MainColor.rgb * _Color.rgb;
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0,dot(worldNormal,WorldLightDir));
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                return fixed4 (diffuse + ambient, MainColor.a * _AlphaScale);
            }
            ENDCG
        }

        pass{
            Tags{"Lightmode" = "ForwardBase"}
            
            Cull Back //剔除背面

            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _AlphaScale;

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

            v2f vert (a2v v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                o.uv = TRANSFORM_TEX(v.texcoord , _MainTex);
                return o;
            } 

            //片元着色器需要干的事 计算diffuse ambient 在a通道写入透明度
            fixed4 frag (v2f i):SV_TARGET{
                float3 worldNormal = normalize(i.worldNormal);
                fixed3 WorldLightDir = normalize (UnityWorldSpaceLightDir(i.worldPos));
                fixed4 MainColor = tex2D(_MainTex,i.uv);
                fixed3 albedo = MainColor.rgb * _Color.rgb;
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0,dot(worldNormal,WorldLightDir));
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                return fixed4 (diffuse + ambient, MainColor.a * _AlphaScale);
            }
            ENDCG
        }
    }Fallback "Transparent/VertexLit"
}
