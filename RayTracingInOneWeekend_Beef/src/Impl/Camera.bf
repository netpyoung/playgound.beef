using System;
using System.Text;
using System.IO;
using System.Threading;
namespace RayTracingInOneWeekend_Beef.Impl;

struct Camera
{
    public double aspect_ratio = 1.0; // Ratio of image width over height
    public int    image_width  = 100; // Rendered image width in pixel count
    public int    samples_per_pixel = 10; // Count of random samples for each pixel
    public int    max_depth         = 10; // Maximum number of ray bounces into scene
    public double vfov = 90; // Vertical view angle (field of view)
    public point3 lookfrom = point3(0, 0, 0); // Point camera is looking from
    public point3 lookat   = point3(0, 0, -1); // Point camera is looking at
    public vec3   vup      = vec3(0, 1, 0); // Camera-relative "up" direction
    public double defocus_angle = 0; // Variation angle of rays through each pixel
    public double focus_dist = 10; // Distance from camera lookfrom point to plane of perfect focus

    int    image_height; // Rendered image height
    double pixel_samples_scale; // Color scale factor for a sum of pixel samples
    point3 center; // Camera center
    point3 pixel00_loc; // Location of pixel 0, 0
    vec3   pixel_delta_u; // Offset to pixel to the right
    vec3   pixel_delta_v; // Offset to pixel below
    vec3   u, v, w; // Camera frame basis vectors
    vec3   defocus_disk_u; // Defocus disk horizontal radius
    vec3   defocus_disk_v; // Defocus disk vertical radius

    public void render(IHittable world) mut
    {
        initialize();

        COUT.WriteLine("P3\n{} {}\n255",  image_width, image_height);
        for (int y = 0; y < image_height; ++y)
        {
            CLOG.WriteLine("\rScanlines remaining: {:0000}",  image_height - y);
            for (int x = 0; x < image_width; ++x)
            {
                color pixel_color = .(0, 0, 0);
                for (int sample = 0; sample < samples_per_pixel; sample++)
                {
                    ray r = get_ray(x, y);
                    pixel_color += ray_color(r, max_depth, world);
                }

                write_color(COUT.Out, pixel_samples_scale * pixel_color);
            }
        }

        CLOG.WriteLine("\r\rDone.                 ");
    }

    void initialize() mut
    {
        image_height = int(image_width / aspect_ratio);
        image_height = (image_height < 1) ? 1 : image_height;

        pixel_samples_scale = 1.0 / samples_per_pixel;

        center = lookfrom;

        // Determine viewport dimensions.
        let theta = Rtweekend.degrees_to_radians(vfov);
        let h = Math.Tan(theta / 2);
        let viewport_height = 2 * h * focus_dist;
        let viewport_width = viewport_height * (double(image_width) / image_height);

        // Calculate the u,v,w unit basis vectors for the camera coordinate frame.
        w = vec3.unit_vector(lookfrom - lookat);
        u = vec3.unit_vector(vec3.cross(vup, w));
        v = vec3.cross(w, u);

        // Calculate the vectors across the horizontal and down the vertical viewport edges.
        vec3 viewport_u = viewport_width * u; // Vector across viewport horizontal edge
        vec3 viewport_v = viewport_height * -v; // Vector down viewport vertical edge

        // Calculate the horizontal and vertical delta vectors from pixel to pixel.
        pixel_delta_u = viewport_u / image_width;
        pixel_delta_v = viewport_v / image_height;

        // Calculate the location of the upper left pixel.
        let viewport_upper_left = center - (focus_dist * w) - viewport_u / 2 - viewport_v / 2;
        pixel00_loc = viewport_upper_left + 0.5 * (pixel_delta_u + pixel_delta_v);

        // Calculate the camera defocus disk basis vectors.
        let defocus_radius = focus_dist * Math.Tan(Rtweekend.degrees_to_radians(defocus_angle / 2));
        defocus_disk_u = u * defocus_radius;
        defocus_disk_v = v * defocus_radius;
    }

    ray get_ray(int i, int j)
    {
        // Construct a camera ray originating from the defocus disk and directed at a randomly
        // sampled point around the pixel location i, j.

        let offset = sample_square();
        let pixel_sample = pixel00_loc
            + ((i + offset.x) * pixel_delta_u)
            + ((j + offset.y) * pixel_delta_v);

        let ray_origin = (defocus_angle <= 0) ? center : defocus_disk_sample();
        let ray_direction = pixel_sample - ray_origin;

        return ray(ray_origin, ray_direction);
    }

    [Inline]
    vec3 sample_square()
    {
        // Returns the vector to a random point in the [-.5,-.5]-[+.5,+.5] unit square.
        return vec3(Rtweekend.random_double() - 0.5, Rtweekend.random_double() - 0.5, 0);
    }

    [Inline]
    point3 defocus_disk_sample()
    {
        // Returns a random point in the camera defocus disk.
        let p = vec3.random_in_unit_disk();
        return center + (p[0] * defocus_disk_u) + (p[1] * defocus_disk_v);
    }

    static color ray_color(ray r, int depth, IHittable world)
    {
         // If we've exceeded the ray bounce limit, no more light is gathered.
        if (depth <= 0)
        {
            return color(0, 0, 0);
        }

        if (world.hit(r, Interval(0.001, double.MaxValue), let rec))
        {
            if (rec.mat.scatter(r, rec, let attenuation, let scattered))
            {
                return attenuation * ray_color(scattered, depth - 1, world);
            }
            return color(0, 0, 0);
        }

        vec3 unit_direction = vec3.unit_vector(r.direction());
        let a = 0.5 * (unit_direction.y + 1.0);
        return (1.0 - a) * color(1.0, 1.0, 1.0) + a * color(0.5, 0.7, 1.0);
    }


    // ================================================================
    [CRepr, Ordered, Packed]
    struct rgb
    {
        public uint8 r;
        public uint8 g;
        public uint8 b;
        public this(uint8 r, uint8 g, uint8 b)
        {
            this.r = r;
            this.g = g;
            this.b = b;
        }
    }

    volatile uint32 remaining;
    public void renderP6WithThread(IHittable world) mut
    {
        initialize();

        var outBuff = new rgb[image_width * image_height];
        defer delete outBuff;

        int32 useThreadCount = 4;

        //ThreadPool.[Friend]sWorkerThreadStats.mMax = useThreadCount;

        int quot = image_height / useThreadCount;
        int rem = image_height % useThreadCount;
        int count = quot;
        if (rem > 0)
        {
            count += 1;
        }

        remaining = (uint32)useThreadCount;
        var doneEvent = scope WaitEvent();

        for (int i = 0; i < useThreadCount; i++)
        {
            int from = i * count;
            int to = Math.Min((i + 1) * count, image_height);
            ThreadPool.QueueUserWorkItem(new [?] () =>
                {
                    for (int y = from; y < to; ++y)
                    {
                        renderRow(ref this, y, world, outBuff);
                        CLOG.Write(".");
                    }

                    if (Interlocked.Decrement(ref remaining) == 0)
                    {
                        doneEvent.Set();
                    }
                });
        }

        doneEvent.WaitFor();

        COUT.WriteLine("P6\n{} {}\n255",  image_width, image_height);
        Span<uint8> span = .((uint8*)outBuff.Ptr, outBuff.Count * 3);
        COUT.mOut.Write(span);

        CLOG.WriteLine("\r\rDone.                 ");
    }

    [Inline]
    static void renderRow(ref Camera camera, int y, IHittable world, rgb[] outBuff)
    {
        var rgbBuff = Span<rgb>(outBuff, y * camera.image_width);
        for (let x in 0 ..< camera.image_width)
        {
            color pixel_color = .(0, 0, 0);
            for (int sample = 0; sample < camera.samples_per_pixel; sample++)
            {
                ray r = camera.get_ray(x, y);
                pixel_color += ray_color(r, camera.max_depth, world);
            }

            let rgb = to_rgb(camera.pixel_samples_scale * pixel_color);
            rgbBuff[x] = rgb;
        }
    }

    static rgb to_rgb(color pixel_color)
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
        uint8 rbyte = uint8(255.999 * intensity.clamp(r));
        uint8 gbyte = uint8(255.999 * intensity.clamp(g));
        uint8 bbyte = uint8(255.999 * intensity.clamp(b));

        return .(rbyte, gbyte, bbyte);
    }
}