using System;
using System.IO;
namespace RayTracingInOneWeekend_Beef.Impl;

static
{
    public typealias color = vec3;

    [Inline]
    static double linear_to_gamma(double linear_component)
    {
        if (linear_component > 0)
        {
            return Math.Sqrt(linear_component);
        }

        return 0;
    }


    public static void write_color(StreamWriter sw, color pixel_color)
    {
        var r = pixel_color.x;
        var g = pixel_color.y;
        var b = pixel_color.z;

        // Apply a linear to gamma transform for gamma 2
        r = linear_to_gamma(r);
        g = linear_to_gamma(g);
        b = linear_to_gamma(b);

        // Translate the [0,1] component values to the byte range [0,255].
        static Interval intensity = .(0.000, 0.999);
        int rbyte = int(256 * intensity.clamp(r));
        int gbyte = int(256 * intensity.clamp(g));
        int bbyte = int(256 * intensity.clamp(b));

        sw.WriteLine($"{rbyte} {gbyte} {bbyte}");
    }
}