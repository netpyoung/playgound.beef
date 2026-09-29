using System;
using Win32.Foundation;
using Win32.System.Console;

namespace TextGameFramework_Beef;

// ref:
//   - https://github.com/megayuchi/TextGameFramework
//   - https://github.com/megayuchi/DebuggingTip/tree/main/CrtCheckMemory/TextGameFramework
//   - https://www.youtube.com/playlist?list=PL00yTT-RECdUXlaWwU8XmI2-hTFTS0NEp

class Program
{
    [CLink]
    public static extern int32 _getch();

    public static void Main()
    {
        HANDLE hOut = GetStdHandle(.STD_OUTPUT_HANDLE);

        Game game = scope Game();
        game.InitializeGame(hOut);
        defer game.CleanupGame();

        while (true)
        {
            game.GameLoop(let isExit);
            if (isExit)
            {
                break;
            }
        }

        Console.WriteLine("The application has been terminated. Press any key.");
        _getch();
    }
}