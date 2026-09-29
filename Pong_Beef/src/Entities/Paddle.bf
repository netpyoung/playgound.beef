using SDL2;

namespace Pong_Beef.Entities;

class Paddle : BaseEntity
{
    SDL.Texture* texture;

    public this(SDL.Renderer* renderer) : base(renderer)
    {
        SDL.Surface* surface = SDLImage.Load("res/paddle.png");
        texture = SDL.CreateTextureFromSurface(renderer, surface);
        SDL.FreeSurface(surface);

        width = 32;
        height = 128;

        x = 0;
        y = 0;
    }

    public ~this()
    {
        SDL.DestroyTexture(texture);
    }

    public override void Render(float delta)
    {
        SDL.Rect rect;
        rect.x = (int32)(x + 0.5f); // Round the float to the nearest integer
        rect.y = (int32)(y + 0.5f); // Round the float to the nearest integer
        rect.w = (int32)width;
        rect.h = (int32)height;
        SDL.RenderCopy(_renderer, texture, null, &rect);
    }
}