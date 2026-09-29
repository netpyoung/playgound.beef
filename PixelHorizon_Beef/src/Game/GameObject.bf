using PixelHorizon_Beef.ImageData;
using PixelHorizon_Beef.Common;
using PixelHorizon_Beef.Utils;

namespace PixelHorizon_Beef.Game;

static class GameObject
{
    public static FlightObject CreatePlayer(ImageData imageData, int32 x, int32 y, int32 iSpeed)
    {
        FlightObject pNewObject = new FlightObject();
        pNewObject.SetImageData(imageData);
        pNewObject.SetPos((int32)x, (int32)y, false);
        //pNewObject.x = (g_iScreenWidth / 2) - IMG_WIDTH_FIGHTER_TYPE0 / 2;
        //pNewObject.y = (g_iScreenHeight / 2) - IMG_HEIGHT_FIGHTER_TYPE0 / 2;
        pNewObject.SetStatus(.FLIGHT_OBJECT_STATUS_ALIVE);
        pNewObject.SetSpeed(iSpeed);
        return pNewObject;
    }

    public static FlightObject CreateEnemyRandom(ImageData pImgData, int32 iScreenWidth, int32 iScreenHeight, int32 iSpeed)
    {
        FlightObject pNewObject = new FlightObject();
        pNewObject.SetImageData(pImgData);

        int pos_x = Util.Interop.rand() % (iScreenWidth - pImgData.GetWidth());

        pNewObject.SetPos((int32)pos_x, 0, false);
        pNewObject.SetStatus(.FLIGHT_OBJECT_STATUS_ALIVE);
        pNewObject.SetSpeed(iSpeed);

        return pNewObject;
    }

    public static FlightObject CreateAmmo(FlightObject pShooter, ImageData pImgData, int32 iSpeed)
    {
        FlightObject pAmmo = new FlightObject();
        pAmmo.SetImageData(pImgData);
        pAmmo.SetStatus(.FLIGHT_OBJECT_STATUS_ALIVE);

        int2 ivShooterPos = ?;
        pShooter.GetPos(out ivShooterPos);
        pAmmo.SetPos(ivShooterPos.x + pShooter.GetWidth() / 2, ivShooterPos.y, false);
        pAmmo.SetSpeed(iSpeed);

        return pAmmo;
    }

    public static void DeleteFlightObject(FlightObject pObject)
    {
        delete pObject;
    }

    public static void ChangeFlightObjectStatusToDead(FlightObject pObject, uint64 CurTick)
    {
        pObject.SetStatus(.FLIGHT_OBJECT_STATUS_DEAD);
        pObject.SetDeadTick(CurTick);
    }

    public static bool MoveEmemy(FlightObject pObj, int32 iScreenWidth)
    {
        if (pObj.GetStatus() != .FLIGHT_OBJECT_STATUS_ALIVE)
        {
            return false;
        }

        int2 ivPos = ?;
        pObj.GetPos(out ivPos);
        //int move_x = (rand() % 3) - 2;
        //ivPos.x += (move_x * pObj.iSpeed);

        if (ivPos.x < 0)
        {
            ivPos.x = 0;
        }

        if (ivPos.x + pObj.GetWidth() > iScreenWidth)
        {
            ivPos.x -= (ivPos.x + pObj.GetWidth() - iScreenWidth);
        }

        //ivPos.y++;
        //ivPos.y += pObj.iSpeed;
        ivPos.y += 10;
        pObj.SetPos(&ivPos, true);
        return true;
    }
}