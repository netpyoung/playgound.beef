using System;
using Win32.System.SystemInformation;
using Win32.UI.Input.KeyboardAndMouse;
using Win32.System.Console;
using Win32.Foundation;
using Win32.System.SystemInformation;
using System.Diagnostics;

namespace TextGameFramework_Beef;

class Game
{
    public static int g_iCursorPosX = 0;
    public static int g_iCursorPosY = 0;

    public static int g_iScreenWidth = 0;
    public static int g_iScreenHeight = 0;

    char8[] g_pBackBuffer = null;
    char8[] g_pBackground = null;
    char8[] g_pBackgroundLineBuffer = null;

    bool g_bLeftKeyPressed = false;
    bool g_bUpKeyPressed = false;
    bool g_bRightKeyPressed = false;
    bool g_bDownKeyPressed = false;
    bool g_bSpaceKeyPressed = false;
    int g_dwCurScore = 0;

    HANDLE g_hOut = 0;
    int g_dwCurFPS = 0;
    const int g_dwGameFPS = 60;
    const int g_dwTicksPerGameFame = 1000 / g_dwGameFPS;
    uint64 g_PrvGameFrameTick = 0;

    FLIGHT_OBJECT* g_pPlayer = null;

    FLIGHT_OBJECT*[game_typedef.MAX_AMMO_NUM] g_ppAmmoList;
    int g_dwCurAmmoNum = 0;

    FLIGHT_OBJECT*[game_typedef.MAX_ENEMY_NUM] g_ppEnemyList;
    int g_dwCurEnemiesNum = 0;

    static uint64 PrvTick = GetTickCount64();
    static int dwFrameCount = 0;
    static uint64 PrvUpdateTick = 0;

    [CLink]
    public static extern void srand(uint seed);

    [CLink]
    public static extern int rand();

    public bool InitializeGame(HANDLE hOut)
    {
        srand(GetTickCount());

        g_hOut = hOut;
        CONSOLE_SCREEN_BUFFER_INFO info = .();
        GetConsoleScreenBufferInfo(hOut, &info);
        g_iScreenWidth = (int)info.dwSize.X;
        g_iScreenHeight = info.srWindow.Bottom - info.srWindow.Top + 1;


        g_pBackBuffer = new char8[g_iScreenWidth * g_iScreenHeight];
        for (int i = 0; i < (int)(g_iScreenWidth * g_iScreenHeight); i++)
        {
            g_pBackBuffer[i] = '.';
        }
        g_pBackground = new char8[g_iScreenWidth * g_iScreenHeight];
        g_pBackgroundLineBuffer = new char8[g_iScreenWidth];
        for (int i = 0; i < (int)(g_iScreenWidth * g_iScreenHeight); i++)
        {
            g_pBackground[i] = ' ';
        }
        //int dwStartNum = (g_iScreenWidth / 16) * (g_iScreenHeight / 8);
        int dwStartNum = 36;
        for (int i = 0; i < dwStartNum; i++)
        {
            int x = rand() % (g_iScreenWidth / 8) * 8;
            int y = rand() % (g_iScreenHeight / 4) * 4;


            if (x >= g_iScreenWidth)
            {
                Debug.Break();
            }

            if (y >= g_iScreenHeight)
            {
                Debug.Break();
            }

            g_pBackground[x + y * g_iScreenWidth] = '.';
        }

        COORD pos = .();
        uint32 dwWrittenChrs = 0;
        FillConsoleOutputCharacter(hOut, (uint8)'.', (uint32)(g_iScreenWidth * g_iScreenHeight), pos, &dwWrittenChrs);

        g_pPlayer = GameObject.CreatePlayer();


        return true;
    }

    public void GameLoop(out bool outIsExit)
    {
        ProcessInput(out outIsExit);

        uint64 CurTick = GetTickCount64();
        if ((int)(CurTick - g_PrvGameFrameTick) > g_dwTicksPerGameFame)
        {
            OnGameFrame(CurTick);
            g_PrvGameFrameTick = CurTick;
        }
        DrawScene();
    }


    bool ProcessInput(out bool outIsExit)
    {
        outIsExit = false;

        bool bUpdated = false;

        if (GetAsyncKeyState((int32)VIRTUAL_KEY.VK_LEFT) != 0)
        {
            if (!g_bLeftKeyPressed)
            {
                OnKeyDown_Left();
                bUpdated = true;
            }
            g_bLeftKeyPressed = true;
        }
        else
        {
            if (g_bLeftKeyPressed)
            {
                OnKeyUp_Left();
                bUpdated = true;
            }
            g_bLeftKeyPressed = false;
        }
        if (GetAsyncKeyState((int32)VIRTUAL_KEY.VK_RIGHT) != 0)
        {
            if (!g_bRightKeyPressed)
            {
                OnKeyDown_Right();
                bUpdated = true;
            }
            g_bRightKeyPressed = true;
        }
        else
        {
            if (g_bRightKeyPressed)
            {
                OnKeyUp_Right();
                bUpdated = true;
            }
            g_bRightKeyPressed = false;
        }

        if (GetAsyncKeyState((int32)VIRTUAL_KEY.VK_UP) != 0)
        {
            if (!g_bUpKeyPressed)
            {
                OnKeyDown_Up();
                bUpdated = true;
            }
            g_bUpKeyPressed = true;
        }
        else
        {
            if (g_bUpKeyPressed)
            {
                OnKeyUp_Up();
                bUpdated = true;
            }
            g_bUpKeyPressed = false;
        }
        if (GetAsyncKeyState((int32)VIRTUAL_KEY.VK_DOWN) != 0)
        {
            if (!g_bDownKeyPressed)
            {
                OnKeyDown_Down();
                bUpdated = true;
            }
            g_bDownKeyPressed = true;
        }
        else
        {
            if (g_bDownKeyPressed)
            {
                OnKeyUp_Down();
                bUpdated = true;
            }
            g_bDownKeyPressed = false;
        }
        if (GetAsyncKeyState((int32)VIRTUAL_KEY.VK_SPACE) != 0)
        {
            if (!g_bSpaceKeyPressed)
            {
                OnKeyDown_Space();
                bUpdated = true;
            }
            g_bSpaceKeyPressed = true;
        }
        else
        {
            if (g_bSpaceKeyPressed)
            {
                OnKeyUp_Space();
                bUpdated = true;
            }
            g_bSpaceKeyPressed = false;
        }

        if (GetAsyncKeyState((int32)VIRTUAL_KEY.VK_ESCAPE) != 0)
        {
            outIsExit = true;
            bUpdated = true;
        }

        return bUpdated;
    }
    void DrawScene()
    {
        ClearBackBuffer();

        // Draw player
        DrawFlightObject(g_pPlayer, g_pPlayer.x, g_pPlayer.y);

        // Draw Enemies
        for (int i = 0; i < g_dwCurEnemiesNum; i++)
        {
            DrawFlightObject(g_ppEnemyList[i], g_ppEnemyList[i].x, g_ppEnemyList[i].y);
        }

        // Draw ammos
        for (int i = 0; i < g_dwCurAmmoNum; i++)
        {
            DrawFlightObject(g_ppAmmoList[i], g_ppAmmoList[i].x, g_ppAmmoList[i].y);
        }
        DrawFPS(1, 1);
        DrawScore(g_iScreenWidth - 16, 1);

        Blt();
    }
    void DrawFlightObject(FLIGHT_OBJECT* pFighter, int x, int y)
    {
        int dest_start_x = Math.Max(x, 0);
        int dest_start_y = Math.Max(y, 0);
        dest_start_x = Math.Min(dest_start_x, g_iScreenWidth - 1);
        dest_start_y = Math.Min(dest_start_y, g_iScreenHeight - 1);

        int dest_end_x = Math.Max(x + pFighter.Width, 0);
        int dest_end_y = Math.Max(y + pFighter.Height, 0);
        dest_end_x = Math.Min(dest_end_x, g_iScreenWidth);
        dest_end_y = Math.Min(dest_end_y, g_iScreenHeight);

        int width = dest_end_x - dest_start_x;
        int height = dest_end_y - dest_start_y;

        if (width <= 0 || height <= 0)
            return;

        int src_start_x = dest_start_x - x;
        int src_start_y = dest_start_y - y;

        //if (x > g_iScreenWidth - 1)
        //{
        // x = g_iScreenWidth - 1;
        //}
        //if (y > g_iScreenHeight - 1)
        //{
        // y = g_iScreenHeight - 1;
        //}
        //y = 10;
        //g_pBackBuffer[x + y * g_iScreenWidth] = L'x';
        //g_pBackBuffer[dest_start_x + dest_start_y * g_iScreenWidth] = L'x';


        char8* pSrc = pFighter.pBits.Ptr + src_start_x + src_start_y * pFighter.Width;
        char8* pDest = g_pBackBuffer.Ptr + dest_start_x + dest_start_y * g_iScreenWidth;

        for (int yy = 0; yy < height; yy++)
        {
            for (int xx = 0; xx < width; xx++)
            {
                *pDest = *pSrc;
                pSrc++;
                pDest++;
            }
            pSrc -= width;
            pSrc += pFighter.Width;
            pDest -= width;
            pDest += g_iScreenWidth;
        }
    }
    void OnGameFrame(uint64 CurTick)
    {
        if (g_bLeftKeyPressed)
        {
            g_pPlayer.x--;
            if (g_pPlayer.x < 0)
                g_pPlayer.x = 0;
        }
        if (g_bRightKeyPressed)
        {
            g_pPlayer.x++;
            if (g_pPlayer.x > g_iScreenWidth - g_pPlayer.Width)
                g_pPlayer.x = g_iScreenWidth - g_pPlayer.Width;
        }
        if (g_bUpKeyPressed)
        {
            g_pPlayer.y--;
            if (g_pPlayer.y < 0)
                g_pPlayer.y = 0;
        }
        if (g_bDownKeyPressed)
        {
            g_pPlayer.y++;
            if (g_pPlayer.y > g_iScreenHeight - g_pPlayer.Height)
                g_pPlayer.y = g_iScreenHeight - g_pPlayer.Height;
        }

        // 사망한 적들 제거
        DeleteDestroyedEnemies(CurTick);

        ProcessCollision(CurTick);

        // 탄환이 맵 끝에 도달하면 자동 파괴
        int dwIndex = 0;
        while (dwIndex < g_dwCurAmmoNum)
        {
            FLIGHT_OBJECT* pAmmo = g_ppAmmoList[dwIndex];
            if (pAmmo.y < 0)
            {
                GameObject.DeleteFlightObject(pAmmo);
                g_dwCurAmmoNum--;
                g_ppAmmoList[dwIndex] = g_ppAmmoList[g_dwCurAmmoNum];
                g_ppAmmoList[g_dwCurAmmoNum] = null;
            }
            else
            {
                pAmmo.y--;
                dwIndex++;
            }
        }

        ProcessEnemies();

        UpdateBackground();
    }

    void UpdateBackground()
    {
        uint64 CurTick = GetTickCount64();

        if (CurTick - PrvUpdateTick < 1000)
        {
            return;
        }

        PrvUpdateTick = CurTick;

    #unwarn
        int dwTotalPixels = (int)(g_iScreenWidth * g_iScreenHeight);


        char8* pSrc = g_pBackground.Ptr + (g_iScreenHeight - 1) * g_iScreenWidth;
        char8* pDest = g_pBackgroundLineBuffer.Ptr;

        for (int y = 0; y < g_iScreenHeight; y++)
        {
            Internal.MemCpy(pDest, pSrc, sizeof(char8) * g_iScreenWidth);
            pDest = pSrc;
            pSrc -= g_iScreenWidth;
        }

        Internal.MemCpy(g_pBackground.Ptr, g_pBackgroundLineBuffer.Ptr, sizeof(char8) * g_iScreenWidth);
        //memcpy(g_pBackground, g_pBackground + g_iScreenWidth, sizeof(char8) * (dwTotalPixels - (int)g_iScreenWidth));
        //memcpy(g_pBackground + (dwTotalPixels - (int)g_iScreenWidth), g_pBackgroundLineBuffer, sizeof(char8) * g_iScreenWidth);
    }
    void DeleteDestroyedEnemies(uint64 CurTick)
    {
        int dwIndex = 0;
        while (dwIndex < g_dwCurEnemiesNum)
        {
            FLIGHT_OBJECT* pEnemy = g_ppEnemyList[dwIndex];
            if (pEnemy.status == .FLIGHT_OBJECT_STATUS_DEAD && CurTick - pEnemy.DeadTick > game_typedef.DEAD_STATUS_WAIT_TICK)
            {
                GameObject.DeleteFlightObject(pEnemy);
                g_dwCurEnemiesNum--;
                g_ppEnemyList[dwIndex] = g_ppEnemyList[g_dwCurEnemiesNum];
                g_ppEnemyList[g_dwCurEnemiesNum] = null;
            }
            else
            {
                dwIndex++;
            }
        }
    }
    void ProcessCollision(uint64 CurTick)
    {
        int dwIndex = 0;
        while (dwIndex < g_dwCurAmmoNum)
        {
            FLIGHT_OBJECT* pAmmo = g_ppAmmoList[dwIndex];
            if (ProcessCollisionAmmoVsEnemies(pAmmo, CurTick))
            {
                GameObject.DeleteFlightObject(pAmmo);
                g_dwCurAmmoNum--;
                g_ppAmmoList[dwIndex] = g_ppAmmoList[g_dwCurAmmoNum];
                g_ppAmmoList[g_dwCurAmmoNum] = null;
            }
            else
            {
                dwIndex++;
            }
        }
    }

    bool IsCollisionRectVsRect(INT_VECTOR2* pv3MinA,  INT_VECTOR2* pv3MaxA,  INT_VECTOR2* pv3MinB, INT_VECTOR2* pv3MaxB)
    {
        int* a_min = &pv3MinA.x;
        int* a_max = &pv3MaxA.x;
        int* b_min = &pv3MinB.x;
        int* b_max = &pv3MaxB.x;

        for (int i = 0; i < 2; i++)
        {
            if (a_min[i] > b_max[i] || a_max[i] < b_min[i])
            {
                return false;
            }
        }
        return true;
    }
    bool IsCollisionFlightObjectVsFlightObject(FLIGHT_OBJECT* pObj0, FLIGHT_OBJECT* pObj1)
    {
        bool bResult = false;

        if (pObj0.status != .FLIGHT_OBJECT_STATUS_ALIVE || pObj1.status != .FLIGHT_OBJECT_STATUS_ALIVE)
        {
            return false;
        }

        INT_RECT2 objRect0 = INT_RECT2
            {
                min = INT_VECTOR2 { x = pObj0.x, y = pObj0.y },
                max = INT_VECTOR2 { x = pObj0.x + pObj0.Width, y = pObj0.y + pObj0.Height }
            };
        INT_RECT2 objRect1 = INT_RECT2
            {
                min = INT_VECTOR2 { x = pObj1.x, y = pObj1.y },
                max = INT_VECTOR2 { x = pObj1.x + pObj1.Width, y = pObj1.y + pObj1.Height }
            };

        bResult = IsCollisionRectVsRect(&objRect0.min, &objRect0.max, &objRect1.min, &objRect1.max);


        return bResult;
    }
    bool ProcessCollisionAmmoVsEnemies(FLIGHT_OBJECT* pAmmo, uint64 CurTick)
    {
        bool bCollision = false;
        for (int i = 0; i < g_dwCurEnemiesNum; i++)
        {
            FLIGHT_OBJECT* pEnemy = g_ppEnemyList[i];
            if (IsCollisionFlightObjectVsFlightObject(pAmmo, pEnemy))
            {
                // 적 타격 성공
                OnHitEnemy(pEnemy, CurTick);

                bCollision = true;
                break;
            }
        }
        return bCollision;
    }
    void ProcessEnemies()
    {
        // 적이 맵 끝(바닥)에 도달하면 자동파괴
        int dwIndex = 0;
        while (dwIndex < g_dwCurEnemiesNum)
        {
            FLIGHT_OBJECT* pEnemy = g_ppEnemyList[dwIndex];
            if (pEnemy.y >= g_iScreenHeight)
            {
                GameObject.DeleteFlightObject(pEnemy);
                g_dwCurEnemiesNum--;
                g_ppEnemyList[dwIndex] = g_ppEnemyList[g_dwCurEnemiesNum];
                g_ppEnemyList[g_dwCurEnemiesNum] = null;
            }
            else
            {
                dwIndex++;
            }
        }
        MoveEnemies();
        FillEnemies();
    }
    void OnHitEnemy(FLIGHT_OBJECT* pEnemy, uint64 CurTick)
    {
        // 지금 삭제하지 않고 상태만 바꾼다.
        GameObject.ChangeFlightObjectStatusToDead(pEnemy, CurTick);
        AddScore(game_typedef.SCORE_PER_ONE_KILL);
    }
    int AddScore(int dwAddval)
    {
        g_dwCurScore += dwAddval;
        return g_dwCurScore;
    }
    void MoveEnemies()
    {
        static uint64 PrvEnemyMoveTick = 0;
        uint64 CurTick = GetTickCount64();
        if (CurTick - PrvEnemyMoveTick < game_typedef.ENEMY_MOVE_ACTION_DELAY_TICK)
        {
            return;
        }
        PrvEnemyMoveTick = CurTick;

        for (int i = 0; i < g_dwCurEnemiesNum; i++)
        {
            GameObject.MoveEmemy(g_ppEnemyList[i]);
        }
    }

    void FillEnemies()
    {
        static uint64 PrvFillEnemyTick = 0;

        if (g_dwCurEnemiesNum >= game_typedef.MAX_ENEMY_NUM)
        {
            return;
        }

        uint64 CurTick = GetTickCount64();
        if (CurTick - PrvFillEnemyTick < 3000)
        {
            return;
        }
        PrvFillEnemyTick = CurTick;

        int dwNeyEnemyNum = game_typedef.MAX_ENEMY_NUM - g_dwCurEnemiesNum;
        for (int i = 0; i < dwNeyEnemyNum; i++)
        {
            FLIGHT_OBJECT* pEnemy = GameObject.CreateEnemyRandom();
            g_ppEnemyList[g_dwCurEnemiesNum] = pEnemy;
            g_dwCurEnemiesNum++;
        }
    }
    void DeleteAllEnemies()
    {
        for (int i = 0; i < g_dwCurEnemiesNum; i++)
        {
            GameObject.DeleteFlightObject(g_ppEnemyList[i]);
            g_ppEnemyList[i] = null;
        }
        g_dwCurEnemiesNum = 0;
    }
    void DeleteAllAmmos()
    {
        for (int i = 0; i < g_dwCurAmmoNum; i++)
        {
            GameObject.DeleteFlightObject(g_ppAmmoList[i]);
            g_ppAmmoList[i] = null;
        }
        g_dwCurAmmoNum = 0;
    }

    public void CleanupGame()
    {
        DeleteAllEnemies();
        DeleteAllAmmos();
        if (g_pPlayer != null)
        {
            GameObject.DeleteFlightObject(g_pPlayer);
            g_pPlayer = null;
        }
        if (g_pBackBuffer != null)
        {
            delete g_pBackBuffer;
            g_pBackBuffer = null;
        }
        if (g_pBackground != null)
        {
            delete g_pBackground;
            g_pBackground = null;
        }
        if (g_pBackgroundLineBuffer != null)
        {
            delete g_pBackgroundLineBuffer;
            g_pBackgroundLineBuffer = null;
        }
    }
    void OnKeyDown_Left()
    {
    }
    void OnKeyUp_Left()
    {
    }
    void OnKeyDown_Up()
    {
    }
    void OnKeyUp_Up()
    {
    }

    void OnKeyDown_Right()
    {
    }
    void OnKeyUp_Right()
    {
    }

    void OnKeyDown_Down()
    {
    }
    void OnKeyUp_Down()
    {
    }

    void OnKeyDown_Space()
    {
        ShootFromPlayer();
    }

    void OnKeyUp_Space()
    {
    }

    void ShootFromPlayer()
    {
        if (g_dwCurAmmoNum >= game_typedef.MAX_AMMO_NUM)
        {
            return;
        }

        FLIGHT_OBJECT* pAmmo = GameObject.CreateAmmo(g_pPlayer);
        g_ppAmmoList[g_dwCurAmmoNum] = pAmmo;
        g_dwCurAmmoNum++;
    }

    void ClearScreen()
    {
        COORD pos = .();
        uint32 dwWrittenChrs = 0;
        FillConsoleOutputCharacter(g_hOut, (uint8)'\0', (uint32)(g_iScreenWidth * g_iScreenHeight), pos, &dwWrittenChrs);
    }

    void ClearBackBuffer()
    {
        Internal.MemCpy(g_pBackBuffer.Ptr, g_pBackground.Ptr, sizeof(char8) * g_iScreenWidth * g_iScreenHeight);
        //for (int i = 0; i < (int)(g_iScreenWidth * g_iScreenHeight); i++)
        //{
        // g_pBackBuffer[i] = L' ';
        //}
    }


    void Blt()
    {
        dwFrameCount++;

        COORD pos = .();
        uint32 lenout = 0;
        WriteConsoleOutputCharacter(g_hOut, (uint8*)g_pBackBuffer.Ptr, (uint32)(g_iScreenWidth * g_iScreenHeight), pos, &lenout);

        uint64 CurTick = GetTickCount64();
        if (CurTick - PrvTick > 1000)
        {
            UpdateFPS(dwFrameCount);
            dwFrameCount = 0;
            PrvTick = GetTickCount64();
        }
    }
    void UpdateFPS(int dwFPS)
    {
        g_dwCurFPS = dwFPS;
        //char8 wchTxt[32];
        //swprintf_s(wchTxt, L"FPS:%u\n", dwFPS);
        //OutputDebugStringW(wchTxt);
    }
    void DrawCursor()
    {
        COORD pos = COORD { X = (int16)g_iCursorPosX, Y = (int16)g_iCursorPosY };
        uint32 lenout;
        char8* wchTxt = "x";
        WriteConsoleOutputCharacter(g_hOut, (uint8*)wchTxt, 1, pos, &lenout);
    }

    void DrawFPS(int x, int y)
    {
        int dwOffset = x + y * g_iScreenWidth;
        char8* wchDest = g_pBackBuffer.Ptr + dwOffset;
        //int dwDesBufferLen = (int)((g_iScreenWidth * g_iScreenHeight - (int)dwOffset));

        String txt = scope $"FPS: {g_dwCurFPS}";
        Internal.MemCpy(wchDest, txt.Ptr, sizeof(char8) * txt.Length);
    }

    void DrawScore(int x, int y)
    {
        int dwOffset = x + y * g_iScreenWidth;
        char8* wchDest = g_pBackBuffer.Ptr + dwOffset;
        //int dwDesBufferLen = (int)((g_iScreenWidth * g_iScreenHeight - (int)dwOffset));

        String txt = scope $"Score: {g_dwCurScore:00000000}";
        Internal.MemCpy(wchDest, txt.Ptr, sizeof(char8) * txt.Length);
    }
}