using System;

namespace Pong_Beef;

// ref: https://rembound.com/articles/porting-pong-from-flash-to-cpp

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