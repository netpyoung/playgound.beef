using System.Collections;
namespace RayTracingInOneWeekend_Beef.Impl;

class HittableList : IHittable
{
    List<IHittable> objects = new List<IHittable>() ~ DeleteContainerAndItems!(_);

    public this() { }

    public this(IHittable object)
    {
        add(object);
    }

    public void clear() { objects.Clear(); }

    public void add(IHittable object)
    {
        objects.Add(object);
    }

    public bool hit(ray r, Interval ray_t, out hit_record rec)
    {
        bool hit_anything = false;
        var closest_so_far = ray_t.max;

        rec = .();
        for (let object in objects)
        {
            if (object.hit(r, Interval(ray_t.min, closest_so_far), let temp_rec))
            {
                hit_anything = true;
                closest_so_far = temp_rec.t;
                rec = temp_rec;
            }
        }

        return hit_anything;
    }
}