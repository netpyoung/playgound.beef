using SDL2;
using System;

namespace Breakout_Beef.Entities;

class Ball : BaseEntity
{
    const float BALL_SPEED = 550;

    public float dirx;
    public float diry;
    SDL.Texture* texture;

    public this(SDL.Renderer* renderer) : base(renderer)
    {
        SDL.Surface* surface = SDLImage.Load("res/ball.png");
        texture = SDL.CreateTextureFromSurface(renderer, surface);
        SDL.FreeSurface(surface);

        x = 0;
        y = 0;
        width = 24;
        height = 24;

        SetDirection(1, 1);
    }

    public ~this()
    {
        SDL.DestroyTexture(texture);
    }

    public override void Update(float delta)
    {
        x += dirx * delta;
        y += diry * delta;
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

    public void SetDirection(float x, float y)
    {
        // Normalize the direction vector and multiply with BALL_SPEED
        float length = Math.Sqrt(x * x + y * y);
        dirx = BALL_SPEED * (x / length);
        diry = BALL_SPEED * (y / length);
    }
}