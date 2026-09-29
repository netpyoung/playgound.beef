using System;

namespace TextGameFramework_Beef;

enum FLIGHT_OBJECT_STATUS
{
    FLIGHT_OBJECT_STATUS_ALIVE,
    FLIGHT_OBJECT_STATUS_DEAD,
}

struct FLIGHT_OBJECT
{
    public int x;
    public int y;
    public int Width;
    public int Height;
    public FLIGHT_OBJECT_STATUS status;
    public uint64 DeadTick;
    public Span<char8> pBits;
}

class GameObject
{
    [CLink]
    public static extern int rand();

    public static FLIGHT_OBJECT* CreatePlayer()
    {
        FLIGHT_OBJECT* pNewObject = new FLIGHT_OBJECT();
        pNewObject.pBits = StaticData.g_FighterType0;
        pNewObject.x = (Game.g_iScreenWidth / 2) - StaticData.IMG_WIDTH_FIGHTER_TYPE0 / 2;
        pNewObject.y = (Game.g_iScreenHeight / 2) - StaticData.IMG_HEIGHT_FIGHTER_TYPE0 / 2;
        pNewObject.Width = StaticData.IMG_WIDTH_FIGHTER_TYPE0;
        pNewObject.Height = StaticData.IMG_HEIGHT_FIGHTER_TYPE0;
        pNewObject.status = .FLIGHT_OBJECT_STATUS_ALIVE;

        return pNewObject;
    }

    public static FLIGHT_OBJECT* CreateEnemyRandom()
    {
        FLIGHT_OBJECT* pNewObject = new FLIGHT_OBJECT();
        pNewObject.pBits = StaticData.g_pEnemyType0;

        int pos_x = rand() % (Game.g_iScreenWidth - StaticData.IMG_WIDTH_ENEMY_TYPE0);

        pNewObject.x = pos_x;
        pNewObject.y = 0;
        pNewObject.Width = StaticData.IMG_WIDTH_ENEMY_TYPE0;
        pNewObject.Height = StaticData.IMG_HEIGHT_ENEMY_TYPE0;
        pNewObject.status = .FLIGHT_OBJECT_STATUS_ALIVE;

        return pNewObject;
    }

    public static FLIGHT_OBJECT* CreateAmmo(FLIGHT_OBJECT* pShooter)
    {
        FLIGHT_OBJECT* pAmmo = new FLIGHT_OBJECT();
        pAmmo.Width = 1;
        pAmmo.Height = 1;
        pAmmo.status = .FLIGHT_OBJECT_STATUS_ALIVE;

        pAmmo.x = pShooter.x + pShooter.Width / 2;
        pAmmo.y = pShooter.y - 1;
        pAmmo.pBits = "|";

        return pAmmo;
    }

    public static void DeleteFlightObject(FLIGHT_OBJECT* pObject)
    {
        delete pObject;
    }

    public static void ChangeFlightObjectStatusToDead(FLIGHT_OBJECT* pObject, uint64 CurTick)
    {
        pObject.status = .FLIGHT_OBJECT_STATUS_DEAD;
        pObject.Width = StaticData.IMG_WIDTH_DESTROYED;
        pObject.Height = StaticData.IMG_HEIGHT_DESTROYED;
        pObject.pBits = StaticData.g_pDetroyed;
        pObject.DeadTick = CurTick;
    }

    public static bool MoveEmemy(FLIGHT_OBJECT* pObj)
    {
        if (pObj.status != .FLIGHT_OBJECT_STATUS_ALIVE)
        {
            return false;
        }

        int move_x = (rand() % 3) - 2;
        pObj.x += move_x;

        if (pObj.x < 0)
        {
            pObj.x = 0;
        }
        if (pObj.x + pObj.Width > Game.g_iScreenWidth)
        {
            pObj.x -= (pObj.x + pObj.Width - Game.g_iScreenWidth);
        }
        pObj.y++;
        return true;
    }
}