using UnityEngine;
using System.Collections;
using System.Runtime.InteropServices;

namespace irishoak{

    public struct SimpleVertex{
        public Vector4 position;
        public Color   color;

        public SimpleVertex(Vector3 pos, Color col){
            this.position = pos;
            this.color = col;
        }
    }

    public class MarchingCubesGPU : MonoBehaviour{

        public VolumeSupplyer volumeSupplyer;
        public Material RenderMat;

        public Vector3 numChunks = new Vector3(32, 32, 32);
        [Range(0.0f, 1.0f)] public float IsoLevel = 0.5f;

        Vector3 _numChunks;
        Vector3 _cubeStep;
        Vector4[] _vertDecals;

        ComputeBuffer _vertexBuffer;
        ComputeBuffer _edgeTableBuffer;
        ComputeBuffer _triTableBuffer;

        public Vector3 LightPos = new Vector3(0.0f, 2.0f, 0.0f);

        #region MonoBehaviour Functions
        void Start(){
            InitBuffer();
        }

        void OnRenderObject(){
            Render();
        }

        void OnDestroy(){
            DeleteBuffer();
        }
        #endregion

        #region Private Functions
        void InitBuffer(){

            _numChunks = numChunks;
            _cubeStep = new Vector3(2.0f / _numChunks.x, 2.0f / _numChunks.y, 2.0f / _numChunks.z);

            _vertDecals = new Vector4[8];
            _vertDecals[0] = new Vector4(0.0f, 0.0f, 0.0f, 0.0f);
            _vertDecals[1] = new Vector4(_cubeStep.x, 0.0f, 0.0f, 0.0f);
            _vertDecals[2] = new Vector4(_cubeStep.x, _cubeStep.y, 0.0f, 0.0f);
            _vertDecals[3] = new Vector4(0.0f, _cubeStep.y, 0.0f, 0.0f);
            _vertDecals[4] = new Vector4(0.0f, 0.0f, _cubeStep.z, 0.0f);
            _vertDecals[5] = new Vector4(_cubeStep.x, 0.0f, _cubeStep.z, 0.0f);
            _vertDecals[6] = new Vector4(_cubeStep.x, _cubeStep.y, _cubeStep.z, 0.0f);
            _vertDecals[7] = new Vector4(0.0f, _cubeStep.y, _cubeStep.z, 0.0f);
            
            // vertex buffer
            SimpleVertex[] vertexArr = new SimpleVertex[(int)_numChunks.x * (int)_numChunks.y * (int)_numChunks.z];
            int ii = 0;
            for (var k = -1.0f; k < 1.0f; k += _cubeStep.z){
                for (var j = -1.0f; j < 1.0f; j += _cubeStep.y){
                    for (var i = -1.0f; i < 1.0f; i += _cubeStep.x){
                        vertexArr[ii] = new SimpleVertex(new Vector3(i, j, k), new Color(i / _numChunks.x, j / _numChunks.y, k / _numChunks.z, 1.0f));  // Colorは座標を意味する
                        ii++;
                    }
                }
            }
            _vertexBuffer = new ComputeBuffer(vertexArr.Length, Marshal.SizeOf(typeof(SimpleVertex)));
            _vertexBuffer.SetData(vertexArr);

            // --- triTable ---
            int[] triTableArr = new int[256 * 16];
            for (var i = 0; i < 256; i++) {
                for (var j = 0; j < 16; j++){
                    triTableArr[i * 16 + j] = MarchingCubesTable.triTable[i, j];
                }
            }
            _triTableBuffer = new ComputeBuffer(256 * 16, Marshal.SizeOf(typeof(int)));
            _triTableBuffer.SetData(triTableArr);

            // --- edgeTable ---
            _edgeTableBuffer = new ComputeBuffer(256, Marshal.SizeOf(typeof(int)));
            _edgeTableBuffer.SetData(MarchingCubesTable.edgeTable);
            
        }

        void DeleteBuffer(){
            if (_vertexBuffer != null){
                _vertexBuffer.Release();
                _vertexBuffer = null;
            }
            if (_triTableBuffer != null){
                _triTableBuffer.Release();
                _triTableBuffer = null;
            }
            if (_edgeTableBuffer != null){
                _edgeTableBuffer.Release();
                _edgeTableBuffer = null;
            }
        }

        void Render(){
            RenderMat.SetPass(0);
            RenderMat.SetBuffer ("_VertexBuffer",    _vertexBuffer);    // 格子点
            RenderMat.SetBuffer ("_TriTableBuffer",  _triTableBuffer);  // ポリゴン情報テーブル
            RenderMat.SetBuffer ("_EdgeTableBuffer", _edgeTableBuffer); // エッジ情報テーブル
            RenderMat.SetTexture("_DataFieldTex", volumeSupplyer.GetDataFieldTex ());   // ボリュームデータ
            RenderMat.SetVectorArray("_VertDecals", _vertDecals);   // 立方体格子点の各インデックスの相対位置
            RenderMat.SetVector ("_LightPos", LightPos);
            RenderMat.SetFloat  ("_IsoLevel", IsoLevel);

            Graphics.DrawProcedural(MeshTopology.Points, _vertexBuffer.count, 0);
        }
        #endregion
    }
}