using System;
namespace PixelHorizon_Beef.Filter;

struct IMAGE_PROCESS_DESC
{
    uint8* pSrc;
    uint8* pDest;
    FILTER_TYPE FilterType;
    uint32 dwThreadNum;
    uint32 Width;
    uint32 Height;
}

class CPU_Filter
{
    [Packed(1)]
    struct RGBA
    {
        public uint8 b;
        public uint8 g;
        public uint8 r;
        public uint8 a;
    }

    float[3 * 3] SAMPLE_MASK_3_3_BARTLETT =
        .(
        1,  1, 1,
        1,  1, 1,
        1,  1, 1
        );

    float[3 * 3] SAMPLE_MASK_3_3_LAPLACIAN =
        .(
        -1, -1, -1,
        -1, 8, -1,
        -1, -1, -1
        );

    float[3 * 3] SAMPLE_MASK_3_3_GAUSSIAN =
        .(
        1,  4, 1,
        4, 12, 4,
        1,  4, 1
        );

    const int MASK_3_3_WIDTH = 3;
    const int MASK_3_3_HEIGHT = 3;
    const int MASK_3_3_CENTER_X = 1;
    const int MASK_3_3_CENTER_Y = 1;

    float[5 * 5] SAMPLE_MASK_5_5_GAUSSIAN =
        .(
        1,  4, 8, 4, 1,
        4, 12, 15, 12, 4,
        8, 25, 49, 25, 8,
        4, 12, 15, 12, 4,
        1,  4, 8, 4, 1
        );

    const int MASK_5_5_WIDTH = 5;
    const int MASK_5_5_HEIGHT = 5;
    const int MASK_5_5_CENTER_X = 2;
    const int MASK_5_5_CENTER_Y = 2;

    uint32 SampleBlurPixel32_CPU(uint8* pBits, int iWidth, int iHeight, int iPitch, int sx, int sy, float* pMask, int iMaskWidth, int iMaskHeight, int iMaskCenterX, int iMaskCenterY)
    {
        //float mask_center_value = pMask[iMaskCenterX + iMaskWidth*iMaskCenterY];

        int src_start_x = sx - iMaskCenterX;

        int mask_start_x = 0;
        int mask_start_y = 0;

        if (src_start_x < 0)
        {
            mask_start_x = 0 - src_start_x;
        }

        int  src_start_y = sy - iMaskCenterY;

        if (src_start_y < 0)
        {
            mask_start_y = 0 - src_start_y;
        }

        int src_end_x = src_start_x + iMaskWidth;
        int src_end_y = src_start_y + iMaskHeight;

        if (src_start_x < 0)
        {
            src_start_x = 0;
        }

        if (src_start_y < 0)
        {
            src_start_y = 0;
        }

        if (src_end_x > iWidth)
        {
            src_end_x = iWidth;
        }

        if (src_end_y > iHeight)
        {
            src_end_y = iHeight;
        }

        int sample_width = src_end_x - src_start_x;
        int sample_height = src_end_y - src_start_y;

        float[4] color;
        float[4] total_color  = .(0, 0, 0, 0);
        uint32 R;
        uint32 G;
        uint32 B;
        uint32 A;

        float weight;
        uint32 dwPixelOut, dwPixelIn;

        float total = 0.0f;
        for (int y = 0; y < sample_height; y++)
        {
            for (int x = 0; x < sample_width; x++)
            {
                total += pMask[(x + mask_start_x) + (y + mask_start_y) * iMaskWidth];
            }
        }


        uint32*  pPixel;
        for (int y = 0; y < sample_height; y++)
        {
            for (int x = 0; x < sample_width; x++)
            {
                weight = pMask[(x + mask_start_x) + (y + mask_start_y) * iMaskWidth] / total;
                if (weight != 0.0f)
                {
                    pPixel = (uint32*)(pBits + ((x + src_start_x) << 2) + (y + src_start_y) * iPitch);


                    dwPixelIn = *pPixel;

                    color[3] = (float)((dwPixelIn & 0xFF000000) >> 24);
                    color[2] = (float)((dwPixelIn & 0x00FF0000) >> 16);
                    color[1] = (float)((dwPixelIn & 0x0000FF00) >> 8);
                    color[0] = (float)(dwPixelIn & 0x000000FF);

                    for (int k = 0; k < 4; k++)
                    {
                        total_color[k] += (color[k] * weight);
                    }
                }
            }
        }
        A = (uint32)total_color[3];
        R = (uint32)total_color[2];
        G = (uint32)total_color[1];
        B = (uint32)total_color[0];


        dwPixelOut = (A << 24) | (R << 16) | (G << 8) | B;


        return dwPixelOut;
    }

    uint32 SampleEdgePixel32_CPU(uint8* pBits, int iWidth, int iHeight, int iPitch, int sx, int sy, float* pMask, int iMaskWidth, int iMaskHeight, int iMaskCenterX, int iMaskCenterY)
    {
        //float mask_center_value = pMask[iMaskCenterX + iMaskWidth * iMaskCenterY];

        int  src_start_x = sx - iMaskCenterX;

        int  mask_start_x = 0;
        int  mask_start_y = 0;

        if (src_start_x < 0)
            mask_start_x = 0 - src_start_x;

        int  src_start_y = sy - iMaskCenterY;

        if (src_start_y < 0)
        {
            mask_start_y = 0 - src_start_y;
        }

        int  src_end_x = src_start_x + iMaskWidth;
        int  src_end_y = src_start_y + iMaskHeight;
        if (src_start_x < 0)
        {
            src_start_x = 0;
        }

        if (src_start_y < 0)
        {
            src_start_y = 0;
        }

        if (src_end_x > iWidth)
        {
            src_end_x = iWidth;
        }

        if (src_end_y > iHeight)
        {
            src_end_y = iHeight;
        }

        int  sample_width = src_end_x - src_start_x;
        int  sample_height = src_end_y - src_start_y;

        float[4] color;
        float[4] total_color  = .(0, 0, 0, 0);

        float weight;
        uint32 dwPixelOut;
        uint32 dwPixelIn;

        uint32*  pPixel;
        for (int y = 0; y < sample_height; y++)
        {
            for (int x = 0; x < sample_width; x++)
            {
                weight = pMask[(x + mask_start_x) + (y + mask_start_y) * iMaskWidth];
                pPixel = (uint32*)(pBits + ((x + src_start_x) << 2) + (y + src_start_y) * iPitch);

                dwPixelIn = *pPixel;

                color[3] = (float)((dwPixelIn & 0xFF000000) >> 24);
                color[2] = (float)((dwPixelIn & 0x00FF0000) >> 16);
                color[1] = (float)((dwPixelIn & 0x0000FF00) >> 8);
                color[0] = (float)(dwPixelIn & 0x000000FF);

                for (int k = 0; k < 4; k++)
                {
                    total_color[k] += (color[k] * weight);
                }
            }
        }

        int bw = (uint32)((total_color[2] * 0.3f) + (total_color[1] * 0.59f) + (total_color[0] * 0.11f));
        bw = 255 - bw;
        bw = Math.Clamp(bw, 0, 255);

        dwPixelOut = (uint32)((bw << 24) | (bw << 16) | (bw << 8) | bw);

        return dwPixelOut;
    }


    void CPU_Blur_Filter(uint8* pDest, uint8* pSrc, uint32 dwWidth, uint32 dwHeight)
    {
        uint32 dwPitch = dwWidth * 4;

        uint32 start_y = 0;
        uint32 end_y = start_y + dwHeight;

        for (int y = start_y; y < end_y; y++)
        {
            for (int x = 0; x < dwWidth; x++)
            {
                uint32 dwPixel = SampleBlurPixel32_CPU(pSrc, dwWidth, dwHeight, dwPitch, x, y, &SAMPLE_MASK_5_5_GAUSSIAN, MASK_5_5_WIDTH, MASK_5_5_HEIGHT, MASK_5_5_CENTER_X, MASK_5_5_CENTER_Y);

                uint32* pDestColor = (uint32*)pDest + x + (y * dwWidth);
                *pDestColor = dwPixel;
            }
        }
    }
    void CPU_Edge_Filter(uint8* pDest, uint8* pSrc, uint32 dwWidth, uint32 dwHeight)
    {
        uint32 dwPitch = dwWidth * 4;

        uint32 start_y = 0;
        uint32 end_y = start_y + dwHeight;

        for (int y = start_y; y < end_y; y++)
        {
            for (int x = 0; x < dwWidth; x++)
            {
                uint32 dwPixel = SampleEdgePixel32_CPU(pSrc, dwWidth, dwHeight, dwPitch, x, y, &SAMPLE_MASK_3_3_LAPLACIAN, MASK_3_3_WIDTH, MASK_3_3_HEIGHT, MASK_3_3_CENTER_X, MASK_3_3_CENTER_Y);
                uint32* pDestColor = (uint32*)pDest + x + (y * dwWidth);
                *pDestColor = dwPixel;
            }
        }
    }
    void CPU_BW_Filter(uint8* pDest, uint8* pSrc, uint32 dwWidth, uint32 dwHeight)
    {
        //uint32 dwPitch = dwWidth * 4;

        uint32 start_y = 0;
        uint32 end_y = start_y + dwHeight;

        for (int y = start_y; y < end_y; y++)
        {
            for (int x = 0; x < dwWidth; x++)
            {
                RGBA* pSrcColor = (RGBA*)pSrc + x + (y * dwWidth);
                RGBA* pDestColor = (RGBA*)pDest + x + (y * dwWidth);

                int  iBright = (int)(((float)pSrcColor.r * 0.3f) + ((float)pSrcColor.g * 0.59f) + ((float)pSrcColor.b * 0.11f));

                pDestColor.a = (uint8)iBright;
                pDestColor.r = (uint8)iBright;
                pDestColor.g = (uint8)iBright;
                pDestColor.b = (uint8)iBright;
            }
        }
    }

}