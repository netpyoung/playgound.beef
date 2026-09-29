using System;

namespace PixelHorizon_Beef.Common;

[Packed(1), Ordered]
struct int2
{
    public int32 x;
    public int32 y;

    public const int2 ZERO = .(0, 0);

    public this() : this(0, 0) { }

    public this(int32 x, int32 y)
    {
        this.x = x;
        this.y = y;
    }
}

[Packed(1), Ordered]
struct SRect
{
    public int2 min;
    public int2 max;

    public this(int32 minX, int32 minY, int32 maxX, int32 maxY)
    {
        min.x = minX;
        min.y = minY;
        max.x = maxX;
        max.y = maxY;
    }
}