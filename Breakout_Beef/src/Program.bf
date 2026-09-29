using System;

namespace Breakout_Beef;

// ref: https://rembound.com/articles/the-breakout-tutorial-with-cpp-and-sdl-2

class Program
{
    public static void Main()
    {
        Game game = scope Game();
        if (game.Init())
        {
            game.Run();
        }
    }
}