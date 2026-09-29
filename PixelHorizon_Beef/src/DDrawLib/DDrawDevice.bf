using Win32.Foundation;
using Win32.UI.WindowsAndMessaging;
using Win32.Graphics.DirectDraw;
using Win32;
using Win32.Globalization;
using Win32.Graphics.Gdi;
using Win32.System.SystemInformation;
using System;
using System.Diagnostics;
using System.Text;
using PixelHorizon_Beef.ImageData;
using PixelHorizon_Beef.Common;
using PixelHorizon_Beef.Utils;
using System.IO;

namespace PixelHorizon_Beef.DDrawLib;

class DDrawDevice
{
    const int32 DD_OK = S_OK;

    IDirectDraw* m_pDD = null;
    IDirectDraw7* m_pDD7 = null;
    IDirectDrawSurface7* m_pDDPrimary = null;
    IDirectDrawSurface7* m_pDDBack = null;
    IDirectDrawClipper* m_pClipper = null;

    uint8* m_pWriteBuffer = null;
    uint32 m_dwWriteBufferPitch = 0;
    uint32 m_dwWidth;
    uint32 m_dwHeight;

    public uint32 Width => m_dwWidth;
    public uint32 Height => m_dwHeight;

    RECT m_rcWindow;
    HWND m_hWnd;
    uint32 m_dwFrameCount;
    uint32 m_dwFPS;
    uint64 m_LastDrawTick;
    String _fpsStr = new String("Asdf") ~ delete _;
    char16[64] m_wchInfoTxt;
    int32 m_wchInfoTxtLen;

    public uint32 GetWidth() { return m_dwWidth; }
    public uint32 GetHeight() { return m_dwHeight; }

    public ~this()
    {
        Cleanup();
    }

    [NoDiscard]
    public bool InitializeDDraw(HWND hwnd)
    {
        m_hWnd = hwnd;

        HRESULT r = ?;
        r = DirectDrawCreate(null, &m_pDD, null);
        if (FAILED(r))
        {
            String s = scope $"Fail to Create DirectDraw: {r}";
            MessageBoxW(hwnd, s.ToScopedNativeWChar!(), TEXT!("Error"), .MB_OK);
            return false;
        }

        r = m_pDD.QueryInterface(IDirectDraw7.IID, (void**)&m_pDD7);
        if (FAILED(r))
        {
            String s = scope $"Fail to QueryInterface: {r}";
            MessageBoxW(hwnd, s.ToScopedNativeWChar!(), TEXT!("Error"), .MB_OK);
            return false;
        }

        r = m_pDD7.SetCooperativeLevel(hwnd, DDSCL_NORMAL);
        if (FAILED(r))
        {
            String s = scope $"Fail to SetCooperativeLevel: {r}";
            MessageBoxW(hwnd, s.ToScopedNativeWChar!(), TEXT!("Error"), .MB_OK);
            return false;
        }


        DDSURFACEDESC2 ddsd = .();
        ddsd.dwSize = sizeof(DDSURFACEDESC2);
        ddsd.dwFlags = DDSD_CAPS;
        ddsd.ddsCaps.dwCaps = DDSCAPS_PRIMARYSURFACE;
        r = m_pDD7.CreateSurface(&ddsd, &m_pDDPrimary, null);
        if (FAILED(r))
        {
            String s = scope $"Fail to CreateSurface: {r}";
            MessageBoxW(hwnd, s.ToScopedNativeWChar!(), TEXT!("Error"), .MB_OK);
            return false;
        }

        r = m_pDD.CreateClipper(0, &m_pClipper, null);
        if (FAILED(r))
        {
            String s = scope $"Fail to CreateClipper: {r}";
            MessageBoxW(hwnd, s.ToScopedNativeWChar!(), TEXT!("Error"), .MB_OK);
            return false;
        }

        m_pClipper.SetHWnd(0, hwnd);
        m_pDDPrimary.SetClipper(m_pClipper);

        ddsd.dwFlags = DDSD_WIDTH | DDSD_HEIGHT | DDSD_CAPS;
        ddsd.ddsCaps.dwCaps = DDSCAPS_OFFSCREENPLAIN | DDSCAPS_SYSTEMMEMORY;

        OnUpdateWindowPos(hwnd, ref m_rcWindow);

        uint32 dwWidth = (uint32)(m_rcWindow.right - m_rcWindow.left);
        uint32 dwHeight = (uint32)(m_rcWindow.bottom - m_rcWindow.top);
        if (!CreateBackBuffer(dwWidth, dwHeight))
        {
#if DEBUG
            Debug.Break();
#endif // DEBUG
            return false;
        }

        return true;
    }

    static void OnUpdateWindowPos(HWND hwnd, ref RECT rect)
    {
        GetClientRect(hwnd, &rect);
        ClientToScreen(hwnd, (POINT*)&rect.left);
        ClientToScreen(hwnd, (POINT*)&rect.right);
    }

    bool CreateBackBuffer(uint32 dwWidth, uint32 dwHeight)
    {
        Debug.Assert(m_pDD7 != null);

        DDSURFACEDESC2 ddsd = .();
        ddsd.dwSize = sizeof(DDSURFACEDESC2);
        ddsd.dwFlags = DDSD_WIDTH | DDSD_HEIGHT | DDSD_CAPS;
        ddsd.ddsCaps.dwCaps = DDSCAPS_OFFSCREENPLAIN | DDSCAPS_SYSTEMMEMORY;
        ddsd.dwWidth = dwWidth;
        ddsd.dwHeight = dwHeight;

        HRESULT r = m_pDD7.CreateSurface(&ddsd, &m_pDDBack, null);
        if (FAILED(r))
        {
            String s = scope $"Fail to CreateSurface: {r}";
            MessageBoxW(m_hWnd, s.ToScopedNativeWChar!(), TEXT!("ERROR"), .MB_OK);
            return false;
        }

        m_pDDBack.GetSurfaceDesc(&ddsd);
        m_dwWidth = ddsd.dwWidth;
        m_dwHeight = ddsd.dwHeight;
        return true;
    }

    public void Clear()
    {
        if (m_pWriteBuffer == null)
        {
#if DEBUG
            Debug.Break();
#endif // DEBUG
            return;
        }

        for (int y = 0; y < m_dwHeight; y++)
        {
            Internal.MemSet(m_pWriteBuffer + y * m_dwWriteBufferPitch, 0, 4 * m_dwWidth);
        }
    }

    bool LockBackBuffer(uint8** ppBits, uint32* pdwWidth, uint32* pdwHeight, uint32* pdwPitch)
    {
        // TODO(pyoung): out?
        if (m_pDDBack != null)
        {
            DDSURFACEDESC2 ddsc = .();
            ddsc.dwSize = sizeof(DDSURFACEDESC2);

            m_pDDBack.Lock(null, &ddsc, DDLOCK_WAIT | DDLOCK_WRITEONLY, 0);

            *ppBits = (uint8*)ddsc.lpSurface;
            *pdwPitch = (uint32)ddsc.lPitch;
            *pdwWidth = ddsc.dwWidth;
            *pdwHeight = ddsc.dwHeight;
        }

        return true;
    }

    void UnlockBackBuffer()
    {
        if (m_pDDBack != null)
        {
            m_pDDBack.Unlock(null);
        }
    }

    public uint32 CaptureBackBuffer(UnbufferedFileStream fs)
    {
        if (m_pDDBack == null)
        {
            return 0;
        }

        DDSURFACEDESC2 ddsc = .();
        ddsc.dwSize = sizeof(DDSURFACEDESC2);

        m_pDDBack.Lock(null, &ddsc, DDLOCK_WAIT | DDLOCK_READONLY, 0);

        uint32 dwResult = (uint32)TGAImage.WriteTGAImage(fs, (uint8*)ddsc.lpSurface, ddsc.dwWidth, ddsc.dwHeight, (uint32)ddsc.lPitch, 32);
        m_pDDBack.Unlock(null);

        return dwResult;
    }

    void SetPixelRandom()
    {
        uint32 dwColor = 0xFFFFFFFF;

        uint8* pBits = null;
        uint32 dwWidth = 0;
        uint32 dwHeight = 0;
        uint32 dwPitch = 0;
        if (!LockBackBuffer(&pBits, &dwWidth, &dwHeight, &dwPitch))
        {
            Debug.Break();
        }

        uint32 x = (uint32)Util.Interop.rand() % dwWidth;
        uint32 y = (uint32)Util.Interop.rand() % dwHeight;
        uint32* pDest = (uint32*)(pBits + x * 4 + y * dwPitch);
        *pDest = dwColor;

        UnlockBackBuffer();
    }

    public void OnUpdateWindowSize()
    {
        CleanupBackBuffer();

        OnUpdateWindowPos();

        uint32 dwWidth = (uint32)(m_rcWindow.right - m_rcWindow.left);
        uint32 dwHeight = (uint32)(m_rcWindow.bottom - m_rcWindow.top);
        CreateBackBuffer(dwWidth, dwHeight);

        if (BeginDraw())
        {
            Clear();
            EndDraw();
        }
    }

    public void OnUpdateWindowPos()
    {
         // TOOD(pyoung) : static
        GetClientRect(m_hWnd, &m_rcWindow);
        ClientToScreen(m_hWnd, (POINT*)&m_rcWindow.left);
        ClientToScreen(m_hWnd, (POINT*)&m_rcWindow.right);
    }

    void DrawRect(int sx, int sy, int iWidth, int iHeight, uint32 dwColor)
    {

#if DEBUG
        if (m_pWriteBuffer == null)
        {
            Debug.Break();
        }
#endif // DEBUG

        int start_x = Math.Max(0, sx);
        int start_y = Math.Max(0, sy);
        int end_x = Math.Min(sx + iWidth, (int)m_dwWidth);
        int end_y = Math.Min(sy + iHeight, (int)m_dwHeight);

        for (int y = start_y; y < end_y; y++)
        {
            for (int x = start_x; x < end_x; x++)
            {
                uint32* pDest = (uint32*)(m_pWriteBuffer + x * 4 + y * m_dwWriteBufferPitch);
                *pDest = dwColor;
            }
        }
    }

    bool CalcClipArea(int2* pivOutSrcStart, int2* pivOutDestStart, int2* pivOutDestSize, int2* pivPos, int2* pivImageSize)
    {
        int2 ivBufferSize = .((int32)m_dwWidth, (int32)m_dwHeight);
        bool bResult = Util.CalcClipArea(pivOutSrcStart, pivOutDestStart, pivOutDestSize, pivPos, pivImageSize, &ivBufferSize);
        return bResult;
    }

    public bool BeginDraw()
    {
        uint8* pBuffer = null;
        uint32 dwBufferWidth = 0;
        uint32 dwBufferHeight = 0;
        uint32 dwPitch = 0;

        if (!LockBackBuffer(&pBuffer, &dwBufferWidth, &dwBufferHeight, &dwPitch))
        {
#if DEBUG
            Debug.Break();
#endif
            return false;
        }

#if DEBUG
        if (dwBufferWidth != m_dwWidth)
        {
            Debug.Break();
        }

        if (dwBufferHeight != m_dwHeight)
        {
            Debug.Break();
        }
#endif
        m_pWriteBuffer = pBuffer;
        m_dwWriteBufferPitch = dwPitch;

        return true;
    }

    public void EndDraw()
    {
        UnlockBackBuffer();
        m_pWriteBuffer = null;
        m_dwWriteBufferPitch = 0;
    }

    public bool DrawBitmap(int32 sx, int32 sy, int32 iBitmapWidth, int32 iBitmapHeight, uint8[] pBits)
    {
#if DEBUG
        if (m_pWriteBuffer == null)
        {
            Debug.Break();
        }
#endif // DEBUG

        int2 ivSrcStart = .ZERO;
        int2 ivDestStart = .ZERO;

        int2 ivPos = .(sx, sy);
        int2 ivImageSize = .(iBitmapWidth, iBitmapHeight);
        int2 ivDestSize = .ZERO;

        if (!CalcClipArea(&ivSrcStart, &ivDestStart, &ivDestSize, &ivPos, &ivImageSize))
        {
            return false;
        }

        uint8* pSrc = pBits.Ptr + (ivSrcStart.x + ivSrcStart.y * iBitmapWidth) * 4;
        uint8* pDest = m_pWriteBuffer + (uint32)(ivDestStart.x * 4) + (uint32)ivDestStart.y * m_dwWriteBufferPitch;

        for (int y = 0; y < ivDestSize.y; y++)
        {
            for (int x = 0; x < ivDestSize.x; x++)
            {
                *(uint32*)pDest = *(uint32*)pSrc;
                pSrc += 4;
                pDest += 4;
            }
            pSrc -= (ivDestSize.x * 4);
            pSrc += (iBitmapWidth * 4);
            pDest -= (ivDestSize.x * 4);
            pDest += m_dwWriteBufferPitch;
        }

        return true;
    }

    public bool DrawBitmapWithColorKey(int32 sx, int32 sy, int32 iBitmapWidth, int32 iBitmapHeight, uint8* pBits, uint32 dwColorKey)
    {
#if DEBUG
        if (m_pWriteBuffer == null)
        {
            Debug.Break();
        }
#endif // DEBUG

        int2 ivSrcStart = .();
        int2 ivDestStart = .();

        int2 ivPos = .(sx, sy);
        int2 ivImageSize = .(iBitmapWidth, iBitmapHeight);
        int2 ivDestSize = .();

        if (!CalcClipArea(&ivSrcStart, &ivDestStart, &ivDestSize, &ivPos, &ivImageSize))
        {
            return false;
        }

        uint8* pSrc = pBits + (ivSrcStart.x + ivSrcStart.y * iBitmapWidth) * 4;
        uint8* pDest = m_pWriteBuffer + (ivDestStart.x * 4) + (uint32)ivDestStart.y * m_dwWriteBufferPitch;

        for (int y = 0; y < ivDestSize.y; y++)
        {
            for (int x = 0; x < ivDestSize.x; x++)
            {
                if (*(uint32*)pSrc != dwColorKey)
                {
                    *(uint32*)pDest = *(uint32*)pSrc;
                }
                pSrc += 4;
                pDest += 4;
            }
            pSrc -= (ivDestSize.x * 4);
            pSrc += (iBitmapWidth * 4);
            pDest -= (ivDestSize.x * 4);
            pDest += m_dwWriteBufferPitch;
        }

        return true;
    }

    public bool DrawImageData(int32 sx, int32 sy, ImageData pImgData)
    {
#if DEBUG
        if (m_pWriteBuffer == null)
        {
            Debug.Break();
        }
#endif // DEBUG

        int iScreenWidth = (int)m_dwWidth;

        int32 iBitmapWidth = (int32)pImgData.GetWidth();
        int32 iBitmapHeight = (int32)pImgData.GetHeight();

        int2 ivSrcStart = .();
        int2 ivDestStart = .();

        int2 ivPos = .(sx, sy);
        int2 ivImageSize = .(iBitmapWidth, iBitmapHeight);
        int2 ivDestSize = .();

        if (!CalcClipArea(&ivSrcStart, &ivDestStart, &ivDestSize, &ivPos, &ivImageSize))
        {
            return false;
        }

        COMPRESSED_LINE* pLineDesc = pImgData.GetCompressedImage(ivSrcStart.y);
        uint8* pDestPerLine = m_pWriteBuffer + (uint32)(ivDestStart.y) * m_dwWriteBufferPitch;

        for (int y = 0; y < ivDestSize.y; y++)
        {
            for (int i = 0; i < pLineDesc.dwStreamNum; i++)
            {
                PIXEL_STREAM* pStream = pLineDesc.pPixelStream + i;
                uint32 dwPixelColor = pStream.dwPixel;
                int iPixelNum = (int)pStream.wPixelNum;

                int dest_x = sx + (int)pStream.wPosX;
                if (dest_x < 0)
                {
                    iPixelNum += dest_x;
                    dest_x = 0;
                }
                if (dest_x + iPixelNum > iScreenWidth)
                {
                    iPixelNum = iScreenWidth - dest_x;
                }
                uint8* pDest = pDestPerLine + (uint32)(dest_x * 4);
                for (int x = 0; x < iPixelNum; x++)
                {
                    *(uint32*)pDest = dwPixelColor;
                    pDest += 4;
                }
            }
            pLineDesc++;
            pDestPerLine += m_dwWriteBufferPitch;
        }

        return true;
    }

    void UpdateInfoTxt()
    {
        _fpsStr.Clear();
        _fpsStr.AppendF("FPS : {}", m_dwFPS);

        int encodedLen = UTF16.GetEncodedLen(_fpsStr);
        UTF16.Encode(_fpsStr, (.)&m_wchInfoTxt, encodedLen);
        m_wchInfoTxt[encodedLen] = 0;
        m_wchInfoTxtLen = (int32)_fpsStr.Length;
    }


    public bool CheckFPS()
    {
        bool bUpdated = false;

        uint64 CurTick = GetTickCount64();
        if (CurTick - m_LastDrawTick > 1000)
        {
            uint32 dwOldPFS = m_dwFPS;

            m_dwFPS = m_dwFrameCount;
            m_LastDrawTick = CurTick;
            m_dwFrameCount = 0;
            if (m_dwFPS != dwOldPFS)
            {
                UpdateInfoTxt();
                bUpdated = true;
            }
            else
            {
                //int a = 0;
            }
        }
        m_dwFrameCount += 1;
        return bUpdated;
    }

    public void OnDraw()
    {
        m_pDDPrimary.Blt(&m_rcWindow, m_pDDBack, null, DDBLT_WAIT, null);
    }

    #region GDI
    void ProcessGDI(int param)
    {
    }

    public bool BeginGDI(HDC* pOutDC)
    {
        HDC hDC = .();
        HRESULT hr = m_pDDBack.GetDC(&hDC);
        if (FAILED(hr))
        {
#if DEBUG
            Debug.Break();
#endif
            return false;
        }
        *pOutDC = hDC;

        return true;
    }


    public void DrawInfo(HDC hDC)
    {
        WriteText(&m_wchInfoTxt, m_wchInfoTxtLen, 0, 0, 0xFFFF0000, hDC);
    }

    public void EndGDI(HDC hDC)
    {
        ProcessGDI(hDC);
        m_pDDBack.ReleaseDC(hDC);
    }

    static void WriteText(char16* wchTxt, int32 dwLen, int32 x, int32 y, uint32 dwColor, HDC hDC)
    {
        SetBkMode(hDC, .TRANSPARENT);

        int32 iWidth = 0;
        int32 iHeight = 0;
        GetFontSize(out iWidth, out iHeight, wchTxt, (int32)dwLen, hDC);

        RECT textRect;
        textRect.left = x;
        textRect.top = y;
        textRect.right = textRect.left + iWidth;
        textRect.bottom = textRect.top + iHeight;

        RECT[4] texRectSide;

        texRectSide[0].left = textRect.left - 1;
        texRectSide[0].top = textRect.top - 1;
        texRectSide[0].right = textRect.right - 1;
        texRectSide[0].bottom = textRect.bottom - 1;

        texRectSide[1].left = textRect.left + 1;
        texRectSide[1].top = textRect.top - 1;
        texRectSide[1].right = textRect.right + 1;
        texRectSide[1].bottom = textRect.bottom - 1;

        texRectSide[2].left = textRect.left + 1;
        texRectSide[2].top = textRect.top + 1;
        texRectSide[2].right = textRect.right + 1;
        texRectSide[2].bottom = textRect.bottom + 1;

        texRectSide[3].left = textRect.left - 1;
        texRectSide[3].top = textRect.top + 1;
        texRectSide[3].right = textRect.right - 1;
        texRectSide[3].bottom = textRect.bottom + 1;
        texRectSide[3].bottom = textRect.bottom + 1;

        SetTextColor(hDC, 0x00000000);
        for (int i = 0; i < 4; i++)
        {
            DrawTextW(hDC, wchTxt, dwLen, &texRectSide[i], .DT_LEFT | .DT_WORDBREAK);
        }

        uint32 r = (dwColor & 0x00FF0000) >> 16;
        uint32 g = (dwColor & 0x0000FF00) >> 8;
        uint32 b = (dwColor & 0x000000FF);

        COLORREF color = RGB!(r, g, b);
        SetTextColor(hDC, color);
        DrawTextW(hDC, wchTxt, dwLen, &textRect, .DT_LEFT | .DT_WORDBREAK);
    }

    static bool GetFontSize(out int32 outWidth, out int32 outHeight, char16* wchString, int32 dwStrLen, HDC hDC)
    {
        SIZE strSize = ?;
        BOOL bGetSize = GetTextExtentPoint32W(hDC, wchString, dwStrLen, &strSize);
        if (bGetSize == 0)
        {
            outWidth = 1;
            outHeight = 1;
            return false;
        }

        outWidth = strSize.cx;
        outHeight = strSize.cy;
        return true;
    }

#endregion GDI

    void CleanupBackBuffer()
    {
        SafeRelease!(m_pDDBack);
    }

    void Cleanup()
    {
        CleanupBackBuffer();

        if (m_pDDPrimary != null)
        {
            m_pDDPrimary.SetClipper(null);
            m_pDDPrimary.Release();
            m_pDDPrimary = null;
        }

        if (m_pClipper != null)
        {
            m_pClipper.Release();
            m_pClipper = null;
        }

        if (m_pDD7 != null)
        {
            uint32 ref_count = m_pDD7.Release();
            if (ref_count != 0)
            {
                Debug.Break();
            }
            m_pDD7 = null;
        }

        if (m_pDD != null)
        {
            uint32 ref_count = m_pDD.Release();
            if (ref_count != 0)
            {
                Debug.Break();
            }
            m_pDD = null;
        }
    }
}

static
{
    public static mixin RGB(var r, var g, var b)
    {
        ((COLORREF)(((uint8)(r) | ((uint16)((uint8)(g)) << 8)) | (((uint32)(uint8)(b)) << 16)))
    }
}