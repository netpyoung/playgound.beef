using System;
using Win32.Foundation;
using Win32.UI.WindowsAndMessaging;
using Win32.UI.Input.KeyboardAndMouse;
using Win32.System.LibraryLoader;
using Win32.Graphics.Gdi;
using Win32;
using PixelHorizon_Beef.Game;
using System.Diagnostics;

namespace PixelHorizon_Beef;

class Program
{
    public static void Main()
    {
        let program = scope Program();
        program.Run();
    }

    static Game s_GAME = new Game() ~ delete _;

    void Run()
    {
        HINSTANCE hInstance = GetModuleHandle(null);
        SHOW_WINDOW_CMD nCmdShow = .SW_SHOW;

        char16[?] className = "className-DDrawSample".ToConstNativeW();
        HWND? hwndOrNull = InitWindow(&className, hInstance, nCmdShow);
        if (hwndOrNull == null)
        {
            return;
        }

        HWND hwnd = hwndOrNull.Value;
        if (!s_GAME.Initialize(hwnd))
        {
            return;
        }

        s_GAME.gameClock.Init(60);

        MSG msg = .();
        while (WM_QUIT != msg.message)
        {
            if (PeekMessage(&msg, 0, 0, 0, .PM_REMOVE) != 0)
            {
                TranslateMessage(&msg);
                DispatchMessage(&msg);
            }
            else
            {
                s_GAME.Process();
            }
        }
    }


    HWND? InitWindow(char16* className, HINSTANCE hInstance, SHOW_WINDOW_CMD nCmdShow)
    {
        if (RegisterClass(hInstance, className) == 0)
        {
            Console.Error.WriteLine($"RegisterClass: {GetLastError()}");
            return null;
        }

        RECT rc = .(0, 0, 640, 480);
        AdjustWindowRect(&rc, .WS_OVERLAPPEDWINDOW, FALSE);
        HWND hwnd = CreateWindowExW(
            .WS_EX_APPWINDOW,
            className,
            TEXT!("DDrawWorld"),
            .WS_OVERLAPPEDWINDOW,
            CW_USEDEFAULT, CW_USEDEFAULT,
            rc.right - rc.left,
            rc.bottom - rc.top,
            0, 0,
            hInstance,
            null);
        if (hwnd == 0)
        {
            Console.Error.WriteLine($"CreateWindowExW: {GetLastError()}");
            return null;
        }

        ShowWindow(hwnd, nCmdShow);
        UpdateWindow(hwnd);

        return hwnd;
    }

    static uint16 RegisterClass(HINSTANCE hInstance, char16* className)
    {
        WNDCLASSEXW wcex = .();
        wcex.cbSize = sizeof(WNDCLASSEXW);
        wcex.style = .CS_HREDRAW | .CS_VREDRAW;
        wcex.lpfnWndProc = => WndProc;
        wcex.cbClsExtra = 0;
        wcex.cbWndExtra = 0;
        wcex.hInstance = hInstance;
        wcex.hIcon = LoadIcon(hInstance, (uint8*)IDI_WINLOGO);
        wcex.hCursor = LoadCursor(0,  (uint8*)IDC_ARROW);
        wcex.hbrBackground = (HBRUSH)(SYS_COLOR_INDEX.COLOR_WINDOW + 1);
        wcex.lpszMenuName = null;
        wcex.lpszClassName = className;
        wcex.hIconSm = LoadIcon(wcex.hInstance, (uint8*)IDI_WINLOGO);

        return RegisterClassExW(&wcex);
    }

    static LRESULT WndProc(HWND hWnd, uint32 message, WPARAM wParam, LPARAM lParam)
    {
        if (!s_GAME.IsInitialized)
        {
            return DefWindowProcW(hWnd, message, wParam, lParam);
        }

        PAINTSTRUCT ps = ?;
        HDC hdc = ?;

        switch (message)
        {
        case WM_SIZE:
            s_GAME.OnUpdateWindowSize();
        case WM_MOVE:
            s_GAME.OnUpdateWindowPos();
            break;
        case WM_KEYDOWN:
            {
                switch (wParam) {
                case (uint)VIRTUAL_KEY.VK_ESCAPE:
                    PostQuitMessage(0);
                }

                uint32	uiScanCode = (0x00FF0000 & (uint32)lParam) >> 16;
                uint32	vkCode = MapVirtualKey(uiScanCode, MAPVK_VSC_TO_VK);
                if ((lParam & 0x40000000) == 0)
                {
                    s_GAME.OnKeyDown(vkCode, uiScanCode);
                }
            }
        case WM_KEYUP:
            {
                uint32 uiScanCode = (0x00FF0000 & (uint32)lParam) >> 16;
                uint32 vkCode = MapVirtualKey(uiScanCode, MAPVK_VSC_TO_VK);
                s_GAME.OnKeyUp(vkCode, uiScanCode);
            }
        case WM_SYSKEYDOWN:
            {
                uint32	uiScanCode = (0x00FF0000 & (uint32)lParam) >> 16;
                uint32	vkCode = MapVirtualKey(uiScanCode, MAPVK_VSC_TO_VK);
                BOOL	bAltKeyDown = FALSE;
                if ((HIWORD!((uint)lParam) & KF_ALTDOWN) != 0)
                {
                    bAltKeyDown = TRUE;
                }
                if (!s_GAME.OnSysKeyDown(vkCode, uiScanCode, bAltKeyDown))
                {
                    DefWindowProcW(hWnd, message, wParam, lParam);
                }
            }
        case WM_PAINT:
            hdc = BeginPaint(hWnd, &ps);
            EndPaint(hWnd, &ps);
        case WM_DESTROY:
            PostQuitMessage(0);
        default:
            return DefWindowProcW(hWnd, message, wParam, lParam);
        }

        return 0;
    }
}

static
{
    [Comptime(ConstEval = true)]
    public static mixin TEXT(var s)
    {
        &s.ToConstNativeW()
    }

    public static mixin SafeRelease(var s)
    {
        if (s != null)
        {
            s.Release();
            s = null;
        }
    }

    public static mixin SafeReleaseEnsureZero(var s)
    {
        if (s != null)
        {
            let referenceCount = s.Release();
            Debug.Assert(referenceCount == 0);
            s = null;
        }
    }

    public static mixin UNREFERENCED_PARAMETER(var s)
    {
    }


    public static mixin HIWORD(uint l)
    {
        (uint16)((l >> 16) & 0xFFFF)
    }
}
