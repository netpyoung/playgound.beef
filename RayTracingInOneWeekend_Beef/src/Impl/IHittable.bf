namespace RayTracingInOneWeekend_Beef.Impl;


struct hit_record
{
    public point3 p;
    public vec3 normal;
    public IMaterial mat;
    public double t;

    public bool front_face;

    public void set_face_normal(ray r, vec3 outward_normal) mut
    {
        front_face = vec3.dot(r.direction(), outward_normal) < 0;
        normal = front_face ? outward_normal : -outward_normal;
    }
}

interface IHittable
{
    bool hit(ray r, Interval ray_t, out hit_record rec);
}
