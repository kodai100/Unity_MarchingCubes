Shader "Hidden/GPUMarchingCubes/Render"{
	Properties{
		_MainTex       ("Texture",        2D   ) = "white" {}
		_DiffuseColor  ("Diffuse Color",  Color) = (0.70, 0.70, 0.70, 1.00)
		_SpecularColor ("Specular Color", Color) = (0.99, 0.99, 0.99, 1.00)
		_AmbientColor  ("Ambient Color",  Color) = (0.10, 0.10, 0.10, 1.00)
	}

	CGINCLUDE
	#include "UnityCG.cginc"

	struct SimpleVertex{
		float4 position : POSITION;
		float4 color    : COLOR;
	};

	struct v2g{
		float4 pos    : SV_POSITION;
		float4 color  : COLOR;
	};

	struct g2f{
		float4 pos      : SV_POSITION;
		float4 color    : COLOR;
		float3 normal   : NORMAL;
		float4 worldPos : TEXCOORD0;
	};

	sampler2D _MainTex;
	float4 _MainTex_ST;

	sampler3D _DataFieldTex;

	StructuredBuffer<SimpleVertex> _VertexBuffer;
	StructuredBuffer<int>          _TriTableBuffer;
	StructuredBuffer<int>          _EdgeTableBuffer;

	float3 _VertDecals[8];

	float  _IsoLevel;

	float3 _LightPos;

	fixed4 _DiffuseColor;
	fixed4 _SpecularColor;
	fixed4 _AmbientColor;

	v2g vert(uint id : SV_VertexID)
	{
		v2g o   = (v2g)0;
		o.pos   = _VertexBuffer[id].position;
		o.color = _VertexBuffer[id].color;
		return o;
	}

	float3 vertexInterp(float isoLevel, float3 v0, float l0, float3 v1, float l1){
		float lerper = (isoLevel - l0) / (l1 - l0);
		return lerp(v0, v1, lerper);
	}

	// Gets a value from the look-up table
	int triTableValue(int i, int j){
		if (i >= 256 || j >= 16){
			return -1;
		}
		return _TriTableBuffer[i * 16 + j];
	}

	[maxvertexcount(18)]
	void geom(point v2g input[1], inout TriangleStream <g2f> triStream)
	{
		v2g o = (v2g)0;

		float isolevel = _IsoLevel;

		float3 position = input[0].pos.xyz;

		int cubeindex = 0;

		// 左下を起点に立方体の各頂点位置を計算
		float3 cubePos[8];
		cubePos[0] = position + _VertDecals[0];
		cubePos[1] = position + _VertDecals[1];
		cubePos[2] = position + _VertDecals[2];
		cubePos[3] = position + _VertDecals[3];
		cubePos[4] = position + _VertDecals[4];
		cubePos[5] = position + _VertDecals[5];
		cubePos[6] = position + _VertDecals[6];
		cubePos[7] = position + _VertDecals[7];

		// 各頂点の濃度値を取得
		float cubeVal[8];
		cubeVal[0] = tex3Dlod(_DataFieldTex, float4(((cubePos[0] + 1.0) / 2.0), 0.0)).r;
		cubeVal[1] = tex3Dlod(_DataFieldTex, float4(((cubePos[1] + 1.0) / 2.0), 0.0)).r;
		cubeVal[2] = tex3Dlod(_DataFieldTex, float4(((cubePos[2] + 1.0) / 2.0), 0.0)).r;
		cubeVal[3] = tex3Dlod(_DataFieldTex, float4(((cubePos[3] + 1.0) / 2.0), 0.0)).r;
		cubeVal[4] = tex3Dlod(_DataFieldTex, float4(((cubePos[4] + 1.0) / 2.0), 0.0)).r;
		cubeVal[5] = tex3Dlod(_DataFieldTex, float4(((cubePos[5] + 1.0) / 2.0), 0.0)).r;
		cubeVal[6] = tex3Dlod(_DataFieldTex, float4(((cubePos[6] + 1.0) / 2.0), 0.0)).r;
		cubeVal[7] = tex3Dlod(_DataFieldTex, float4(((cubePos[7] + 1.0) / 2.0), 0.0)).r;

		// Determine the index into the edge table which tells us which vertices are inside of the surface
		// Cubeの値から三角形形成データのインデックスを求める
		cubeindex =  int(cubeVal[0] < isolevel);
		cubeindex += int(cubeVal[1] < isolevel) << 1;
		cubeindex += int(cubeVal[2] < isolevel) << 2;
		cubeindex += int(cubeVal[3] < isolevel) << 3;
		cubeindex += int(cubeVal[4] < isolevel) << 4;
		cubeindex += int(cubeVal[5] < isolevel) << 5;
		cubeindex += int(cubeVal[6] < isolevel) << 6;
		cubeindex += int(cubeVal[7] < isolevel) << 7;

		// Cube is entirely in/out of the surface
		if (cubeindex == 0 || cubeindex == 255){
			// この場合は三角形を形成しない
			return;
		}

		// 正規化Cubeの辺上の座標を求める
		// Find the vertices where the surface intersects the cube
		float3 vertlist[12];	
		// float3 vertexInterp(float isoLevel, float3 v0, float l0, float3 v1, float l1)
		vertlist[0]  = vertexInterp(isolevel, cubePos[0], cubeVal[0], cubePos[1], cubeVal[1]);
		vertlist[1]  = vertexInterp(isolevel, cubePos[1], cubeVal[1], cubePos[2], cubeVal[2]);
		vertlist[2]  = vertexInterp(isolevel, cubePos[2], cubeVal[2], cubePos[3], cubeVal[3]);
		vertlist[3]  = vertexInterp(isolevel, cubePos[3], cubeVal[3], cubePos[0], cubeVal[0]);
		vertlist[4]  = vertexInterp(isolevel, cubePos[4], cubeVal[4], cubePos[5], cubeVal[5]);
		vertlist[5]  = vertexInterp(isolevel, cubePos[5], cubeVal[5], cubePos[6], cubeVal[6]);
		vertlist[6]  = vertexInterp(isolevel, cubePos[6], cubeVal[6], cubePos[7], cubeVal[7]);
		vertlist[7]  = vertexInterp(isolevel, cubePos[7], cubeVal[7], cubePos[4], cubeVal[4]);
		vertlist[8]  = vertexInterp(isolevel, cubePos[0], cubeVal[0], cubePos[4], cubeVal[4]);
		vertlist[9]  = vertexInterp(isolevel, cubePos[1], cubeVal[1], cubePos[5], cubeVal[5]);
		vertlist[10] = vertexInterp(isolevel, cubePos[2], cubeVal[2], cubePos[6], cubeVal[6]);
		vertlist[11] = vertexInterp(isolevel, cubePos[3], cubeVal[3], cubePos[7], cubeVal[7]);

		// 三角形頂点生成
		float4 col = float4(cos(isolevel * 10.0 - 0.5), sin(isolevel * 10.0 - 0.5), cos(1.0 - isolevel), 1.0);
		int i = 0;

		while (true) {
			int tri1 = triTableValue(cubeindex, i);
			if (tri1 != -1) {
				g2f p0 = (g2f)0;
				g2f p1 = (g2f)0;
				g2f p2 = (g2f)0;

				// 法線を求める
				float3 v0 = vertlist[triTableValue(cubeindex, i + 1)] - vertlist[tri1];
				float3 v1 = vertlist[triTableValue(cubeindex, i + 2)] - vertlist[tri1];
				float3 norm = normalize(cross(v0, v1));

				p0.worldPos = float4(vertlist[tri1], 1);
				p0.pos    = mul(UNITY_MATRIX_MVP, p0.worldPos);
				p0.color  = col;
				p0.normal = norm;

				p1.worldPos = float4(vertlist[triTableValue(cubeindex, i + 1)], 1);
				p1.pos    = mul(UNITY_MATRIX_MVP, p1.worldPos);
				p1.color  = col;
				p1.normal = norm;

				p2.worldPos = float4(vertlist[triTableValue(cubeindex, i + 2)], 1);
				p2.pos    = mul(UNITY_MATRIX_MVP, p2.worldPos);
				p2.color  = col;
				p2.normal = norm;

				triStream.Append(p0);
				triStream.Append(p1);
				triStream.Append(p2);

				triStream.RestartStrip();
			}
			else {
				break;
			}
			i = i + 3;
		}
	}

	fixed4 frag(g2f i) : SV_Target{
		float3 diffuseMaterial  = _DiffuseColor.rgb;
		float3 specularMaterial = _SpecularColor.rgb;
		float3 ambientMaterial  = _AmbientColor.rgb;

		float3 lightDir = normalize(_LightPos.xyz - i.worldPos.xyz);
		float3 norm     = i.normal.xyz;// -normalize(i.normal.xyz);
		
		float3 eyeDir  = normalize(_WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld, i.worldPos).xyz);
		float3 halfDir = normalize(lightDir + eyeDir);

		float diffStrength = abs(dot(norm, lightDir));
		float specStrength = abs(dot(norm, halfDir));

		float3 diffuse  = diffStrength           * diffuseMaterial;
		float3 specular = pow(specStrength, 32.) * specularMaterial;

		float4 col;
		col.rgb = ambientMaterial + diffuse + specular;
		col.a = 1.0;
		// col.rgb = norm;
		return col;
	}
	ENDCG

	SubShader
	{
		Tags{ "RenderType" = "Opaque" }
		LOD 100
		Cull Off

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
