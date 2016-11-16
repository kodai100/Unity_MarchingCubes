Shader "Hidden/GPUMarchingCubes/DebugCubeRenderVolumeTex"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_CubeSize ("CubeSize", Float) = 0.05
		_Scale ("Scale", Float) = 1.0
	}

	CGINCLUDE

	#include "UnityCG.cginc"

	struct v2g
	{
		float4 position : POSITION;
		float4 color    : COLOR;
	};

	struct g2f
	{
		float4 position : SV_Position;
		float4 color    : COLOR;
		float2 texcoord : TEXCOORD0;
	};


	sampler2D _MainTex;
	float4 _MainTex_ST;

	sampler3D _VolumeTex;

	float4 _GridSize;
	float  _Scale;
	float  _CubeSize;
	
	v2g vert (uint id : SV_VertexID)
	{
		v2g o = (v2g)0;
		float4 pos = float4(
			fmod(id + 0.5, _GridSize.x), 
			floor(fmod((id + 0.5), (_GridSize.x * _GridSize.y)) / _GridSize.y), 
			floor((id + 0.5) / (_GridSize.x * _GridSize.y)), 
			1.0
		);

		o.position = float4((pos.x / _GridSize.x - 0.5) * _Scale, (pos.y / _GridSize.y - 0.5) * _Scale, (pos.z / _GridSize.z - 0.5) * _Scale, 1.0);
		float vol = tex3Dlod(_VolumeTex, float4(pos.x / _GridSize.x, pos.y / _GridSize.y, pos.z / _GridSize.z, 0.0)).r;
		o.color = float4 (vol, 0, 0, 1);
		return o;
	}

	static const float2 g_texcoord[4] = {float2(1, 0), float2(0, 0), float2(0, 1), float2(1, 1)};

	[maxvertexcount(24)]
	void geom (point v2g input[1], inout TriangleStream<g2f> outStream)
	{
		g2f o = (g2f)0;
		float3 pos  = input[0].position.xyz;
		float  size = _CubeSize * input[0].color.x;

		float3 cv[8] = {
			float3(-0.5, -0.5, -0.5), // 0
			float3( 0.5, -0.5, -0.5), // 1
			float3( 0.5,  0.5, -0.5), // 2
			float3(-0.5,  0.5, -0.5), // 3
			float3(-0.5, -0.5,  0.5), // 4
			float3( 0.5, -0.5,  0.5), // 5
			float3( 0.5,  0.5,  0.5), // 6
			float3(-0.5,  0.5,  0.5)  // 7
		};

		if (size > 0) {

			// Top (Green)
			o.position = mul(UNITY_MATRIX_MVP, input[0].position + float4(cv[2] * size, 0)); o.texcoord = float2(0, 0); o.color = float4(0.0, 1.0, 0.0, 1.0); outStream.Append(o);
			o.position = mul(UNITY_MATRIX_MVP, input[0].position + float4(cv[3] * size, 0)); o.texcoord = float2(1, 0); o.color = float4(0.0, 1.0, 0.0, 1.0); outStream.Append(o);
			o.position = mul(UNITY_MATRIX_MVP, input[0].position + float4(cv[6] * size, 0)); o.texcoord = float2(0, 1); o.color = float4(0.0, 1.0, 0.0, 1.0); outStream.Append(o);
			o.position = mul(UNITY_MATRIX_MVP, input[0].position + float4(cv[7] * size, 0)); o.texcoord = float2(1, 1); o.color = float4(0.0, 1.0, 0.0, 1.0); outStream.Append(o);

			// Bottom (Orange)								
			o.position = mul(UNITY_MATRIX_MVP, input[0].position + float4(cv[0] * size, 0)); o.texcoord = float2(0, 0); o.color = float4(1.0, 0.5, 0.0, 1.0); outStream.Append(o);
			o.position = mul(UNITY_MATRIX_MVP, input[0].position + float4(cv[1] * size, 0)); o.texcoord = float2(1, 0); o.color = float4(1.0, 0.5, 0.0, 1.0); outStream.Append(o);
			o.position = mul(UNITY_MATRIX_MVP, input[0].position + float4(cv[4] * size, 0)); o.texcoord = float2(0, 1); o.color = float4(1.0, 0.5, 0.0, 1.0); outStream.Append(o);
			o.position = mul(UNITY_MATRIX_MVP, input[0].position + float4(cv[5] * size, 0)); o.texcoord = float2(1, 1); o.color = float4(1.0, 0.5, 0.0, 1.0); outStream.Append(o);

			// Front (Yellow)
			o.position = mul(UNITY_MATRIX_MVP, input[0].position + float4(cv[4] * size, 0)); o.texcoord = float2(0, 0); o.color = float4(1.0, 1.0, 0.0, 1.0); outStream.Append(o);
			o.position = mul(UNITY_MATRIX_MVP, input[0].position + float4(cv[5] * size, 0)); o.texcoord = float2(1, 0); o.color = float4(1.0, 1.0, 0.0, 1.0); outStream.Append(o);
			o.position = mul(UNITY_MATRIX_MVP, input[0].position + float4(cv[7] * size, 0)); o.texcoord = float2(0, 1); o.color = float4(1.0, 1.0, 0.0, 1.0); outStream.Append(o);
			o.position = mul(UNITY_MATRIX_MVP, input[0].position + float4(cv[6] * size, 0)); o.texcoord = float2(1, 1); o.color = float4(1.0, 1.0, 0.0, 1.0); outStream.Append(o);

			// Back (Red)
			o.position = mul(UNITY_MATRIX_MVP, input[0].position + float4(cv[1] * size, 0)); o.texcoord = float2(0, 0); o.color = float4(1.0, 0.0, 0.0, 1.0); outStream.Append(o);
			o.position = mul(UNITY_MATRIX_MVP, input[0].position + float4(cv[0] * size, 0)); o.texcoord = float2(1, 0); o.color = float4(1.0, 0.0, 0.0, 1.0); outStream.Append(o);
			o.position = mul(UNITY_MATRIX_MVP, input[0].position + float4(cv[2] * size, 0)); o.texcoord = float2(0, 1); o.color = float4(1.0, 0.0, 0.0, 1.0); outStream.Append(o);
			o.position = mul(UNITY_MATRIX_MVP, input[0].position + float4(cv[3] * size, 0)); o.texcoord = float2(1, 1); o.color = float4(1.0, 0.0, 0.0, 1.0); outStream.Append(o);

			// Left (Blue)								
			o.position = mul(UNITY_MATRIX_MVP, input[0].position + float4(cv[0] * size, 0)); o.texcoord = float2(0, 0); o.color = float4(0.0, 0.0, 1.0, 1.0); outStream.Append(o);
			o.position = mul(UNITY_MATRIX_MVP, input[0].position + float4(cv[4] * size, 0)); o.texcoord = float2(1, 0); o.color = float4(0.0, 0.0, 1.0, 1.0); outStream.Append(o);
			o.position = mul(UNITY_MATRIX_MVP, input[0].position + float4(cv[3] * size, 0)); o.texcoord = float2(0, 1); o.color = float4(0.0, 0.0, 1.0, 1.0); outStream.Append(o);
			o.position = mul(UNITY_MATRIX_MVP, input[0].position + float4(cv[7] * size, 0)); o.texcoord = float2(1, 1); o.color = float4(0.0, 0.0, 1.0, 1.0); outStream.Append(o);

			// Right (Magenta)											
			o.position = mul(UNITY_MATRIX_MVP, input[0].position + float4(cv[5] * size, 0)); o.texcoord = float2(0, 0); o.color = float4(1.0, 0.0, 1.0, 1.0); outStream.Append(o);
			o.position = mul(UNITY_MATRIX_MVP, input[0].position + float4(cv[1] * size, 0)); o.texcoord = float2(1, 0); o.color = float4(1.0, 0.0, 1.0, 1.0); outStream.Append(o);
			o.position = mul(UNITY_MATRIX_MVP, input[0].position + float4(cv[6] * size, 0)); o.texcoord = float2(0, 1); o.color = float4(1.0, 0.0, 1.0, 1.0); outStream.Append(o);
			o.position = mul(UNITY_MATRIX_MVP, input[0].position + float4(cv[2] * size, 0)); o.texcoord = float2(1, 1); o.color = float4(1.0, 0.0, 1.0, 1.0); outStream.Append(o);

			outStream.RestartStrip();
		}
	}
	
	fixed4 frag (g2f i) : Color{
		fixed4 col = i.color;
		return col;
	}
	ENDCG

	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma target   5.0
			#pragma vertex   vert
			#pragma geometry geom
			#pragma fragment frag
			ENDCG
		}
	}
}
