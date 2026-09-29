using SDL2;

namespace Pong_Beef.Entities;

class Board : BaseEntity
{
    public float boundtop, boundbottom;
    SDL.Texture* sidetexture;

    public this(SDL.Renderer* renderer) : base(renderer)
    {
        SDL.Surface* surface = SDLImage.Load("res/side.png");
        sidetexture = SDL.CreateTextureFromSurface(renderer, surface);
        SDL.FreeSurface(surface);

        x = 0;
        y = 0;
        width = 800;
        height = 600;

        // Define bounds
        boundtop = 21;
        boundbottom = 600 - 21;
    }
    public ~this()
    {
        // Clean resources
        SDL.DestroyTexture(sidetexture);
    }

    public override void Render(float delta)
    {
        // Render top and bottom
        SDL.Rect dstrect;
        dstrect.x = 0;
        dstrect.y = 0;
        dstrect.w = 800;
        dstrect.h = 21;
        SDL.RenderCopy(_renderer, sidetexture, null, &dstrect);

        dstrect.x = 0;
        dstrect.y = 600 - 21;
        dstrect.w = 800;
        dstrect.h = 21;
        SDL.RenderCopy(_renderer, sidetexture, null, &dstrect);
    }


}
