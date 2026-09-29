using Win32.Foundation;
using Win32.System.Performance;
using System;

namespace PixelHorizon_Beef.Utils;

class GameClock
{
    LARGE_INTEGER _performanceFrequency;
    LARGE_INTEGER _performanceCounter_curr;
    LARGE_INTEGER _performanceCounter_prev;

    float _accumulatorForFixedDeltaTime;
    float _accumulatorForFps;
    uint _frameCount;

    public float CurrentFps { get; private set; }
    public uint TargetFps { get; private set; }
    public float DeltaTimeSec { get; private set; }
    public float FixedDeltaTimeSec { get; private set; }
    public bool IsFpsUpdated { get; private set; }
    public float Alpha;

    [Inline]
    public void Init(uint targetFps)
    {
        TargetFps = targetFps;
        FixedDeltaTimeSec = 1.0f / targetFps;

        QueryPerformanceFrequency(&_performanceFrequency);

        QueryPerformanceCounter(&_performanceCounter_curr);
        _performanceCounter_prev = _performanceCounter_curr;
    }

    [Inline]
    public void UpdatePerFrameLoop()
    {
        QueryPerformanceCounter(&_performanceCounter_curr);
        let diff = _performanceCounter_curr.QuadPart - _performanceCounter_prev.QuadPart;
        _performanceCounter_prev = _performanceCounter_curr;

        DeltaTimeSec = (float)diff / (float)_performanceFrequency.QuadPart;

        // to prevent Spiral of Death
        const float MIN_DELTA_TIME_SEC = 0.25f;
        DeltaTimeSec = Math.Min(DeltaTimeSec, MIN_DELTA_TIME_SEC);

        _accumulatorForFixedDeltaTime += DeltaTimeSec;
        _accumulatorForFps += DeltaTimeSec;

        _frameCount++;

        IsFpsUpdated = _accumulatorForFps >= 1.0f;

        if (IsFpsUpdated)
        {
            CurrentFps = (float)_frameCount  / _accumulatorForFps;
            _frameCount = 0;
            _accumulatorForFps -= 1.0f;
        }
    }

    [Inline]
    public bool TryConsumeFixedDeltaTimeSec()
    {
        if (_accumulatorForFixedDeltaTime >= FixedDeltaTimeSec)
        {
            _accumulatorForFixedDeltaTime -= FixedDeltaTimeSec;
            return true;
        }

        Alpha = _accumulatorForFixedDeltaTime / FixedDeltaTimeSec;
        return false;
    }
}