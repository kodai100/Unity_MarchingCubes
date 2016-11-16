using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace irishoak{
    public class VolumeSupplyer : MonoBehaviour{
        
        public ComputeShader DataFieldCS;

        public int ParticleNum = 8;

        public Vector3 numChunks = new Vector3 (32, 32, 32);
        [HideInInspector] public Vector3 _cubeStep;
        public Vector3 GridCenter = new Vector3(0.0f, 0.0f, 0.0f);
        public Vector3 GridSize   = new Vector3(2.0f, 2.0f, 2.0f);

        private float _timeStep;
        [Range(0,1)]public float timeScale = 0.4f;

        RenderTexture _dataFieldRenderTex;

        public VolumeTexDebugger VolumeTexDebugger;

        public bool EnableDrawDebugVolumeTex = false;

        #region Accessor
        public RenderTexture GetDataFieldTex ()
        {
            return this._dataFieldRenderTex;
        }
        #endregion

        #region MonoBehaviour Functions
        void Start(){
            InitParams();   // 格子幅の決定(gridSize/numChunk)
            InitBuffers();  // コンピュートバッファとレンダーテクスチャ(3次元ボリュームデータ)の初期化
        }

        void Update(){
            UdpateDataField();  // ボリュームデータのアップデート
        }

        void OnRenderObject(){
            if (EnableDrawDebugVolumeTex){
                if (VolumeTexDebugger != null){
                    // ボリュームデータを送り、レンダリングする
                    VolumeTexDebugger.DrawVolumeTex(_dataFieldRenderTex, _dataFieldRenderTex.width, _dataFieldRenderTex.height, _dataFieldRenderTex.volumeDepth);
                }
            }
        }

        void OnDestroy(){
            DeleteBuffers();
        }

        void OnDrawGizmos(){
            // グリッド(シミュレーション領域)のギズモ
            Gizmos.color = Color.yellow;
            Gizmos.DrawWireCube(GridCenter, GridSize);
        }
        #endregion

        #region Private Functions
        void InitParams(){
            _cubeStep = new Vector3(GridSize.x / numChunks.x, GridSize.y / numChunks.y, GridSize.z / numChunks.z);    // 2.0 => gridsize
            _timeStep = 0;
        }

        void InitBuffers(){

            // 空間上のパーティクルの分布を示すボリュームデータの初期化(3次元レンダーテクスチャ)
            _dataFieldRenderTex = new RenderTexture((int)numChunks.x, (int)numChunks.y, 0, RenderTextureFormat.RFloat);
            _dataFieldRenderTex.dimension         = UnityEngine.Rendering.TextureDimension.Tex3D;
            _dataFieldRenderTex.filterMode        = FilterMode.Point;
            _dataFieldRenderTex.volumeDepth       = (int)numChunks.z;
            _dataFieldRenderTex.enableRandomWrite = true;
            _dataFieldRenderTex.wrapMode          = TextureWrapMode.Clamp;
            _dataFieldRenderTex.hideFlags         = HideFlags.HideAndDontSave;
            _dataFieldRenderTex.Create();

        }

        void DeleteBuffers(){

            if(_dataFieldRenderTex != null){
                DestroyImmediate(_dataFieldRenderTex);
            }
            _dataFieldRenderTex = null;
        }
        

        void UdpateDataField(){
            _timeStep += Time.deltaTime;

            var id = DataFieldCS.FindKernel("ClearDataFieldCS");
            DataFieldCS.SetTexture(id, "_DataFieldTexRW", _dataFieldRenderTex);
            DataFieldCS.Dispatch(id, _dataFieldRenderTex.width / 8, _dataFieldRenderTex.height / 8, _dataFieldRenderTex.volumeDepth / 8);

            id = DataFieldCS.FindKernel("UpdateDataFieldCS");
            DataFieldCS.SetTexture(id, "_DataFieldTexRW",   _dataFieldRenderTex);
            DataFieldCS.SetInts  ("_GridNum", new int[3] { (int)numChunks.x, (int)numChunks.y, (int)numChunks.z });
            DataFieldCS.SetVector("_GridCenter", GridCenter);
            DataFieldCS.SetVector("_GridSize",   GridSize  );
            DataFieldCS.SetFloat("_Time", _timeStep);
            DataFieldCS.SetFloat("_TimeScale", timeScale);
            DataFieldCS.Dispatch(id, ParticleNum / 32, 1, 1);
        }
        #endregion
    }
}