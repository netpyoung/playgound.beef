using SDL2;

namespace Breakout_Beef.Entities;

class BaseEntity
{
    protected SDL.Renderer* _renderer;
    public float x, y, width, height;


    public this(SDL.Renderer* renderer)
    {
        _renderer = renderer;
        x = 0;
        y = 0;
        width = 1;
        height = 1;
    }

    public bool Collides(BaseEntity other)
    {
        if (x + width > other.x && x < other.x + other.width &&
            y + height > other.y && y < other.y + other.height)
        {
            return true;
        }

        return false;
    }



    public virtual void Update(float delta)
    {
    }


    public virtual void Render(float delta)
    {
    }
}