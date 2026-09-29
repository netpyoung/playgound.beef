using Win32.UI.WindowsAndMessaging;
using Win32.Foundation;
using Win32.Graphics.Gdi;
using Win32.System.SystemInformation;
using Win32.UI.Input.KeyboardAndMouse;
using System;
using PixelHorizon_Beef.Common;
using PixelHorizon_Beef.DDrawLib;
using PixelHorizon_Beef.ImageData;
using PixelHorizon_Beef.Utils;
using System.IO;

namespace PixelHorizon_Beef.Game;

class Game
{
    public readonly GameClock gameClock = new GameClock() ~ delete _;

    DDrawDevice m_pDDraw = new DDrawDevice() ~ delete _;
    HWND m_hWnd;
    int m_dwGameFPS = 60;
    int m_dwCurFPS = 0;
    float m_fTicksPerGameFrame = 16.6f;
    uint64 m_PrvGameFrameTick = 0;
    LARGE_INTEGER m_PrvCounter = .();

    ImageData m_pPlayerImgData;
    ImageData m_pAmmoImgData;
    ImageData m_pEnemyImgData;
    ImageData m_pMidScrollImageData = null;
    TGAImage m_pMidScrollImage = null;
    uint32 m_dwMidScrollImageColorKey = 0;
    TGAImage m_pBackImage = null;

    int32 m_iCursorPosX = 0;
    int32 m_iCursorPosY = 0;

    int32 m_iBackImagePosX = 0;
    int32 m_iBackImagePosY = 0;

    int32 m_iMidScrollImagePosX = 0;
    int32 m_iMidScrollImagePosY = 0;

    bool m_bKeyDown_Up = false;
    bool m_bKeyDown_Down = false;
    bool m_bKeyDown_Left = false;
    bool m_bKeyDown_Right = false;

    FlightObject m_pPlayer = null;
    FlightObject[MAX_AMMO_NUM] m_ppAmmoList;
    uint32 m_dwCurAmmoNum = 0;

    FlightObject[MAX_ENEMY_NUM] m_ppEnemyList;
    uint32 m_dwCurEnemiesNum = 0;


    public bool IsInitialized { get; private set; }
    public this()
    {
        m_dwCurFPS = 0;
        m_fTicksPerGameFrame = 1000.0f / (float)m_dwGameFPS;
        m_PrvGameFrameTick = GetTickCount64();
    }

    public ~this()
    {
        Cleanup();
    }

    void Cleanup()
    {
        DeleteAllEnemies();
        DeleteAllAmmos();

        if (m_pPlayer != null)
        {
            GameObject.DeleteFlightObject(m_pPlayer);
            m_pPlayer = null;
        }
        DeleteAndNullify!(m_pMidScrollImage);
        DeleteAndNullify!(m_pPlayerImgData);
        DeleteAndNullify!(m_pAmmoImgData);
        DeleteAndNullify!(m_pEnemyImgData);
        DeleteAndNullify!(m_pBackImage);
        DeleteAndNullify!(m_pMidScrollImageData);
    }

    void DeleteAllEnemies()
    {
        for (int i = 0; i < m_dwCurEnemiesNum; i++)
        {
            GameObject.DeleteFlightObject(m_ppEnemyList[i]);
            m_ppEnemyList[i] = null;
        }
        m_dwCurEnemiesNum = 0;
    }

    void DeleteAllAmmos()
    {
        for (int i = 0; i < m_dwCurAmmoNum; i++)
        {
            GameObject.DeleteFlightObject(m_ppAmmoList[i]);
            m_ppAmmoList[i] = null;
        }
        m_dwCurAmmoNum = 0;
    }

    [NoDiscard]
    public bool Initialize(HWND hwnd)
    {
        m_hWnd = hwnd;
        if (!m_pDDraw.InitializeDDraw(hwnd))
        {
            return false;
        }

        Util.Interop.srand(GetTickCount64());

        TGAImage playerImage = scope TGAImage();
        if (playerImage.Load24BitsTGA("./data/galaga_player.tga", 4))
        {
            uint32 dwPlayerColorKey = playerImage.GetPixel(0, 0);
            m_pPlayerImgData = new ImageData();
            m_pPlayerImgData.Create(playerImage.GetRawImage(), playerImage.GetWidth(), playerImage.GetHeight(), dwPlayerColorKey);
        }

        TGAImage pAmmoImage = scope TGAImage();
        if (pAmmoImage.Load24BitsTGA("./data/ammo.tga", 4))
        {
            uint32 dwAmmoColorKey = pAmmoImage.GetPixel(0, 0);
            m_pAmmoImgData = new ImageData();
            m_pAmmoImgData.Create(pAmmoImage.GetRawImage(), pAmmoImage.GetWidth(), pAmmoImage.GetHeight(), dwAmmoColorKey);
        }
        TGAImage pEnemyImage = scope TGAImage();
        if (pEnemyImage.Load24BitsTGA("./data/galaga_enemy.tga", 4))
        {
            uint32 dwEnemyColorKey = pEnemyImage.GetPixel(5, 0);
            m_pEnemyImgData = new ImageData();
            m_pEnemyImgData.Create(pEnemyImage.GetRawImage(), pEnemyImage.GetWidth(), pEnemyImage.GetHeight(), dwEnemyColorKey);
        }


        //CImageData* m_pEnemyImgData = nullptr;
        //m_pCircleImage = new CTGAImage;;
        //m_pCircleImage.Load24BitsTGA("./data/circle.tga", 4);
        //m_dwCircleColorKey = m_pCircleImage.GetPixel(0, 0);
        //m_pCircleImgData = new CImageData;
        //m_pCircleImgData.Create(m_pCircleImage.GetRawImage(), m_pCircleImage.GetWidth(), m_pCircleImage.GetHeight(), m_dwCircleColorKey);

        // 중간 스크롤 이미지
        m_pMidScrollImage = new TGAImage(); // 속도비교를 위해서 미드스크롤 이미지는 원본 이미지도 보관해둠.
        if (m_pMidScrollImage.Load24BitsTGA("./data/mid_scroll_image.tga", 4))
        {
            uint32 dwMidScrollImageColorKey = m_pMidScrollImage.GetPixel(5, 0);
            m_dwMidScrollImageColorKey = dwMidScrollImageColorKey;

            m_pMidScrollImageData = new ImageData();
            m_pMidScrollImageData.Create(m_pMidScrollImage.GetRawImage(), m_pMidScrollImage.GetWidth(), m_pMidScrollImage.GetHeight(), dwMidScrollImageColorKey);
        }
        //delete pMidScrollImage;
        //pMidScrollImage = nullptr;

        m_pBackImage = new TGAImage();
        m_pBackImage.Load24BitsTGA("./data/background.tga", 4);

        int32 screenW = (int32)m_pDDraw.Width;
        int32 screenH = (int32)m_pDDraw.Height;
        int32 iPlayerPosX = (screenW - (int32)m_pPlayerImgData.GetWidth()) / 2;
        int32 iPlayerPosY = (screenH - (int32)m_pPlayerImgData.GetHeight()) / 2;

        m_pPlayer = GameObject.CreatePlayer(m_pPlayerImgData, iPlayerPosX, iPlayerPosY, DEFAULT_PLAYER_SPEED);

        IsInitialized = true;
        return true;
    }

    public void Process()
    {
        gameClock.UpdatePerFrameLoop();

        if (gameClock.TryConsumeFixedDeltaTimeSec())
        {
            FixPositionPosition();

            uint64 CurTick = GetTickCount64();
            OnGameFrame(CurTick);
        }
        else
        {
            let alpha = gameClock.Alpha;
            InterpolatePosition(alpha);
        }

        DrawScene();
    }

    public void OnKeyDown(uint32 nChar, uint32 uiScanCode)
    {
        switch ((VIRTUAL_KEY)nChar)
        {
        case .VK_LEFT:
            {
                m_bKeyDown_Left = true;
            }
        case .VK_RIGHT:
            {
                m_bKeyDown_Right = true;
            }
        case .VK_UP:
            {
                m_bKeyDown_Up = true;
            }
        case .VK_DOWN:
            {
                m_bKeyDown_Down = true;
            }
        case .VK_SPACE:
            {
                ShootFromPlayer();
            }
        case .VK_RETURN:
            {
                //CaptureBackBuffer("backbuffer.tga");
            }
        default:
        }
    }

    public void OnKeyUp(uint32 nChar, uint32 uiScanCode)
    {
        switch ((VIRTUAL_KEY)nChar)
        {
        case .VK_LEFT:
            {
                m_bKeyDown_Left = false;
            }
        case .VK_RIGHT:
            {
                m_bKeyDown_Right = false;
            }
        case .VK_UP:
            {
                m_bKeyDown_Up = false;
            }
        case .VK_DOWN:
            {
                m_bKeyDown_Down = false;
            }
        default:
        }
    }

    public bool OnSysKeyDown(uint32 nChar, uint32 uiScanCode, int32 bAltKeyDown)
    {
        switch ((VIRTUAL_KEY)nChar)
        {
        case .VK_F9:
            if (bAltKeyDown != 0)
            {
                CaptureBackBuffer("backbuffer.tga");
                return true;
            }
        default:
        }
        return false;
    }

    bool CaptureBackBuffer(StringView szFileName)
    {
        UnbufferedFileStream fs = scope UnbufferedFileStream();
        var result = fs.Open(szFileName, .Create, .Write);
        if (result case .Err(let err))
        {
            Console.Error.WriteLine($"err: {err}");
            return false;
        }

        if (m_pDDraw != null)
        {
            uint32 size = m_pDDraw.CaptureBackBuffer(fs);
            if (size == 0)
            {
                return false;
            }
        }

        return true;
    }


    void DrawScene()
    {
        if (m_pDDraw.BeginDraw())
        {
            if (m_pBackImage != null)
            {
                m_pDDraw.DrawBitmap(m_iBackImagePosX, m_iBackImagePosY, (int32)m_pBackImage.GetWidth(), (int32)m_pBackImage.GetHeight(), m_pBackImage.GetRawImage());
            }
            else
            {
                m_pDDraw.Clear();
            }

            // mid scroll image
            // 속도비교를 위해 둘중 하나를 주석처리한다.

            // case-1a: 0번압축으로 출력.이쪽이 훨씬 빠르다.
            m_pDDraw.DrawImageData(m_iMidScrollImagePosX, m_iMidScrollImagePosY, m_pMidScrollImageData);

            // case-1b: 픽셀당 컬러키 비교 방식으로 출력. 0번압축보다 느리다.
            //m_pDDraw.DrawBitmapWithColorKey(m_iMidScrollImagePosX, m_iMidScrollImagePosY, (int32)m_pMidScrollImage.GetWidth(), (int32)m_pMidScrollImage.GetHeight(), m_pMidScrollImage.GetRawImage().Ptr, m_dwMidScrollImageColorKey);

            //m_pDDraw.DrawRect(sx, sy, iBoxWidth, iBoxHeight, 0xFF00FF00);

            // Draw player
            int2 ivPos;
            m_pPlayer.GetInterpolatedPos(out ivPos);
            //m_pPlayer.GetPos(&ivPos);
            DrawFlightObject(m_pPlayer, ivPos.x, ivPos.y);

            for (int i = 0; i < m_dwCurEnemiesNum; i++)
            {
                m_ppEnemyList[i].GetInterpolatedPos(out ivPos);
                DrawFlightObject(m_ppEnemyList[i], ivPos.x, ivPos.y);
            }

            for (int i = 0; i < m_dwCurAmmoNum; i++)
            {
                m_ppAmmoList[i].GetInterpolatedPos(out ivPos);
                DrawFlightObject(m_ppAmmoList[i], ivPos.x, ivPos.y);
            }

            m_pDDraw.EndDraw();
        }

        HDC hDC = .();
        if (m_pDDraw.BeginGDI(&hDC))
        {
            m_pDDraw.DrawInfo(hDC);
            m_pDDraw.EndGDI(hDC);
        }

        m_pDDraw.OnDraw();
        m_pDDraw.CheckFPS();
    }

    public void OnUpdateWindowSize()
    {
        m_pDDraw.OnUpdateWindowSize();
    }

    public void OnUpdateWindowPos()
    {
        m_pDDraw.OnUpdateWindowPos();
    }

    void DrawFlightObject(FlightObject pFighter, int32 x, int32 y)
    {
        m_pDDraw.DrawImageData(x, y, pFighter.GetImageData());
    }

    void InterpolatePosition(float fAlpha)
    {
        if (m_pPlayer != null)
        {
            m_pPlayer.Interpolate(fAlpha);
        }

        for (int i = 0; i < m_dwCurEnemiesNum; i++)
        {
            FlightObject pEnemy = m_ppEnemyList[i];
            pEnemy.Interpolate(fAlpha);
        }
        for (int i = 0; i < m_dwCurAmmoNum; i++)
        {
            FlightObject pAmmo = m_ppAmmoList[i];
            pAmmo.Interpolate(fAlpha);
        }
    }

    void FixPositionPosition()
    {
        if (m_pPlayer != null)
        {
            m_pPlayer.FixPos();
        }

        for (int i = 0; i < m_dwCurEnemiesNum; i++)
        {
            FlightObject pEnemy = m_ppEnemyList[i];
            pEnemy.FixPos();
        }
        for (int i = 0; i < m_dwCurAmmoNum; i++)
        {
            FlightObject pAmmo = m_ppAmmoList[i];
            pAmmo.FixPos();
        }
    }

    void OnGameFrame(uint64 CurTick)
    {
        int32 iScreenWidth = (int32)m_pDDraw.GetWidth();
        int32 iScreenHeight = (int32)m_pDDraw.GetHeight();

        UpdatePlayerPos(iScreenWidth, iScreenHeight);

        // 사망한 적들 제거

        DeleteDestroyedEnemies(CurTick);
        ProcessCollision(CurTick);

        // 탄환이 맵 끝에 도달하면 자동 파괴
        int dwIndex = 0;
        while (dwIndex < m_dwCurAmmoNum)
        {
            FlightObject pAmmo = m_ppAmmoList[dwIndex];
            int2 ivPos = ?;
            pAmmo.GetPos(out ivPos);
            if (ivPos.y < 0)
            {
                GameObject.DeleteFlightObject(pAmmo);
                m_dwCurAmmoNum--;
                m_ppAmmoList[dwIndex] = m_ppAmmoList[m_dwCurAmmoNum];
                m_ppAmmoList[m_dwCurAmmoNum] = null;
            }
            else
            {
                //ivPos.y--;
                ivPos.y -= (int32)pAmmo.GetSpeed();
                pAmmo.SetPos(&ivPos, true);
                dwIndex++;
            }
        }

        ProcessEnemies();

        UpdateBackground();
    }

    void UpdateBackground()
    {
        /*
        static ULONGLONG PrvUpdateTick = 0;
        ULONGLONG CurTick = GetTickCount64();

        if (CurTick - PrvUpdateTick < 1000)
            return;

        PrvUpdateTick = CurTick;

        DWORD dwTotalPixels = (DWORD)(m_iScreenWidth * m_iScreenHeight);


        WCHAR* pSrc = m_pBackground + (m_iScreenHeight - 1) * m_iScreenWidth;
        WCHAR* pDest = m_pBackgroundLineBuffer;

        for (int y = 0; y < m_iScreenHeight; y++)
        {
            memcpy(pDest, pSrc, sizeof(WCHAR) * m_iScreenWidth);
            pDest = pSrc;
            pSrc -= m_iScreenWidth;
        }
        memcpy(m_pBackground, m_pBackgroundLineBuffer, sizeof(WCHAR) * m_iScreenWidth);
        //memcpy(m_pBackground, m_pBackground + m_iScreenWidth, sizeof(WCHAR) * (dwTotalPixels - (DWORD)m_iScreenWidth));
        //memcpy(m_pBackground + (dwTotalPixels - (DWORD)m_iScreenWidth), m_pBackgroundLineBuffer, sizeof(WCHAR) * m_iScreenWidth);
        */
    }

    void UpdatePlayerPos(int32 iScreenWidth, int32 iScreenHeight)
    {
        int2 ivPlayerPos = ?;
        m_pPlayer.GetPos(out ivPlayerPos);


        if (m_bKeyDown_Left)
        {
            //m_iPlayerPosX--;
            ivPlayerPos.x -= m_pPlayer.GetSpeed();
        }
        if (m_bKeyDown_Right)
        {
            //m_iPlayerPosX++;
            ivPlayerPos.x += m_pPlayer.GetSpeed();
        }
        if (m_bKeyDown_Up)
        {
            //m_iPlayerPosY--;
            ivPlayerPos.y -= m_pPlayer.GetSpeed();
        }
        if (m_bKeyDown_Down)
        {
            //m_iPlayerPosY++;
            ivPlayerPos.y += m_pPlayer.GetSpeed();
        }

        if (m_pPlayerImgData != null)
        {
            int32 iPlayerImageWidth = (int32)m_pPlayerImgData.GetWidth();
            int32 iPlayerImageHeight = (int32)m_pPlayerImgData.GetHeight();

            if (ivPlayerPos.x < -(iPlayerImageWidth / 2))
            {
                ivPlayerPos.x = -(iPlayerImageWidth / 2);
                m_iBackImagePosX++;
                m_iMidScrollImagePosX += 2;
            }
            if (ivPlayerPos.x > iScreenWidth - iPlayerImageWidth + (iPlayerImageWidth / 2))
            {
                ivPlayerPos.x = iScreenWidth - iPlayerImageWidth + (iPlayerImageWidth / 2);
                m_iBackImagePosX--;
                m_iMidScrollImagePosX -= 2;
            }

            if (ivPlayerPos.y < -(iPlayerImageHeight / 2))
            {
                ivPlayerPos.y = -(iPlayerImageHeight / 2);
                m_iBackImagePosY++;
                m_iMidScrollImagePosY += 2;
            }
            if (ivPlayerPos.y > iScreenHeight - iPlayerImageHeight + (iPlayerImageHeight / 2))
            {
                ivPlayerPos.y = iScreenHeight - iPlayerImageHeight + (iPlayerImageHeight / 2);
                m_iBackImagePosY--;
                m_iMidScrollImagePosY -= 2;
            }
        }

        if (m_pBackImage != null)
        {
            int32 iBackImageWidth = (int32)m_pBackImage.GetWidth();
            int32 iBackImageHeight = (int32)m_pBackImage.GetHeight();

            if (iBackImageWidth > iScreenWidth)
            {
                if (m_iBackImagePosX > 0)
                {
                    m_iBackImagePosX = 0;
                }
                if (m_iBackImagePosX < iScreenWidth - iBackImageWidth)
                {
                    m_iBackImagePosX = iScreenWidth - iBackImageWidth;
                }
            }
            if (iBackImageHeight > iScreenHeight)
            {
                if (m_iBackImagePosY > 0)
                {
                    m_iBackImagePosY = 0;
                }
                if (m_iBackImagePosY < iScreenHeight - iBackImageHeight)
                {
                    m_iBackImagePosY = iScreenHeight - iBackImageHeight;
                }
            }
        }

        if (m_pMidScrollImageData != null)
        {
            int32 iMidScrollImageWidth = (int32)m_pMidScrollImageData.GetWidth();
            int32 iMidScrollImageHeight = (int32)m_pMidScrollImageData.GetHeight();

            if (iMidScrollImageWidth > iScreenWidth)
            {
                if (m_iMidScrollImagePosX > 0)
                {
                    m_iMidScrollImagePosX = 0;
                }
                if (m_iMidScrollImagePosX < iScreenWidth - iMidScrollImageWidth)
                {
                    m_iMidScrollImagePosX = iScreenWidth - iMidScrollImageWidth;
                }
            }
            if (iMidScrollImageHeight > iScreenHeight)
            {
                if (m_iMidScrollImagePosY > 0)
                {
                    m_iMidScrollImagePosY = 0;
                }
                if (m_iMidScrollImagePosY < iScreenHeight - iMidScrollImageHeight)
                {
                    m_iMidScrollImagePosY = iScreenHeight - iMidScrollImageHeight;
                }
            }
        }
        m_pPlayer.SetPos(&ivPlayerPos, true);
    }

    void DeleteDestroyedEnemies(uint64 CurTick)
    {
        int dwIndex = 0;
        while (dwIndex < m_dwCurEnemiesNum)
        {
            FlightObject pEnemy = m_ppEnemyList[dwIndex];
            if (pEnemy.GetStatus() == .FLIGHT_OBJECT_STATUS_DEAD && CurTick - pEnemy.GetDeadTick() > DEAD_STATUS_WAIT_TICK)
            {
                GameObject.DeleteFlightObject(pEnemy);
                m_dwCurEnemiesNum--;
                m_ppEnemyList[dwIndex] = m_ppEnemyList[m_dwCurEnemiesNum];
                m_ppEnemyList[m_dwCurEnemiesNum] = null;
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
        while (dwIndex < m_dwCurAmmoNum)
        {
            FlightObject pAmmo = m_ppAmmoList[dwIndex];
            if (ProcessCollisionAmmoVsEnemies(pAmmo, CurTick))
            {
                GameObject.DeleteFlightObject(pAmmo);
                m_dwCurAmmoNum--;
                m_ppAmmoList[dwIndex] = m_ppAmmoList[m_dwCurAmmoNum];
                m_ppAmmoList[m_dwCurAmmoNum] = null;
            }
            else
            {
                dwIndex++;
            }
        }
    }

    bool IsCollisionFlightObjectVsFlightObject(FlightObject pObj0, FlightObject pObj1)
    {
        if (pObj0.GetStatus() != .FLIGHT_OBJECT_STATUS_ALIVE || pObj1.GetStatus() != .FLIGHT_OBJECT_STATUS_ALIVE)
        {
            return false;
        }

        int2 ivPos0 = ?;
        pObj0.GetPos(out ivPos0);

        int2 ivPos1 = ?;
        pObj1.GetPos(out ivPos1);

        SRect objRect0 =
            .(
            ivPos0.x, ivPos0.y,
            ivPos0.x + pObj0.GetWidth(), ivPos0.y + pObj0.GetHeight()
            );
        SRect objRect1 =
            .(ivPos1.x, ivPos1.y,
            ivPos1.x + pObj1.GetWidth(), ivPos1.y + pObj1.GetHeight()
            );

        bool bResult = Util.IsCollisionRectVsRect(&objRect0.min, &objRect0.max, &objRect1.min, &objRect1.max);
        return bResult;
    }

    bool ProcessCollisionAmmoVsEnemies(FlightObject pAmmo, uint64 CurTick)
    {
        for (int i = 0; i < m_dwCurEnemiesNum; i++)
        {
            FlightObject pEnemy = m_ppEnemyList[i];
            if (IsCollisionFlightObjectVsFlightObject(pAmmo, pEnemy))
            {
                // 적 타격 성공
                OnHitEnemy(pEnemy, CurTick);

                return true;
            }
        }

        return false;
    }

    void ProcessEnemies()
    {
        //int iScreenWidth = (int)m_pDDraw.GetWidth();
        int iScreenHeight = (int)m_pDDraw.GetHeight();

        // 적이 맵 끝(바닥)에 도달하면 자동파괴
        uint32 dwIndex = 0;
        while (dwIndex < m_dwCurEnemiesNum)
        {
            FlightObject pEnemy = m_ppEnemyList[dwIndex];
            int2 ivPos = ?;
            pEnemy.GetPos(out ivPos);
            if (ivPos.y >= iScreenHeight)
            {
                GameObject.DeleteFlightObject(pEnemy);
                m_dwCurEnemiesNum--;
                m_ppEnemyList[dwIndex] = m_ppEnemyList[m_dwCurEnemiesNum];
                m_ppEnemyList[m_dwCurEnemiesNum] = null;
            }
            else
            {
                dwIndex++;
            }
        }
        MoveEnemies();
        FillEnemies();
    }

    void OnHitEnemy(FlightObject pEnemy, uint64 CurTick)
    {
        // 지금 삭제하지 않고 상태만 바꾼다.
        GameObject.ChangeFlightObjectStatusToDead(pEnemy, CurTick);
        AddScore(SCORE_PER_ONE_KILL);
    }

    uint32 AddScore(uint32 dwAddval)
    {
        /*
        m_dwCurScore += dwAddval;
        return m_dwCurScore;
        */
        return 0;
    }

    static uint64 PrvEnemyMoveTick = 0;
    void MoveEnemies()
    {
        int32 iScreenWidth = (int32)m_pDDraw.GetWidth();
        //int32 iScreenHeight = (int32)m_pDDraw.GetHeight();

        uint64 CurTick = GetTickCount64();
        if (CurTick - PrvEnemyMoveTick < ENEMY_MOVE_ACTION_DELAY_TICK)
        {
            return;
        }
        PrvEnemyMoveTick = CurTick;

        for (int i = 0; i < m_dwCurEnemiesNum; i++)
        {
            GameObject.MoveEmemy(m_ppEnemyList[i], iScreenWidth);
        }
    }

    static uint64 PrvFillEnemyTick = 0;
    void FillEnemies()
    {
        int32 iScreenWidth = (int32)m_pDDraw.GetWidth();
        int32 iScreenHeight = (int32)m_pDDraw.GetHeight();

        if (m_dwCurEnemiesNum >= MAX_ENEMY_NUM)
        {
            return;
        }

        uint64 CurTick = GetTickCount64();
        if (CurTick - PrvFillEnemyTick < 3000)
        {
            return;
        }
        PrvFillEnemyTick = CurTick;

        int dwNeyEnemyNum = MAX_ENEMY_NUM - m_dwCurEnemiesNum;
        for (int i = 0; i < dwNeyEnemyNum; i++)
        {
            FlightObject pEnemy = GameObject.CreateEnemyRandom(m_pEnemyImgData, iScreenWidth, iScreenHeight, DEFAULT_ENEMY_SPEED);
            m_ppEnemyList[m_dwCurEnemiesNum] = pEnemy;
            m_dwCurEnemiesNum++;
        }
    }

    void ShootFromPlayer()
    {
        if (m_dwCurAmmoNum >= MAX_AMMO_NUM)
        {
            return;
        }

        FlightObject pAmmo = GameObject.CreateAmmo(m_pPlayer, m_pAmmoImgData, DEFAULT_AMMO_SPEED);
        m_ppAmmoList[m_dwCurAmmoNum] = pAmmo;
        m_dwCurAmmoNum++;
    }

    void DrawScore(int x, int y)
    {
        /*
        DWORD dwOffset = x + y * m_iScreenWidth;
        WCHAR* wchDest = m_pBackBuffer + dwOffset;
        DWORD dwDesBufferLen = (DWORD)((m_iScreenWidth * m_iScreenHeight - (int)dwOffset));

        WCHAR wchTxt[32];
        DWORD dwLen = swprintf_s(wchTxt, L"Score:%08u", m_dwCurScore);
        memcpy(wchDest, wchTxt, sizeof(WCHAR) * dwLen);
        */
    }

}