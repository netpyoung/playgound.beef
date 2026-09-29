using System;
using System.Collections;
using SDL2;
using Breakout_Beef.Entities;

namespace Breakout_Beef;

class Game
{
    const int FPS_DELAY = 500;

    SDL.Window* window;
    SDL.Renderer* renderer;

    // Timing
    uint lasttick, fpstick, fps, framecount;

    // Test
    float testx, testy;

    Board board;
    Paddle paddle;
    Ball ball;
    bool paddlestick;

    public bool Init()
    {
        SDL.Init(.Video);
        window = SDL.CreateWindow("Breakout example", .Centered, .Centered, 800, 600, .Shown);
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
        String buf = scope String(100);

        board = scope Board(renderer);
        paddle = scope Paddle(renderer);
        ball = scope Ball(renderer);

        NewGame();

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

                if (e.type == .KeyDown)
                {
                    if (e.key.keysym.scancode == .Escape)
                    {
                        break;
                    }
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
                buf.AppendF("Breakout Example - (fps: {})", fps);
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
        board.CreateLevel();
        ResetPaddle();
    }

    void ResetPaddle()
    {
        paddlestick = true;
        StickBall();
    }

    void StickBall()
    {
        ball.x = paddle.x + paddle.width / 2 - ball.width / 2;
        ball.y = paddle.y - ball.height;
    }

    void Update(float delta)
    {
         // Game logic

        // Input
        int32 mx, my;
        uint32 mstate = SDL.GetMouseState(out mx, out my);
        SetPaddleX(mx - paddle.width / 2.0f);

        if (mstate & SDL.BUTTON(1) != 0)
        {
            if (paddlestick)
            {
                paddlestick = false;
                ball.SetDirection(1, -1);
            }
        }

        if (paddlestick)
        {
            StickBall();
        }

        CheckBoardCollisions();
        CheckPaddleCollisions();
        CheckBrickCollisions2();

        if (GetBrickCount() == 0)
        {
            NewGame();
        }

        board.Update(delta);
        paddle.Update(delta);

        if (!paddlestick)
        {
            ball.Update(delta);
        }
    }

    void SetPaddleX(float x)
    {
        float newx;
        if (x < board.x)
        {
            // Upper bound
            newx = board.x;
        }
        else if (x + paddle.width > board.x + board.width)
        {
            // Lower bound
            newx = board.x + board.width - paddle.width;
        }
        else
        {
            newx = x;
        }
        paddle.x = newx;
    }

    void CheckBoardCollisions()
    {
        // Top and bottom collisions
        if (ball.y < board.y)
        {
            // Top
            // Keep the ball within the board and reflect the y-direction
            ball.y = board.y;
            ball.diry *= -1;
        }
        else if (ball.y + ball.height > board.y + board.height)
        {
            // Bottom
    
            // Ball lost
            ResetPaddle();
        }

        // Left and right collisions
        if (ball.x <= board.x)
        {
            // Left
            // Keep the ball within the board and reflect the x-direction
            ball.x = board.x;
            ball.dirx *= -1;
        }
        else if (ball.x + ball.width >= board.x + board.width)
        {
            // Right
            // Keep the ball within the board and reflect the x-direction
            ball.x = board.x + board.width - ball.width;
            ball.dirx *= -1;
        }
    }

    float GetReflection(float x)
    {
        // Make sure the hitx variable is within the width of the paddle
        float hitx = x;
        if (hitx < 0)
        {
            hitx = 0;
        }
        else if (hitx > paddle.width)
        {
            hitx = paddle.width;
        }

        // Everything to the left of the center of the paddle is reflected to the left
        // while everything right of the center is reflected to the right
        hitx -= paddle.width / 2.0f;

        // Scale the reflection, making it fall in the range -2.0f to 2.0f
        return 2.0f * (hitx / (paddle.width / 2.0f));
    }


    void CheckPaddleCollisions()
    {
        // Get the center x-coordinate of the ball
        float ballcenterx = ball.x + ball.width / 2.0f;

        // Check paddle collision
        if (ball.Collides(paddle))
        {
            ball.y = paddle.y - ball.height;
            ball.SetDirection(GetReflection(ballcenterx - paddle.x), -1);
            //ball.SetDirection(0, -1);
        }
    }

    void CheckBrickCollisions()
    {
        for (int i = 0; i < Board.BOARD_WIDTH; i++)
        {
            for (int j = 0; j < Board.BOARD_HEIGHT; j++)
            {
                Brick brick = board.bricks[i][j];

                // Check if brick is present
                if (brick.state)
                {
                    // Brick x and y coordinates
                    float brickx = board.brickoffsetx + board.x + i * Board.BOARD_BRWIDTH;
                    float bricky = board.brickoffsety + board.y + j * Board.BOARD_BRHEIGHT;

                    // Check ball-brick collision
                    // Determine the collision using the half-widths of the rectangles
                    // http://stackoverflow.com/questions/16198437/minkowski-sum-for-rectangle-intersection-calculation
                    // http://gamedev.stackexchange.com/questions/29786/a-simple-2d-rectangle-collision-algorithm-that-also-determines-which-sides-that
                    // http://gamedev.stackexchange.com/questions/24078/which-side-was-hit/24091#24091
                    float w = 0.5f * (ball.width + Board.BOARD_BRWIDTH);
                    float h = 0.5f * (ball.height + Board.BOARD_BRHEIGHT);
                    float dx = (ball.x + 0.5f * ball.width) - (brickx + 0.5f * Board.BOARD_BRWIDTH);
                    float dy = (ball.y + 0.5f * ball.height) - (bricky + 0.5f * Board.BOARD_BRHEIGHT);

                    if (Math.Abs(dx) <= w && Math.Abs(dy) <= h)
                    {
                        // Collision detected
                        board.bricks[i][j].state = false;

                        float wy = w * dy;
                        float hx = h * dx;

                        if (wy > hx)
                        {
                            if (wy > -hx)
                            {
                                // Bottom (y is flipped)
                                BallBrickResponse(3);
                            }
                            else
                            {
                                // Left
                                BallBrickResponse(0);
                            }
                        }
                        else
                        {
                            if (wy > -hx)
                            {
                                // Right
                                BallBrickResponse(2);
                            }
                            else
                            {
                                // Top (y is flipped)
                                BallBrickResponse(1);
                            }
                        }
                        return;
                    }
                }
            }
        }
    }

    void CheckBrickCollisions2()
    {
        for (int i = 0; i < Board.BOARD_WIDTH; i++)
        {
            for (int j = 0; j < Board.BOARD_HEIGHT; j++)
            {
                Brick brick = board.bricks[i][j];

                // Check if brick is present
                if (brick.state)
                {
                    // Brick x and y coordinates
                    float brickx = board.brickoffsetx + board.x + i * Board.BOARD_BRWIDTH;
                    float bricky = board.brickoffsety + board.y + j * Board.BOARD_BRHEIGHT;

                    // Center of the ball x and y coordinates
                    float ballcenterx = ball.x + 0.5f * ball.width;
                    float ballcentery = ball.y + 0.5f * ball.height;

                    // Center of the brick x and y coordinates
                    float brickcenterx = brickx + 0.5f * Board.BOARD_BRWIDTH;
                    float brickcentery = bricky + 0.5f * Board.BOARD_BRHEIGHT;

                    if (ball.x <= brickx + Board.BOARD_BRWIDTH && ball.x + ball.width >= brickx && ball.y <= bricky + Board.BOARD_BRHEIGHT && ball.y + ball.height >= bricky)
                    {
                        // Collision detected, remove the brick
                        board.bricks[i][j].state = false;

                        // Asume the ball goes slow enough to not skip through the bricks

                        // Calculate ysize
                        float ymin = 0;
                        if (bricky > ball.y)
                        {
                            ymin = bricky;
                        }
                        else
                        {
                            ymin = ball.y;
                        }

                        float ymax = 0;
                        if (bricky + Board.BOARD_BRHEIGHT < ball.y + ball.height)
                        {
                            ymax = bricky + Board.BOARD_BRHEIGHT;
                        }
                        else
                        {
                            ymax = ball.y + ball.height;
                        }

                        float ysize = ymax - ymin;

                        // Calculate xsize
                        float xmin = 0;
                        if (brickx > ball.x)
                        {
                            xmin = brickx;
                        }
                        else
                        {
                            xmin = ball.x;
                        }

                        float xmax = 0;
                        if (brickx + Board.BOARD_BRWIDTH < ball.x + ball.width)
                        {
                            xmax = brickx + Board.BOARD_BRWIDTH;
                        }
                        else
                        {
                            xmax = ball.x + ball.width;
                        }

                        float xsize = xmax - xmin;

                        // The origin is at the top-left corner of the screen!
                        // Set collision response
                        if (xsize > ysize)
                        {
                            if (ballcentery > brickcentery)
                            {
                                // Bottom
                                ball.y += ysize + 0.01f; // Move out of collision
                                BallBrickResponse(3);
                            }
                            else
                            {
                                // Top
                                ball.y -= ysize + 0.01f; // Move out of collision
                                BallBrickResponse(1);
                            }
                        }
                        else
                        {
                            if (ballcenterx < brickcenterx)
                            {
                                // Left
                                ball.x -= xsize + 0.01f; // Move out of collision
                                BallBrickResponse(0);
                            }
                            else
                            {
                                // Right
                                ball.x += xsize + 0.01f; // Move out of collision
                                BallBrickResponse(2);
                            }
                        }

                        return;
                    }
                }
            }
        }
    }

    void BallBrickResponse(int dirindex)
    {
        // dirindex 0: Left, 1: Top, 2: Right, 3: Bottom

        // Direction factors
        int mulx = 1;
        int muly = 1;

        if (ball.dirx > 0)
        {
            // Ball is moving in the positive x direction
            if (ball.diry > 0)
            {
                // Ball is moving in the positive y direction
                // +1 +1
                if (dirindex == 0 || dirindex == 3)
                {
                    mulx = -1;
                }
                else
                {
                    muly = -1;
                }
            }
            else if (ball.diry < 0)
            {
                // Ball is moving in the negative y direction
                // +1 -1
                if (dirindex == 0 || dirindex == 1)
                {
                    mulx = -1;
                }
                else
                {
                    muly = -1;
                }
            }
        }
        else if (ball.dirx < 0)
        {
            // Ball is moving in the negative x direction
            if (ball.diry > 0)
            {
                // Ball is moving in the positive y direction
                // -1 +1
                if (dirindex == 2 || dirindex == 3)
                {
                    mulx = -1;
                }
                else
                {
                    muly = -1;
                }
            }
            else if (ball.diry < 0)
            {
                // Ball is moving in the negative y direction
                // -1 -1
                if (dirindex == 1 || dirindex == 2)
                {
                    mulx = -1;
                } else
                {
                    muly = -1;
                }
            }
        }

        // Set the new direction of the ball, by multiplying the old direction
        // with the determined direction factors
        ball.SetDirection(mulx * ball.dirx, muly * ball.diry);
    }

    int GetBrickCount()
    {
        int brickcount = 0;
        for (int i = 0; i < Board.BOARD_WIDTH; i++)
        {
            for (int j = 0; j < Board.BOARD_HEIGHT; j++)
            {
                Brick brick = board.bricks[i][j];
                if (brick.state)
                {
                    brickcount++;
                }
            }
        }

        return brickcount;
    }

    void Render(float delta)
    {
        SDL.RenderClear(renderer);

        board.Render(delta);
        paddle.Render(delta);
        ball.Render(delta);

        SDL.RenderPresent(renderer);
    }

}