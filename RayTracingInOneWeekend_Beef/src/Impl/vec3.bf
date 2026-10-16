using System;

namespace RayTracingInOneWeekend_Beef.Impl;

typealias point3 = vec3;

struct vec3
{
    public double[3] e;

    public double x => e[0];
    public double y => e[1];
    public double z => e[2];

    public this()
    {
        e = .();
    }

    public this(double e0, double e1, double e2)
    {
        e[0] = e0;
        e[1] = e1;
        e[2] = e2;
    }

    [Inline]
    public static vec3 operator -(vec3 e)
    {
        return vec3(-e[0], -e[1], -e[2]);
    }

    [Inline]
    public double this[int index] => e[index];

    [Inline]
    public ref double this[int index] mut => ref e[index];

    [Inline]
    public double length()
    {
        return Math.Sqrt(length_squared());
    }

    [Inline]
    public double length_squared()
    {
        return e[0] * e[0] + e[1] * e[1] + e[2] * e[2];
    }

    [Inline]
    public bool near_zero()
    {
        // Return true if the vector is close to zero in all dimensions.
        let s = 1e-8;
        return (Math.Abs(e[0]) < s) && (Math.Abs(e[1]) < s) && (Math.Abs(e[2]) < s);
    }

    [Inline]
    public static vec3 random()
    {
        return vec3(Rtweekend.random_double(), Rtweekend.random_double(), Rtweekend.random_double());
    }

    [Inline]
    public static vec3 random(double min, double max)
    {
        return vec3(Rtweekend.random_double(min, max), Rtweekend.random_double(min, max), Rtweekend.random_double(min, max));
    }

    public override void ToString(String strBuffer)
    {
        strBuffer.Append(e[0]);
        strBuffer.Append(' ');
        strBuffer.Append(e[1]);
        strBuffer.Append(' ');
        strBuffer.Append(e[2]);
    }

    [Inline]
    public static vec3 operator +(vec3 u, vec3 v)
    {
        return vec3(u.e[0] + v.e[0], u.e[1] + v.e[1], u.e[2] + v.e[2]);
    }

    [Inline]
    public static vec3 operator -(vec3 u, vec3 v)
    {
        return vec3(u.e[0] - v.e[0], u.e[1] - v.e[1], u.e[2] - v.e[2]);
    }

    [Inline]
    public static vec3 operator *(vec3 u, vec3 v)
    {
        return vec3(u.e[0] * v.e[0], u.e[1] * v.e[1], u.e[2] * v.e[2]);
    }

    [Inline]
    public static vec3 operator /(vec3 u, vec3 v)
    {
        return vec3(u.e[0] / v.e[0], u.e[1] / v.e[1], u.e[2] / v.e[2]);
    }

    [Inline, Commutable]
    public static vec3 operator *(vec3 v, double t)
    {
        return vec3(t * v.e[0], t * v.e[1], t * v.e[2]);
    }

    [Inline, Commutable]
    public static vec3 operator /(vec3 v, double t)
    {
        return v * (1 / t);
    }

    [Inline]
    public static double dot(vec3 u, vec3 v)
    {
        return u.e[0] * v.e[0]
            + u.e[1] * v.e[1]
            + u.e[2] * v.e[2];
    }

    [Inline]
    public static vec3 cross(vec3 u, vec3 v)
    {
        return vec3(
            u.e[1] * v.e[2] - u.e[2] * v.e[1],
            u.e[2] * v.e[0] - u.e[0] * v.e[2],
            u.e[0] * v.e[1] - u.e[1] * v.e[0]
            );
    }

    [Inline]
    public static vec3 unit_vector(vec3 v)
    {
        return v / v.length();
    }

    [Inline]
    public static vec3 random_in_unit_disk()
    {
        while (true)
        {
            let p = vec3(Rtweekend.random_double(-1, 1), Rtweekend.random_double(-1, 1), 0);
            if (p.length_squared() < 1)
            {
                return p;
            }
        }
    }

    [Inline]
    public static vec3 random_unit_vector()
    {
        while (true)
        {
            let p = random(-1, 1);
            let lensq = p.length_squared();
            if (1e-160 < lensq && lensq <= 1)
            {
                return p / Math.Sqrt(lensq);
            }
        }
    }

    [Inline]
    public static vec3 random_on_hemisphere(vec3 normal)
    {
        vec3 on_unit_sphere = random_unit_vector();
        if (dot(on_unit_sphere, normal) > 0.0) // In the same hemisphere as the normal
        {
            return on_unit_sphere;
        }
        else
        {
            return -on_unit_sphere;
        }
    }

    [Inline]
    public static vec3 reflect(vec3 v, vec3 n)
    {
        return v - 2 * dot(v, n) * n;
    }

    [Inline]
    public static vec3 refract(vec3 uv, vec3 n, double etai_over_etat)
    {
        let cos_theta = Math.Min(dot(-uv, n), 1.0);
        vec3 r_out_perp =  etai_over_etat * (uv + cos_theta * n);
        vec3 r_out_parallel = -Math.Sqrt(Math.Abs(1.0 - r_out_perp.length_squared())) * n;
        return r_out_perp + r_out_parallel;
    }
}