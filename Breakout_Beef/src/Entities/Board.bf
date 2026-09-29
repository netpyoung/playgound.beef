using SDL2;
using System;

namespace Breakout_Beef.Entities;

struct Brick
{
    public int type;
    public bool state;
}

class Board : BaseEntity
{
    public const int BOARD_WIDTH = 12;
    public const int BOARD_HEIGHT = 12;
    public const int BOARD_BRWIDTH = 64;
    public const int BOARD_BRHEIGHT = 24;

    public float brickoffsetx, brickoffsety;

    public Brick[BOARD_HEIGHT][BOARD_WIDTH] bricks;

    SDL.Texture* bricktexture;
    SDL.Texture* sidetexture;
    Random _rand = new Random(100) ~ delete _;

    public this(SDL.Renderer* renderer) : base(renderer)
    {
        SDL.Surface* surface;
        surface = SDLImage.Load("res/bricks.png");
        bricktexture = SDL.CreateTextureFromSurface(renderer, surface);
        SDL.FreeSurface(surface);

        surface = SDLImage.Load("res/side.png");
        sidetexture = SDL.CreateTextureFromSurface(renderer, surface);
        SDL.FreeSurface(surface);

        x = 16;
        y = 0;
        width = 768;
        height = 600;

        brickoffsetx = 0;
        brickoffsety = 16;
    }

    public ~this()
    {
        // Clean resources
        SDL.DestroyTexture(bricktexture);
        SDL.DestroyTexture(sidetexture);
    }

    public override void Render(float delta)
    {
        // Render bricks
        for (int i = 0; i < BOARD_WIDTH; i++)
        {
            for (int j = 0; j < BOARD_HEIGHT; j++)
            {
                Brick brick = bricks[i][j];

                // Check if the brick exists
                if (!brick.state)
                {
                    continue;
                }

                SDL.Rect srcrect;

                srcrect.x = (int32)((brick.type % 2) * BOARD_BRWIDTH);
                srcrect.y = (int32)((brick.type / 2) * BOARD_BRHEIGHT);
                srcrect.w = BOARD_BRWIDTH;
                srcrect.h = BOARD_BRHEIGHT;

                SDL.Rect dstrect;
                dstrect.x = (int32)(brickoffsetx + x + i * BOARD_BRWIDTH);
                dstrect.y = (int32)(brickoffsety + y + j * BOARD_BRHEIGHT);
                dstrect.w = BOARD_BRWIDTH;
                dstrect.h = BOARD_BRHEIGHT;

                SDL.RenderCopy(_renderer, bricktexture, &srcrect, &dstrect);
            }
        }

        // Render sides
        SDL.Rect dstrect;
        dstrect.x = 0;
        dstrect.y = 0;
        dstrect.w = 16;
        dstrect.h = 600;
        SDL.RenderCopy(_renderer, sidetexture, null, &dstrect);

        dstrect.x = 800 - 16;
        dstrect.y = 0;
        dstrect.w = 16;
        dstrect.h = 600;
        SDL.RenderCopy(_renderer, sidetexture, null, &dstrect);
    }

    public void CreateLevel()
    {
        for (int y = 0; y < BOARD_HEIGHT; y++)
        {
            for (int x = 0; x < BOARD_WIDTH; x++)
            {
                Brick brick;
                brick.type = _rand.NextI32() % 4; // Random color
                //brick.type = (i ^ j) % 4; // Example of a fixed pattern using xor
                brick.state = true; // Brick is present
                bricks[x][y] = brick;
            }
        }
    }
}
