Shader "Sigmal00/MeshAmbientOculusion"
{
    Properties
    {
		_Color("Color" , Color) = (1.0, 1.0, 1.0, 1.0)
        _Intensity ("Intensity", Range(0,1)) = 1
        _Exp ("Exponent", Range(0.001,10)) = 1
        _Radius ("Radius", Range(0,0.1)) = 0.01
        _MaskTex ("MaskTexture", 2D) = "white" {}
    }
    SubShader
    {
        Tags 
        {
            "RenderType"="Transparent"
            "Queue"="Transparent+1"
        }
        LOD 100
        ZWrite Off
        Blend DstColor Zero

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 objPos : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                float3 worldNormal : TEXCOORD3;
                float4 projPos : TEXCOORD4;
                float ao : TEXCOORD5;
                float4 vertex : SV_POSITION;
            };

            UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);
            sampler2D _MaskTex;
            float4 _MaskTex_ST;
            float _Intensity, _Radius, _Exp;
            float4 _Color;

            inline float random(float2 p)
            {
                return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453123);
            }

            float calcAO(v2f IN, int sampleCount)
            {
                float mask = tex2Dlod(_MaskTex, float4(IN.uv, 0, 0)).r;
                if(mask <= 0.0) return 0.0f;
                //clip(0.5-step(_Intensity*mask, 0.f));

                float depth = tex2Dlod(_CameraDepthTexture, float4(IN.projPos.xy / IN.projPos.w, 0,0)).r;
                float linearDepth = Linear01Depth(depth);

                float ao = 0.0f;
                float div = 0.0f;

                float3 pos = float3(0,0,0);
                for(int j = 0; j < sampleCount; ++j)
                {
                    float3 omega = float3(2*random(IN.objPos.xy * j)-1, 2*random(IN.objPos.yz * j)-1, 2*random(IN.objPos.zx * j)-1);
                    float dt = dot(omega, IN.worldNormal);
                    const float sgn = sign(dt);
                    omega *= sgn;

                    const float radius = _Radius;
                    float3 samplePos = (IN.worldPos + radius*omega);
                    dt *= sgn;

                    float4 sampleProjPos = UnityWorldToClipPos(samplePos);
                    sampleProjPos = ComputeScreenPos(sampleProjPos);

                    //float sampleDepth = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(sampleProjPos));
                    float sampleDepth = tex2Dlod(_CameraDepthTexture, float4(sampleProjPos.xy / sampleProjPos.w, 0,0)).r;
                    float2 uv = (sampleProjPos.xy / max(sampleProjPos.w, 0.00001f));

                    float ignore = (0.0f <= uv.x && uv.x <= 1.0f) || (0.0f <= uv.y && uv.y <= 1.0f) ? 1.0f : 0.0f;

                    div += dt*ignore;

                    ao += (depth == sampleDepth) ? 0.0f : step(depth, sampleDepth)*dt*ignore;
                }

                ao = (div != 0.0f) ? ao / div : 0.0f;
                ao = 1.0f - _Intensity*mask*pow(ao, _Exp);
                return ao;
            }

            float calcAOFrag(v2f IN, int sampleCount)
            {
                float mask = tex2D(_MaskTex, IN.uv).r;
                clip(0.5-step(_Intensity*mask, 0.f));

                float depth = tex2D(_CameraDepthTexture, IN.projPos.xy / IN.projPos.w).r;
                float linearDepth = Linear01Depth(depth);

                float ao = 0.0f;
                float div = 0.0f;

                float3 pos = float3(0,0,0);
                for(int j = 0; j < sampleCount; ++j)
                {
                    float3 omega = float3(2*random(IN.objPos.xy * j)-1, 2*random(IN.objPos.yz * j)-1, 2*random(IN.objPos.zx * j)-1);
                    float dt = dot(omega, IN.worldNormal);
                    const float sgn = sign(dt);
                    omega *= sgn;

                    const float radius = _Radius;
                    float3 samplePos = (IN.worldPos + radius*omega);
                    dt *= sgn;

                    float4 sampleProjPos = UnityWorldToClipPos(samplePos);
                    sampleProjPos = ComputeScreenPos(sampleProjPos);

                    //float sampleDepth = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(sampleProjPos));
                    float sampleDepth = tex2D(_CameraDepthTexture, sampleProjPos.xy / sampleProjPos.w).r;
                    float2 uv = (sampleProjPos.xy / max(sampleProjPos.w, 0.00001f));

                    float ignore = (0.0f <= uv.x && uv.x <= 1.0f) || (0.0f <= uv.y && uv.y <= 1.0f) ? 1.0f : 0.0f;

                    div += dt*ignore;

                    ao += (depth == sampleDepth) ? 0.0f : step(depth, sampleDepth)*dt*ignore;
                }

                ao = (div != 0.0f) ? ao / div : 0.0f;
                ao = 1.0f - _Intensity*mask*pow(ao, _Exp);
                return ao;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MaskTex);
                o.objPos = v.vertex.xyz;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.projPos = ComputeScreenPos(o.vertex);

                o.ao = 1.0f;//calcAO(o, 128);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float ao = calcAOFrag(i, 64);
                //ao = min(ao, i.ao);
                
                return lerp(_Color, 1.0f, smoothstep(0.0, 0.5, ao));
            }
            ENDCG
        }
    }
}
