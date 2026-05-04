Shader "Edgar/RocksTriplanar"
{
    Properties
    {
        
        _MainTex ("Albedo", 2D) = "white" {}

        
        _Normal ("Normal Map", 2D) = "bump" {}

        
        _TriplanarScale ("Triplanar Scale", Float) = 1.0

        
        _BlendSharpness ("Blend Sharpness", Range(1, 8)) = 4.0

        
        _Color ("Color Tint", Color) = (1,1,1,1)

        
        _Smoothness ("Smoothness", Range(0,1)) = 0.2
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM

        
        #pragma surface surf Standard fullforwardshadows

        
        #pragma multi_compile _ TRIPLANAR_LOCAL

        #pragma target 3.0

        
        sampler2D _MainTex;
        sampler2D _Normal;

        
        float _TriplanarScale;
        float _BlendSharpness;
        fixed4 _Color;
        half _Smoothness;
        half _Metallic;

        
        struct Input
        {
            float3 worldPos;     // posicion fragment en world space
            float3 worldNormal;  // normal en world space
            float3 localPos;     // posicion  object space
            float3 localNormal;  // normal object space 
            INTERNAL_DATA
        };

      
        void vert(inout appdata_full v, out Input o)
        {
            UNITY_INITIALIZE_OUTPUT(Input, o);

            
            o.localPos    = v.vertex.xyz;
            o.localNormal = v.normal.xyz;
        }

      
        fixed4 SampleTriplanar(sampler2D tex, float3 pos, float3 normal, float scale)
        {
            
            float3 scaledPos = pos * scale;

            
            fixed4 projX = tex2D(tex, scaledPos.zy); 
            fixed4 projY = tex2D(tex, scaledPos.xz); 
            fixed4 projZ = tex2D(tex, scaledPos.xy); 

            
            float3 blend = pow(abs(normal), _BlendSharpness);

            
            blend = blend / (blend.x + blend.y + blend.z);

            
            return projX * blend.x + projY * blend.y + projZ * blend.z;
        }

        float3 SampleTriplanarNormal(sampler2D tex, float3 pos, float3 normal, float scale)
        {
            float3 scaledPos = pos * scale;

            //Pasar textura a rango -1 1 porque las normals pueden ser negativas
            float3 normalX = tex2D(tex, scaledPos.zy).rgb * 2.0 - 1.0;
            float3 normalY = tex2D(tex, scaledPos.xz).rgb * 2.0 - 1.0;
            float3 normalZ = tex2D(tex, scaledPos.xy).rgb * 2.0 - 1.0;

            
            float3 blend = pow(abs(normal), _BlendSharpness);
            blend = blend / (blend.x + blend.y + blend.z);

            // 3 normales
            float3 result = normalX * blend.x + normalY * blend.y + normalZ * blend.z;

            
            return result;
        }

        
        void surf(Input IN, inout SurfaceOutputStandard o)
        {
            float3 pos;
            float3 normal;

            //Esto se ve es necesario para activar la keyword no borrar
            #if defined(TRIPLANAR_LOCAL)
                pos    = IN.localPos;
                normal = IN.localNormal;
            #else
                pos    = IN.worldPos;
                normal = WorldNormalVector(IN, float3(0, 0, 1));
            #endif

            
            fixed4 albedo = SampleTriplanar(_MainTex, pos, normal, _TriplanarScale);
            float3 bumpNormal = SampleTriplanarNormal(_Normal, pos, normal, _TriplanarScale);

            
            o.Albedo    = albedo.rgb * _Color.rgb;
            o.Normal    = bumpNormal;
            o.Metallic  = _Metallic;
            o.Smoothness = _Smoothness;
            o.Alpha     = albedo.a;
        }

        ENDCG
    }

}
