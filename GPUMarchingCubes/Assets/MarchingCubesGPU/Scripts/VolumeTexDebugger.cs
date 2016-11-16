using UnityEngine;
using System.Collections;

namespace irishoak
{

    public class VolumeTexDebugger : MonoBehaviour
    {
        public Material RenderMat;

        
        public void DrawVolumeTex(RenderTexture volume, int width, int height, int depth)
        {
            int vNum = width * height * depth;
            RenderMat.SetPass(0);
            RenderMat.SetTexture("_VolumeTex", volume);
            RenderMat.SetVector("_GridSize", new Vector4(width, height, depth, 0.0f));
            Graphics.DrawProcedural(MeshTopology.Points, vNum, 0);
        }
    }
}