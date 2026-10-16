using System;
namespace RayTracingInOneWeekend_Beef.Impl;

static class Rtweekend
{
    public const double INFINITY = double.MaxValue;
    public const double PI = 3.1415926535897932385;

    [Inline]
    public static double degrees_to_radians(double degrees)
    {
        return degrees * PI / 180.0;
    }

    static Random rand_state = new Random(seed: 0) ~ delete _;

    [Inline]
    public static double random_double()
    {
        // Returns a random real in [0,1).
        return rand_state.NextDouble();
    }

    [Inline]
    public static double random_double(double min, double max)
    {
        // Returns a random real in [min,max).
        return min + (max - min) * random_double();
    }
}