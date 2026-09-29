namespace TextGameFramework_Beef;

public static class StaticData
{
    public const int IMG_WIDTH_FIGHTER_TYPE0 = 5;
    public const int IMG_HEIGHT_FIGHTER_TYPE0 = 5;

    public const int IMG_WIDTH_ENEMY_TYPE0 = 4;
    public const int IMG_HEIGHT_ENEMY_TYPE0 = 4;

    public const int IMG_WIDTH_DESTROYED = 5;
    public const int IMG_HEIGHT_DESTROYED = 5;

    public readonly static char8[25] g_FighterType0 =
        .(
        ' ', ' ', '|', ' ', ' ',
        ' ', '[', '|', ']', ' ',
        ' ', '0', '+', '0', ' ',
        ' ', '0', '+', '0', ' ',
        '<', '0', '+', '0', '>'
        );

    public readonly static char8[16] g_pEnemyType0 =
        .(
        '<', '+', '+', '>',
        '<', '+', '+', '>',
        '<', '+', '+', '>',
        ' ', '|', '|', ' '
        );
    public readonly static char8[25] g_pDetroyed =
        .(
        '*', ' ', ' ', ' ', '*',
        ' ', '*', ' ', '*', ' ',
        ' ', ' ', '*', ' ', ' ',
        ' ', '*', ' ', '*', ' ',
        '*', ' ', ' ', ' ', '*'
        );
}
