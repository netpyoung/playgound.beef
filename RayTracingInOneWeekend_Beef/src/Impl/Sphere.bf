using System;
namespace RayTracingInOneWeekend_Beef.Impl;

class Sphere : IHittable
{
    point3 center;
    double radius;
    IMaterial mat;

    public this(point3 center, double radius, IMaterial mat)
    {
        this.center = center;
        this.radius = Math.Max(0, radius);
        this.mat = mat;
    }

    public ~this()
    {
        delete mat;
    }

    public bool hit(ray r, Interval ray_t, out hit_record rec)
    {
        vec3 oc = center - r.origin();
        let a = r.direction().length_squared();
        let h = vec3.dot(r.direction(), oc);
        let c = oc.length_squared() - radius * radius;

        let discriminant = h * h - a * c;
        if (discriminant < 0)
        {
            rec = .();
            return false;
        }

        let sqrtd = Math.Sqrt(discriminant);

        // Find the nearest root that lies in the acceptable range.
        var root = (h - sqrtd) / a;
        if (!ray_t.surrounds(root))
        {
            root = (h + sqrtd) / a;
            if (!ray_t.surrounds(root))
            {
                rec = .();
                return false;
            }
        }

        rec = ?;
        rec.t = root;
        rec.p = r.at(rec.t);
        rec.normal = (rec.p - center) / radius;
        vec3 outward_normal = (rec.p - center) / radius;
        rec.set_face_normal(r, outward_normal);
        rec.mat = mat;

        return true;
    }
}