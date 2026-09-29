using PixelHorizon_Beef.Common;
using PixelHorizon_Beef.ImageData;
using System;

namespace PixelHorizon_Beef.Game;

enum FLIGHT_OBJECT_STATUS
{
    FLIGHT_OBJECT_STATUS_ALIVE,
    FLIGHT_OBJECT_STATUS_DEAD,
}

class FlightObject
{
    public int2 ivOldPos = .();
    public int2 ivPos = .();
    public int2 ivInterpolatedPos = .();

    ImageData m_pImgData = null;
    FLIGHT_OBJECT_STATUS m_status = .FLIGHT_OBJECT_STATUS_ALIVE;
    uint64 m_DeadTick = 0; // 사망한 시간
    int32 m_iSpeed = 0;

    public uint64 GetDeadTick() { return m_DeadTick; }
    public void SetDeadTick(uint64 Tick) { m_DeadTick = Tick; }
    public FLIGHT_OBJECT_STATUS GetStatus() { return m_status; }
    public void SetStatus(FLIGHT_OBJECT_STATUS status) { m_status = status; }
    public ImageData GetImageData() { return m_pImgData; }
    public void SetImageData(ImageData pImgData) { m_pImgData = pImgData; }
    public int32 GetSpeed() { return m_iSpeed; }
    public void SetSpeed(int32 iSpeed) { m_iSpeed = iSpeed; }

    public int32 GetWidth()
    {
        int32 iWidth = (int32)m_pImgData.GetWidth();
        return iWidth;
    }

    public int32 GetHeight()
    {
        int32 iHeight = (int32)m_pImgData.GetHeight();
        return iHeight;
    }

    public void GetInterpolatedPos(out int2 pivOutPos)
    {
        pivOutPos = ivInterpolatedPos;
    }

    public void GetPos(out int2 pivOutPos)
    {
        pivOutPos = ivPos;
    }

    public void SetPos(int32 x, int32 y, bool bInterpolation)
    {
        if (bInterpolation)
        {
            ivOldPos = ivPos;
            //ivInterpolatedPos = ivPos;
        }
        else
        {
            ivOldPos.x = x;
            ivOldPos.y = y;
            ivInterpolatedPos.x = x;
            ivInterpolatedPos.y = y;
        }
        ivPos.x = x;
        ivPos.y = y;
    }

    public void SetPos(int2* pivPos, bool bInterpolation)
    {
        if (bInterpolation)
        {
            ivOldPos = ivPos;
            //ivInterpolatedPos = ivPos;
        }
        else
        {
            ivOldPos = *pivPos;
            ivInterpolatedPos = *pivPos;
        }
        ivPos = *pivPos;
    }

    public void FixPos()
    {
        ivOldPos = ivPos;
        ivInterpolatedPos = ivPos;
    }

    public void Interpolate(float fAlpha)
    {
        float alpha = Math.Clamp(fAlpha, 0.0f, 1.0f);

        float x_vel = (float)ivPos.x - (float)ivOldPos.x;
        ivInterpolatedPos.x = (int32)((float)ivOldPos.x + x_vel * alpha);

        float y_vel = (float)ivPos.y - (float)ivOldPos.y;
        ivInterpolatedPos.y = (int32)((float)ivOldPos.y + y_vel * alpha);
    }
}