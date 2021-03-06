#pragma pack_matrix(row_major)

cbuffer cb0 : register(b0)
{
	float2 resolution;
};

cbuffer cb1 : register(b1)
{
	float4 _L;
	float4 Lc;
	float4x4 Lp;
};


Texture2D		position	: register(t0);
Texture2D		normal		: register(t1);
Texture2D		diffuse		: register(t2);
Texture2D		material	: register(t3);

Texture2D		shadow_map	: register(t4);

SamplerState	smp			: register(s0);
SamplerState	shadow_smp	: register(s1);

float4 main(float4 pos : SV_POSITION) : SV_TARGET
{
	float2 uv = pos.xy / resolution;
	
	float3 n = normalize(
		(normal.Sample(smp, uv).xyz*float3(2.f,2.f,2.f)) - float3(1.f,1.f,1.f));
	float3 L = normalize(_L.xyz);
	
	float ndl = max(0.f, dot(n, L));

	//shadows
	float s = 0.f;
	float3 pw = position.Sample(smp, uv).xyz*float3(2.f, 2.f, 2.f) - float3(1.f, 1.f, 1.f);
	float4 pL = mul(float4(pw, 1.f), Lp);
	pL /= pL.w;
	pL.x = (pL.x * 0.5) + 0.5;
	pL.y = (pL.y * 0.5) + 0.5;
	pL.y = 1.f - pL.y;
	float bias = max(0.05 * (1.0 - dot(n, L)), 0.005);
	for (int x = -1; x <= 1; ++x) {
		for (int y = -1; y <= 1; ++y) {
			float pLd = shadow_map.Sample(shadow_smp, pL.xy, int2(x, y));
			s += pL.z - bias < pLd ? 1.f : 0.f;
		}
	}
	s /= 9.f;
	
	return //uv.x > 0.5f && uv.y > 0.5f ?
		//shadow_map.Sample(shadow_smp, (uv-0.5f)*2.f) :
		//float4(abs(pL.xy), 0.f, 1.f);
		diffuse.Sample(smp, uv)*ndl*Lc*s;
}