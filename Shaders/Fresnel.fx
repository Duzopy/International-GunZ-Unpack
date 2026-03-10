/*
    Shader Parameters
*/

float4x3 Identity;
float4x4 World;
float4x4 View;
float4x4 ViewProjection;

float3 CameraPosition;
float3 CameraDirection;

float4 MaterialAmbient;
float4 MaterialDiffuse;
float4 MaterialSpecular;
float MaterialPower;
float4 GlobalAmbient;
float3 Light0Position;
float4 Light0Ambient;
float4 Light0Diffuse;
float4 Light0Specular;
float Light0Range;
float3 Light1Position;
float4 Light1Ambient;
float4 Light1Diffuse;
float4 Light1Specular;
float Light1Range;
float4 Light0Attenuation;
float4 Light1Attenuation;

texture Texture;

float delta_time;

float4 FresnelColor = float4(0.0f, 1.0f, 1.0f, 1.0f);

float Scale = 1.0f;
float Power = 5.0f;
float Opacity = 1.0f;

/*
    End Shader Parameters
*/

//--------------------------------------------------------

//Texture Configuration for default texture
sampler2D textureSampler = sampler_state
{
    Texture = <Texture>;
    AddressU = Clamp;
    AddressV = Clamp;
    MinFilter = Linear;
    MagFilter = Anisotropic;
    MipFilter = Linear;
};

//--------------------------------------------------------

/*
    Functions
*/

float FresnelEffect(float3 Normal, float3 ViewDir, float Power)
{
    return pow((1.0f - saturate(dot(normalize(Normal), normalize(ViewDir)))), Power);
}

/*
    End Functions
*/

//--------------------------------------------------------

/*
    Default Vertex Structure Shading
*/

struct VS_INPUT {
  float4 Position: POSITION;
  float3 Normal: NORMAL;
  float2 Tex: TEXCOORD0;
};

struct VS_OUTPUT
{
	float4 Position : POSITION;
	float3 Normal : TEXCOORD0;
	float2 Tex : TEXCOORD1;
    float3 ViewDir : TEXCOORD2;
};
 
VS_OUTPUT MainVS(VS_INPUT In) {
    VS_OUTPUT Out;

    float4 TransformedPos = mul(In.Position,  World);

	Out.Position = mul(TransformedPos, ViewProjection);

	float3 mNormal = mul(float4(In.Normal, 0), World).xyz;

    Out.Normal = mNormal;
	Out.Tex = In.Tex;
    Out.ViewDir = CameraPosition - TransformedPos.xyz;

    return Out;
}



float4 MainPS(VS_OUTPUT In) : COLOR
{
    float4 BaseColor = tex2D(textureSampler, In.Tex);

    if(BaseColor.a == 0.f)
        discard;
		
    In.Normal = normalize(In.Normal);
    In.ViewDir = normalize(In.ViewDir);

    //float R = FresnelEffect(In.Normal, In.ViewDir, Power);
    float fresnel = Scale * pow(abs(1.0f - dot(In.Normal, In.ViewDir)), Power );

    float4 result =  lerp(BaseColor, FresnelColor, fresnel) ;
    result.a = MaterialDiffuse.w;
    return result;
}

float4 NoLight_NoFresnelPS(VS_OUTPUT In) : COLOR
{
    float4 BaseColor = tex2D(textureSampler, In.Tex);

    if(BaseColor.a == 0.f)
        discard;
		
    BaseColor.a = MaterialDiffuse.w;
    return BaseColor;
}

/*
    End Default Vertex Structure Shading
*/

//--------------------------------------------------------

/*
    Gunz skin.hlsl Pixel Shading
*/

struct SKINVS_OUTPUT
{
	float4 oPos 		: POSITION;
	float2 oT0 			: TEXCOORD0;
	float3 oNormal 		: TEXCOORD1;
	float3 ViewDir		: TEXCOORD2;
	float4 oDiffuse 	: COLOR0;
	float  oFog 		: FOG;
};

float4 SkinPS(SKINVS_OUTPUT In) : COLOR
{
    float4 BaseColor = tex2D(textureSampler, In.oT0);
	
    if(BaseColor.a == 0.f)
        discard;

    In.oNormal = normalize(In.oNormal);
    In.ViewDir = normalize(In.ViewDir);

    //float R = FresnelEffect(In.oNormal, In.ViewDir, Power);
    float fresnel = Scale * pow(abs(1.0f - dot(In.oNormal, In.ViewDir)), Power );

    float4 result =  lerp(BaseColor, FresnelColor, fresnel);
    result.a = MaterialDiffuse.w;
    return result;
}

float4 Skin_NoLight_NoFresnelPS(SKINVS_OUTPUT In) : COLOR
{
    float4 BaseColor = tex2D(textureSampler, In.oT0);

    if(BaseColor.a == 0.f)
        discard;
		
    BaseColor.a = MaterialDiffuse.w;
    return BaseColor;
}

/*
    End Gunz skin.hlsl Pixel Shading
*/

//--------------------------------------------------------

/*
    Techniques
*/

//Default 3D Space vertex buffer structure
technique Default
{
    pass P0
    {
	    CullMode = none;
        VertexShader = compile vs_2_0 MainVS();
		PixelShader = compile ps_2_0 MainPS();
    }
}

technique Clean
{
    pass P0
    {
	    CullMode = none;
        VertexShader = compile vs_2_0 MainVS();
		PixelShader = compile ps_2_0 NoLight_NoFresnelPS();
    }
}

//For gunz skin.hlsl shader
technique Skin
{
    pass P0
    {
	    CullMode = none;
		PixelShader = compile ps_2_0 SkinPS();
    }
}
technique SkinNoFresnel
{
    pass P0
    {
	    CullMode = none;
		PixelShader = compile ps_2_0 Skin_NoLight_NoFresnelPS();
    }
}

/*
    End Techniques
*/