using System;
namespace RayTracingInOneWeekend_Beef.Impl;

interface IMaterial
{
    bool scatter(ray r_in, hit_record rec, out color attenuation, out ray scattered);
}

class Lambertian : IMaterial
{
    color albedo;

    public this(color albedo)
    {
        this.albedo = albedo;
    }

    public bool scatter(ray r_in, hit_record rec, out color attenuation, out ray scattered)
    {
        var scatter_direction = rec.normal + vec3.random_unit_vector();
        if (scatter_direction.near_zero())
        {
            scatter_direction = rec.normal;
        }

        scattered = ray(rec.p, scatter_direction);
        attenuation = albedo;
        return true;
    }
}

class Metal : IMaterial
{
    color albedo;
    double fuzz;

    public this(color albedo, double fuzz)
    {
        this.albedo = albedo;
        this.fuzz = fuzz < 1 ? fuzz : 1;
    }

    public bool scatter(ray r_in, hit_record rec, out color attenuation, out ray scattered)
    {
        vec3 reflected = vec3.reflect(r_in.direction(), rec.normal);
        reflected = vec3.unit_vector(reflected) + (fuzz * vec3.random_unit_vector());

        scattered = ray(rec.p, reflected);
        attenuation = albedo;
        return (vec3.dot(scattered.direction(), rec.normal) > 0);
    }
}

class Dielectric : IMaterial
{
    // Refractive index in vacuum or air, or the ratio of the material's refractive index over
    // the refractive index of the enclosing media
    double refraction_index;

    public this(double refraction_index)
    {
        this.refraction_index = refraction_index;
    }

    public bool scatter(ray r_in, hit_record rec, out color attenuation, out ray scattered)
    {
        attenuation = color(1.0, 1.0, 1.0);
        double ri = rec.front_face ? (1.0 / refraction_index) : refraction_index;

        vec3 unit_direction = vec3.unit_vector(r_in.direction());
        double cos_theta = Math.Min(vec3.dot(-unit_direction, rec.normal), 1.0);
        double sin_theta = Math.Sqrt(1.0 - cos_theta * cos_theta);

        bool cannot_refract = ri * sin_theta > 1.0;
        vec3 direction;

        if (cannot_refract || reflectance(cos_theta, ri) > Rtweekend.random_double())
        {
            direction = vec3.reflect(unit_direction, rec.normal);
        }
        else
        {
            direction = vec3.refract(unit_direction, rec.normal, ri);
        }

        scattered = ray(rec.p, direction);
        return true;
    }

    static double reflectance(double cosine, double refraction_index)
    {
        // Use Schlick's approximation for reflectance.
        var r0 = (1 - refraction_index) / (1 + refraction_index);
        r0 = r0 * r0;
        return r0 + (1 - r0) * Math.Pow((1 - cosine), 5);
    }
}
