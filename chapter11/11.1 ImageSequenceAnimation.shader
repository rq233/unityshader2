Shader "Unlit/11.1 ImageSequenceAnimation"
{
    Properties{
        _Color("Color Tint",Color) = (1,1,1,1)
        _MainTex("Main Tex",2D) = "white"{}
        _HorizontalAmount("Horizontal Amount",float) = 4
        //序列图像水平个数
        _VerticalAmount("Vertical Amount",float) = 4
        //序列图像垂直个数
        _Speed("Speed",Range(0,200)) = 20
    }

    SubShader{
        //准备渲染设置
        //序列帧图像通常是透明纹理，我们需要设置 Pass 的相关状态，以渲染透明效果：
        Tags{ "RenderType" = "Transparent" "Queue" = "Transparent" "IgnoreProjector" = "True" }
        pass{
            Tags{ "LightMode" = "ForwardBase" }
            
            //透明渲染要关闭深度测试，再进行混合
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert 
            #pragma fragment frag
            #include "UnityCG.cginc"

            float4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _HorizontalAmount;
            float _VerticalAmount;
            fixed _Speed;

            struct a2v{
                float4 vertex :POSITION;
                float4 texcoord :TEXCOORD0;
            };
            struct v2f{
                float4 pos :SV_POSITION;
                float2 uv :TEXCOORD0;
            };

            ////顶点着色器
            v2f vert (a2v v){
                v2f o;
                o.pos = UnityObjectToClipPos( v.vertex );
                o.uv = TRANSFORM_TEX( v.texcoord , _MainTex );
                return o;
            }
            //片元着色器 目的：计算出每个时刻需要播放的关键帧在纹理中的位置
            fixed4 frag (v2f i):SV_TARGET{
                fixed distan = floor( _Time.y * _Speed );
                //floor(x) 对输入参数向下取整。例如floor(float(1.3))返回的值为1.0；但是floor(float(-1.3))返回的值为-2.0。该函数与ceil(x)函数相对应。
                //场景加载开始经过的时间*时间 得到扫过该图片的位置
                fixed row = floor(distan / _HorizontalAmount);
                //row:行 用该位置/每行的图片的个数
                fixed column = distan - row * _HorizontalAmount;
                //colunm:列
                half2 uv = float2( i.uv.x/_HorizontalAmount , i.uv.y/_VerticalAmount );
                //序列帧图像包含了许多关键帧图像， 这意味着采样坐标需要映射到每个关键帧图像的坐标范围内。 
                //我们可以首先把原纹理坐标 i.uv按行数和列数进行等分，得到每个子图像的纹理坐标范围 。
                //使用当前的行列数对上面的结果进行偏移，得到当前子伤像的纹理坐标。
                //对竖直方向的坐标偏移需要使用减法，
                //这是因为在Unity中纹理坐标竖直方向的顺序（从下到上逐渐增大）和序列帧纹理中的顺序（播放顺序是从上到下）是相反的 。
                uv.x += column / _HorizontalAmount;
                uv.y -= row / _VerticalAmount;
                fixed4 c = tex2D(_MainTex,uv);
                c.rgb *= _Color;
                return c;
            }ENDCG
        }
    }Fallback "Transparent/vertexLit"
}