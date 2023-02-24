#include <vsh2>
#include <tf2attributes>
#include <morecolors>
#include "modules/stocks.inc"

public Plugin myinfo = {
    name        = "VSH2 Special Rounds",
    author      = "HotoCocoaco",
    description = "Surprise! Have a special round.",
    version     = "0.1",
    url         = "https://github.com/HotoCocoaco"
};

enum SpecialRoundType 
{
    SRT_Disabled = -1,
    SRT_BigHead,
    SRT_SmallHead,
    SRT_RandomClass,
    SRT_RandomToOneClass,
    SRT_Jesus,
    SRT_Hammer,
    SRT_BattleRoyale,
    SRT_BombKing,
    SRT_TowerDefense,
};

SpecialRoundType g_VSPState = SRT_Disabled;

public void OnLibraryAdded(const char[] name)
{
    if (StrEqual(name, "VSH2"))
    {
        VSH2_Hook(OnRoundEndInfo, VSR_OnRoundEndInfo);
        VSH2_Hook(OnRoundStart, VSR_OnRoundStart);
    }
}

public void OnLibraryRemoved(const char[] name)
{
    if (StrEqual(name, "VSH2"))
    {
        
    }
}

void VSR_OnRoundEndInfo(const VSH2Player player, bool bossBool, char message[MAXMESSAGE])
{
    g_VSPState = SRT_Disabled;
}

void VSR_OnRoundStart(const VSH2Player[] bosses, const int boss_count, const VSH2Player[] red_players, const int red_count)
{
    switch(g_VSPState)
    {
        case SRT_BigHead:
        {
            int i;
            for(i = 0; i < boss_count; i++)
            {
                TF2Attrib_SetByName(bosses[i].index, "head scale", 2.5);
                TF2Attrib_SetByName(bosses[i].index, "hand scale", 0.5);
            }
            for(i = 0; i < red_count; i++)
            {
                TF2Attrib_SetByName(red_players[i].index, "head scale", 2.5);
                TF2Attrib_SetByName(red_players[i].index, "hand scale", 0.5);
            }

            CPrintToChatAll("{purple}[特殊回合]{default}头变大，手变小。");
        }
        
        case SRT_SmallHead:
        {
            int i;
            for(i = 0; i < boss_count; i++)
            {
                TF2Attrib_SetByName(bosses[i].index, "head scale", 0.5);
                TF2Attrib_SetByName(bosses[i].index, "hand scale", 2.5);
            }
            for(i = 0; i < red_count; i++)
            {
                TF2Attrib_SetByName(red_players[i].index, "head scale", 0.5);
                TF2Attrib_SetByName(red_players[i].index, "hand scale", 2.5);
            }

            CPrintToChatAll("{purple}[特殊回合]{default}手变小，头变大。");
        }

        case SRT_RandomClass:
        {
            if ( IsZZJ() )
            {
                CPrintToChatAll("{purple}[特殊回合]{default}本回合无特殊效果。");
            }
            else
            {
                for(int i = 0; i < red_count; i++)
                {
                    TF2_SetPlayerClass(red_players[i].index, view_as<TFClassType>(GetRandomInt(1, 9)), false);
                }

                CPrintToChatAll("{purple}[特殊回合]{default}每个人随机抽选新的兵种。");
            }
        }

        case SRT_RandomToOneClass:
        {
            if ( IsZZJ() )
            {
                CPrintToChatAll("{purple}[特殊回合]{default}本回合无特殊效果。");
            }
            else
            {
                TFClassType class = view_as<TFClassType>(GetRandomInt(1, 9));
                for(int i = 0; i < red_count; i++)
                {
                    TF2_SetPlayerClass(red_players[i].index, class, false);
                }

                CPrintToChatAll("{purple}[特殊回合]{default}所有人变成随机的一个兵种。");
            }
        }

        case SRT_Jesus:
        {
            int theone = GetRandomInt(0, red_count);
            int client = red_players[theone].index;
            TF2_SetPlayerPowerPlay(client, true);
            SetPawnTimer(ResetPowerPlay, 240.0, EntIndexToEntRef(client));

            CPrintToChatAll("{purple}[特殊回合]{default}红队获得一个救世主，");
        }

        case SRT_Hammer:
        {

            CPrintToChatAll("{purple}[特殊回合]{default}每30秒会有重锤落下。");
        }

        case SRT_BattleRoyale:
        {

            CPrintToChatAll("{purple}[特殊回合]{default}可行动的区域会不断缩小。");
        }
        
        case SRT_BombKing:
        {

            CPrintToChatAll("{purple}[特殊回合]{default}每45秒生成一颗炸弹。用近战攻击敌人或队友来转移炸弹。");
        }

        case SRT_TowerDefense:
        {
            int target;
            GetRandomClient(true, VSH2Team_Boss);
            float pos[3];   GetClientAbsOrigin(target, pos);
            BuildSentry(VSH2Team_Boss, 3, 0, 900, pos);

            target = GetRandomClient(true, VSH2Team_Red);
            GetClientAbsOrigin(target, pos);
            BuildSentry(VSH2Team_Red, 3, 0, 500, pos);
            
            CPrintToChatAll("{purple}[特殊回合]{default}红蓝队重生点获得一个步哨枪。");
        }
    }
}

void ResetPowerPlay(int ref)
{
    int client = EntRefToEntIndex(ref);
    if ( client != INVALID_ENT_REFERENCE )
    {
        TF2_SetPlayerPowerPlay(client, false);
    }
}

// 用于检测当前是否有终结者在场。
bool IsZZJ()
{
    int zjz = VSH2_GetBossID("vsh2_boss_cfzombie");
    if (zjz != -1)
    {
        if ( VSH2GameMode_GetBossByType(true, zjz) )
        {
            return true;
        }
    }
    return false;
}

// 建造一个步哨枪
int BuildSentry(int team, int level, int soild, int health, float pos[3])
{
    int sentry = CreateEntityByName("obj_sentrygun");
    if (sentry != INVALID_ENT_REFERENCE)
    {
        SetEntProp(sentry, Prop_Send, "m_iTeamNum", team);
        SetEntProp(sentry, Prop_Send, "m_nSkin", team-2);
        DispatchKeyValueInt(sentry, "defaultupgrade", level);

        SetVariantInt(0);
        AcceptEntityInput(sentry, "SetSolidToPlayer");

        SetEntProp(sentry, Prop_Send, "m_iAmmoShells", 999);
        SetEntProp(sentry, Prop_Send, "m_iAmmoRockets", 999);

        SetEntProp(sentry, Prop_Send, "m_iHealth", health);
        SetEntProp(sentry, Prop_Send, "m_iMaxHealth", health);
        SetEntProp(sentry, Prop_Send, "m_iObjectType", _:TFObject_Sentry);

        DispatchSpawn(sentry);
        TeleportEntity(sentry, pos);
        SetEntityModel(sentry, "models/buildables/sentry3.mdl");

        return sentry;
    }
    
    return -1;
}
