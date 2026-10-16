using System;
namespace RayTracingInOneWeekend_Beef.Impl;

struct Interval
{
    public double min;
    public double max;

    public const Interval empty = Interval(Rtweekend.INFINITY, -Rtweekend.INFINITY);
    public const Interval universe = Interval(-Rtweekend.INFINITY, Rtweekend.INFINITY);

    public this() : this(Rtweekend.INFINITY, -Rtweekend.INFINITY)
    {
    }

    public this(double min, double max)
    {
        this.min = min;
        this.max = max;
    }

    [Inline]
    public double size()
    {
        return max - min;
    }

    [Inline]
    public bool contains(double x)
    {
        return min <= x && x <= max;
    }

    [Inline]
    public bool surrounds(double x)
    {
        return min < x && x < max;
    }

    [Inline]
    public double clamp(double x)
    {
        return Math.Clamp(x, min, max);
    }
}