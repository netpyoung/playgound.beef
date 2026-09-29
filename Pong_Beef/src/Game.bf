using System;
using System.Collections;
using SDL2;
using Pong_Beef.Entities;

namespace Pong_Beef;

class Game
{
    const int FPS_DELAY = 500;
    const int AI_SPEED = 400; // Pixels per second

    SDL.Window* window;
    SDL.Renderer* renderer;

    // Timing
    uint lasttick;
    uint fpstick;
    uint fps;
    uint framecount;

    Board board;
    Paddle[2] paddles;
    Ball ball;

    public bool Init()
    {
        SDL.Init(.Video);
        window = SDL.CreateWindow("Pong example", .Centered, .Centered, 800, 600, .Shown);
        if (window == null)
        {
            return false;
        }

        renderer = SDL.CreateRenderer(window, -1, .Accelerated);
        if (renderer == null)
        {
            return false;
        }

        lasttick = SDL.GetTicks();
        fpstick = lasttick;
        fps = 0;
        framecount = 0;

        return true;
    }

    void Clean()
    {
        SDL.DestroyRenderer(renderer);
        renderer = null;

        SDL.DestroyWindow(window);
        window = null;
    }

    public void Run()
    {
        board = scope Board(renderer);
        ball = scope Ball(renderer);

        paddles[0] = scope Paddle(renderer);
        paddles[1] = scope Paddle(renderer);

        NewGame();

        String buf = scope String(100);

        // Main loop
        while (true)
        {
            // Handler events
            SDL.Event e = ?;
            if (SDL.PollEvent(out e) != 0)
            {
                if (e.type == .Quit)
                {
                    break;
                }
            }

            // Calculate delta and fps
            uint32 curtick = SDL.GetTicks();
            float delta = (curtick - lasttick) / 1000.0f;
            if ((curtick - fpstick) >= FPS_DELAY)
            {
                fps = (uint)(framecount * (1000.0f / (curtick - fpstick)));
                fpstick = curtick;
                framecount = 0;

                buf.Clear();
                buf.AppendF("Pong Example - (fps: {})", fps);
                buf.EnsureNullTerminator();
                SDL.SetWindowTitle(window, buf);
            }
            else
            {
                framecount++;
            }
            lasttick = curtick;

            // Update and render the game
            Update(delta);
            Render(delta);
        }

        Clean();

        SDL.Quit();
    }

    void NewGame()
    {
        SetPaddleY(0, board.height / 2 - paddles[0].height / 2);
        SetPaddleY(1, board.height / 2 - paddles[1].height / 2);

        // Set the paddle x
        paddles[0].x = 12;
        paddles[1].x = board.width - paddles[1].width - 12;

        // Center the ball horizontally and vertically
        ball.x = board.width / 2 - ball.width / 2;
        ball.y = board.height / 2 - ball.height / 2;

        // Set the initial direction of the ball
        ball.SetDirection(1, -1);
    }

    void Update(float delta)
    {
        int32 mx, my;
        SDL.GetMouseState(out mx, out my);

        // Move the paddle with the mouse
        SetPaddleY(0, my - paddles[0].height / 2.0f);

        // Check collisions and perform AI
        CheckCollisions();
        AI(delta);

        // Update board and ball
        board.Update(delta);
        ball.Update(delta);

        // Update paddles
        for (int i = 0; i < paddles.Count; i++)
        {
            paddles[i].Update(delta);
        }
    }

    void Render(float delta)
    {
        SDL.SetRenderDrawColor(renderer, 0, 0, 0, 255);
        SDL.RenderClear(renderer);

        // Render board and ball
        board.Render(delta);
        ball.Render(delta);

        // Render paddles
        for (int i = 0; i < paddles.Count; i++)
        {
            paddles[i].Render(delta);
        }

        // Update the screen
        SDL.RenderPresent(renderer);
    }

    void SetPaddleY(int index, float y)
    {
        float newy;
        if (y < board.boundtop)
        {
            // Top bound
            newy = board.boundtop;
        }
        else if ((y + paddles[index].height) > board.boundbottom)
        {
            // Bottom bound
            newy = board.boundbottom - paddles[index].height;
        }
        else
        {
            // Within bounds
            newy = y;
        }

        // Set the new y
        paddles[index].y = newy;
    }

    void CheckCollisions()
    {
        if (ball.y < board.boundtop)
        {
            ball.y = board.boundtop;
            ball.SetDirection(ball.dirx, -1 * ball.diry);
        }
        else if (ball.y + ball.height > board.boundbottom)
        {
            ball.y = board.boundbottom - ball.height;
            ball.SetDirection(ball.dirx, -1 * ball.diry);
        }

        // Left paddle collisions
        if (ball.Collides(paddles[0]))
        {
            ball.x = paddles[0].x + paddles[0].width;
            ball.SetDirection(1, GetReflection(0, (ball.y + ball.height / 2) - paddles[0].y));
        }

        // Right paddle collisions
        if (ball.Collides(paddles[1]))
        {
            ball.x = paddles[1].x - ball.width;
            ball.SetDirection(-1, GetReflection(1, (ball.y + ball.height / 2) - paddles[1].y));
        }

        // Check if ball is off the screen
        if (ball.x + ball.width <= board.x)
        {
            // Player 2 scores
    
            // Center the ball vertically on the side of player 2
            ball.x = board.width / 2 - ball.width / 2 + 250;
            ball.y = board.height / 2 - ball.height / 2;

            ball.SetDirection(-1, -1);
        }
        else if (ball.x >= board.x + board.width)
        {
            // Player 1 scores
    
            // Center the ball vertically on the side of player 1
            ball.x = board.width / 2 - ball.width / 2 - 250;
            ball.y = board.height / 2 - ball.height / 2;

            ball.SetDirection(1, -1);
        }
    }

    float GetReflection(int index, float y)
    {
         // Make sure the hity variable is within the height of the paddle
        float hity = y;
        if (hity < 0)
        {
            hity = 0;
        }
        else if (hity > paddles[index].height)
        {
            hity = paddles[index].height;
        }

        // Everything above the center of the paddle is reflected upward
        // while everything below the center is reflected downward
        hity -= paddles[index].height / 2.0f;

        // Scale the reflection, making it fall in the range -2.0f to 2.0f
        return 2.0f * (hity / (paddles[index].height / 2.0f));
    }

    void AI(float delta)
    {
        float dy = AI_SPEED * delta;

        // Imperfect ai
        if (ball.x > board.width / 2 && ball.dirx > 0)
        {
            // Lag behind the ball, when ball is in sight
            if (paddles[1].y + paddles[1].height / 2 < ball.y + ball.height / 2 - dy)
            {
                SetPaddleY(1, paddles[1].y + dy);
            }
            else if (paddles[1].y + paddles[1].height / 2 > ball.y + ball.height / 2 + dy)
            {
                SetPaddleY(1, paddles[1].y - dy);
            }
        }
        else
        {
            // Move to the center, when ball is far away
            if (paddles[1].y + paddles[1].height / 2 < board.height / 2 - dy)
            {
                SetPaddleY(1, paddles[1].y + dy);
            }
            else if (paddles[1].y + paddles[1].height / 2 > board.height / 2 + dy)
            {
                SetPaddleY(1, paddles[1].y - dy);
            }
        }
    }

}