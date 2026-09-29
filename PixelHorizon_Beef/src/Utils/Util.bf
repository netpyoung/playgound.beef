using PixelHorizon_Beef.Common;
using System;

namespace PixelHorizon_Beef.Utils;

static class Util
{
    public struct Interop
    {
        [CLink]
        public static extern void srand(uint seed);

        [CLink]
        public static extern int rand();
    }

    public static bool CalcClipArea(int2* pivOutSrcStart, int2* pivOutDestStart, int2* pivOutDestSize, int2* pivPos, int2* pivImageSize, int2* pivBufferSize)
    {
        int32 dest_start_x = Math.Max(pivPos.x, 0);
        int32 dest_start_y = Math.Max(pivPos.y, 0);
        dest_start_x = Math.Min(dest_start_x, pivBufferSize.x);
        dest_start_y = Math.Min(dest_start_y, pivBufferSize.y);

        int32 dest_end_x = Math.Max(pivPos.x + pivImageSize.x, 0);
        int32 dest_end_y = Math.Max(pivPos.y + pivImageSize.y, 0);
        dest_end_x = Math.Min(dest_end_x, pivBufferSize.x);
        dest_end_y = Math.Min(dest_end_y, pivBufferSize.y);

        int32 width = dest_end_x - dest_start_x;
        int32 height = dest_end_y - dest_start_y;
        if (width <= 0 || height <= 0)
        {
            return false;
        }

        int32 src_start_x = dest_start_x - pivPos.x;
        int32 src_start_y = dest_start_y - pivPos.y;

        *pivOutSrcStart = .(src_start_x, src_start_y);
        pivOutDestStart.x = dest_start_x;
        pivOutDestStart.y = dest_start_y;
        pivOutDestSize.x = width;
        pivOutDestSize.y = height;

        return true;
    }

    public static bool IsCollisionRectVsRect(int2* pv3MinA, int2* pv3MaxA, int2* pv3MinB, int2* pv3MaxB)
    {
        int32* a_min = &pv3MinA.x;
        int32* a_max = &pv3MaxA.x;
        int32* b_min = &pv3MinB.x;
        int32* b_max = &pv3MaxB.x;

        for (int i = 0; i < 2; i++)
        {
            if (a_min[i] > b_max[i] || a_max[i] < b_min[i])
            {
                return false;
            }
        }

        return true;
    }
}