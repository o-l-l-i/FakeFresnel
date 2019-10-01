Shader "Custom/FakeFresnel"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _FallOff ("FallOff", range(0, 10)) = 2.0
        _Fade ("Fade", Range(0,1)) = 1.0
    }

    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 100

        ZWrite Off

        // Additive blending:
        Blend One One

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // Make fog work:
            #pragma multi_compile_fog

            // This is needed for fog coords etc.
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;

                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;

                float3 normal : NORMAL;
                float4 worldPos : TEXCOORD2;
                float3 viewDir : TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;

            float _Fade;
            float _FallOff;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);

                // Calculate view direction from object's world pos:
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.viewDir = normalize(UnityWorldSpaceViewDir(o.worldPos));

                // Get vertex normal in world space:
                o.normal = UnityObjectToWorldNormal(v.normal);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // Sample _MainTex texture:
                fixed4 col = tex2D(_MainTex, i.uv) + _Color;

                // Calculate the fake fresnel using dot product of view direction and surface normal:
                float rimLighting = 1.0 - saturate( dot(normalize(i.viewDir), i.normal) );

                // FallOff adjustment with pow:
                rimLighting = pow(rimLighting, _FallOff);

                // Fade the effect:
                col.rgb = lerp(0, col.rgb * rimLighting, _Fade);

                // Apply fog:
                UNITY_APPLY_FOG(i.fogCoord, col);

                return col;
            }
            ENDCG
        }
    }
}
