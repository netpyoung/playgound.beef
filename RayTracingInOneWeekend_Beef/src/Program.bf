using System;

using RayTracingInOneWeekend_Beef.Impl;

namespace RayTracingInOneWeekend_Beef;

class Program
{
    public static void Main()
    {
        RedirectToFile f = .("image.ppm");
        defer f.Dispose();

        HittableList world = scope HittableList();

        let ground_material = new Lambertian(color(0.5, 0.5, 0.5));
        world.add(new Sphere(point3(0, -1000, 0), 1000, ground_material));

        for (int a = -11; a < 11; a++)
        {
            for (int b = -11; b < 11; b++)
            {
                let choose_mat = Rtweekend.random_double();
                point3 center = .(a + 0.9 * Rtweekend.random_double(), 0.2, b + 0.9 * Rtweekend.random_double());

                if ((center - point3(4, 0.2, 0)).length() > 0.9)
                {
                    if (choose_mat < 0.8)
                    {
                        // diffuse
                        let albedo = color.random() * color.random();
                        let sphere_material = new Lambertian(albedo);
                        world.add(new Sphere(center, 0.2, sphere_material));
                    } else if (choose_mat < 0.95)
                    {
                        // metal
                        let albedo = color.random(0.5, 1);
                        let fuzz = Rtweekend.random_double(0, 0.5);
                        let sphere_material = new Metal(albedo, fuzz);
                        world.add(new Sphere(center, 0.2, sphere_material));
                    } else
                    {
                        // glass
                        let sphere_material = new Dielectric(1.5);
                        world.add(new Sphere(center, 0.2, sphere_material));
                    }
                }
            }
        }

        let material1 = new Dielectric(1.5);
        world.add(new Sphere(point3(0, 1, 0), 1.0, material1));

        let material2 = new Lambertian(color(0.4, 0.2, 0.1));
        world.add(new Sphere(point3(-4, 1, 0), 1.0, material2));

        let material3 = new Metal(color(0.7, 0.6, 0.5), 0.0);
        world.add(new Sphere(point3(4, 1, 0), 1.0, material3));


        Camera cam = .();
        cam.aspect_ratio      = 16.0 / 9.0;
        //cam.image_width       = 1200;
        //cam.samples_per_pixel = 500;
        //cam.max_depth         = 50;

        cam.image_width       = 240;
        cam.samples_per_pixel = 100;
        cam.max_depth         = 10;

        cam.vfov     = 20;
        cam.lookfrom = point3(13, 2, 3);
        cam.lookat   = point3(0, 0, 0);
        cam.vup      = vec3(0, 1, 0);

        cam.defocus_angle = 0.6;
        cam.focus_dist    = 10.0;

        //cam.render(world);
        cam.renderP6WithThread(world);
    }
}