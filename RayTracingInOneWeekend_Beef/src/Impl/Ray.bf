namespace RayTracingInOneWeekend_Beef.Impl;

struct ray
{
    point3 orig;
    vec3 dir;

    public this(point3 origin, vec3 direction)
    {
        this.orig = origin;
        this.dir = direction;
    }

    public point3 origin()  { return orig; }
    public vec3 direction() { return dir; }

    public point3 at(double t)
    {
        return orig + t * dir;
    }
}