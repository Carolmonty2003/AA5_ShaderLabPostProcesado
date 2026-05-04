Shader "Custom/Terrain/Vertex Paint Surface"
{
    Properties
    {
        [Header(Texture Set A)]
        _A_Albedo ("A - Albedo", 2D) = "white" {}
        _A_Normal ("A - Normal", 2D) = "bump" {}
        _A_Mask ("A - Mask R Metallic G AO B Height A Smoothness", 2D) = "white" {}

        [Header(Texture Set B)]
        _B_Albedo ("B - Albedo", 2D) = "white" {}
        _B_Normal ("B - Normal", 2D) = "bump" {}
        _B_Mask ("B - Mask R Metallic G AO B Height A Smoothness", 2D) = "white" {}

        [Header(Snow)]
        _SnowColor ("Snow Color", Color) = (1,1,1,1)
        _SnowNormal ("Snow Normal", 2D) = "bump" {}
        _SnowMetallic ("Snow Metallic", Range(0,1)) = 0
        _SnowSmoothness ("Snow Smoothness", Range(0,1)) = 0.2
        _SnowAO ("Snow AO", Range(0,1)) = 1
        _SnowHeight ("Snow Height", Range(0,1)) = 1

        [Header(Noise Blend)]
        _NoiseMap ("Noise Map", 2D) = "white" {}
        _NoiseScale ("Noise Scale", Float) = 8
        _NoiseStrength ("Noise Strength", Range(0,1)) = 0.35
        _BlendDistance ("Blend Distance A/B", Range(0.001,1)) = 0.25
        _SnowBlendDistance ("Snow Blend Distance", Range(0.001,1)) = 0.3

        [Header(Tiling)]
        _MainTiling ("Main Texture Tiling", Float) = 1
        _SnowTiling ("Snow Tiling", Float) = 1

        [Header(Vertex Displacement)]
        _VerticalDisplacement ("Vertical Displacement", Float) = 1
        _HeightInfluence ("Height Influence", Range(0,1)) = 1

        [Header(Normal)]
        _NormalStrength ("Normal Strength", Range(0,2)) = 1
    }

    SubShader
    {
        Tags 
        { 
            "RenderType" = "Opaque"
        }

        LOD 300

        CGPROGRAM

        #pragma surface surf Standard fullforwardshadows vertex:vert addshadow
        #pragma target 3.0

        sampler2D _A_Albedo;
        sampler2D _A_Normal;
        sampler2D _A_Mask;

        sampler2D _B_Albedo;
        sampler2D _B_Normal;
        sampler2D _B_Mask;

        sampler2D _SnowNormal;
        sampler2D _NoiseMap;

        fixed4 _SnowColor;

        float _SnowMetallic;
        float _SnowSmoothness;
        float _SnowAO;
        float _SnowHeight;

        float _NoiseScale;
        float _NoiseStrength;
        float _BlendDistance;
        float _SnowBlendDistance;

        float _MainTiling;
        float _SnowTiling;

        float _VerticalDisplacement;
        float _HeightInfluence;

        float _NormalStrength;

        struct Input
        {
            float2 uv_A_Albedo;
            fixed4 color : COLOR;
        };

        float BlendWithNoise(float vertexValue, float noiseValue, float blendDistance, float noiseStrength)
        {
            float noisyValue = vertexValue + ((noiseValue - 0.5) * noiseStrength);
            return smoothstep(0.5 - blendDistance, 0.5 + blendDistance, noisyValue);
        }

        float3 BlendNormals(float3 normalA, float3 normalB, float blendValue)
        {
            return normalize(lerp(normalA, normalB, blendValue));
        }

        void vert(inout appdata_full v)
        {
            float2 uvMain = v.texcoord.xy * _MainTiling;
            float2 uvNoise = v.texcoord.xy * _NoiseScale;

            float noise = tex2Dlod(_NoiseMap, float4(uvNoise, 0, 0)).r;

            float blendAB = BlendWithNoise(v.color.r, noise, _BlendDistance, _NoiseStrength);
            float blendSnow = BlendWithNoise(v.color.g, noise, _SnowBlendDistance, _NoiseStrength);

            float heightA = tex2Dlod(_A_Mask, float4(uvMain, 0, 0)).b;
            float heightB = tex2Dlod(_B_Mask, float4(uvMain, 0, 0)).b;

            float heightAB = lerp(heightA, heightB, blendAB);
            float finalHeight = lerp(heightAB, _SnowHeight, blendSnow);

            float displacementMask = v.color.b;

            float displacement = displacementMask * finalHeight * _VerticalDisplacement * _HeightInfluence;

            v.vertex.xyz += v.normal * displacement;
        }

        void surf(Input IN, inout SurfaceOutputStandard o)
        {
            float2 uvMain = IN.uv_A_Albedo * _MainTiling;
            float2 uvSnow = IN.uv_A_Albedo * _SnowTiling;
            float2 uvNoise = IN.uv_A_Albedo * _NoiseScale;

            float noise = tex2D(_NoiseMap, uvNoise).r;

            float blendAB = BlendWithNoise(IN.color.r, noise, _BlendDistance, _NoiseStrength);
            float blendSnow = BlendWithNoise(IN.color.g, noise, _SnowBlendDistance, _NoiseStrength);

            fixed4 albedoA = tex2D(_A_Albedo, uvMain);
            fixed4 albedoB = tex2D(_B_Albedo, uvMain);

            fixed4 maskA = tex2D(_A_Mask, uvMain);
            fixed4 maskB = tex2D(_B_Mask, uvMain);

            float3 normalA = UnpackNormal(tex2D(_A_Normal, uvMain));
            float3 normalB = UnpackNormal(tex2D(_B_Normal, uvMain));
            float3 normalSnow = UnpackNormal(tex2D(_SnowNormal, uvSnow));

            normalA.xy *= _NormalStrength;
            normalB.xy *= _NormalStrength;
            normalSnow.xy *= _NormalStrength;

            normalA = normalize(normalA);
            normalB = normalize(normalB);
            normalSnow = normalize(normalSnow);

            fixed4 albedoAB = lerp(albedoA, albedoB, blendAB);
            fixed4 maskAB = lerp(maskA, maskB, blendAB);
            float3 normalAB = BlendNormals(normalA, normalB, blendAB);

            fixed3 finalAlbedo = lerp(albedoAB.rgb, _SnowColor.rgb, blendSnow);
            float3 finalNormal = BlendNormals(normalAB, normalSnow, blendSnow);

            float metallicAB = maskAB.r;
            float aoAB = maskAB.g;
            float smoothnessAB = maskAB.a;

            float finalMetallic = lerp(metallicAB, _SnowMetallic, blendSnow);
            float finalAO = lerp(aoAB, _SnowAO, blendSnow);
            float finalSmoothness = lerp(smoothnessAB, _SnowSmoothness, blendSnow);

            o.Albedo = finalAlbedo;
            o.Normal = finalNormal;
            o.Metallic = finalMetallic;
            o.Smoothness = finalSmoothness;
            o.Occlusion = finalAO;
            o.Alpha = 1;
        }

        ENDCG
    }

    FallBack "Diffuse"
}