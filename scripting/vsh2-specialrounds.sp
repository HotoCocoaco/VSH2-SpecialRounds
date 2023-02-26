#include <vsh2>
#include <sdkhooks>
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

#define KILL_ENT_IN(%1,%2) \
    SetVariantString("OnUser1 !self:Kill::" ... #%2 ... ":1"); \
    AcceptEntityInput(%1, "AddOutput"); \
    AcceptEntityInput(%1, "FireUser1");

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
    SRT_MannPower,
    SRT_Survival,
};

SpecialRoundType g_VSPState = SRT_Disabled;
Handle g_hHUDText;
int g_iBomgKingUserid;
FwdTime g_fwdBomgKingTime;
FwdTime g_fwdSurvivalTime;
bool g_bSurvivalEnabled;

#include "vsr/dome.sp"
#include "vsr/mannpower.sp"
#include "vsr/survival.sp"

public void OnPluginStart()
{
    g_hHUDText = CreateHudSynchronizer();
    RegAdminCmd("sm_setvsp", SetVSPState, ADMFLAG_CHEATS, "ChangeVSPState");
    MannPower_OnPluginStart();
}

Action SetVSPState(int client, int args)
{
    if (VSH2GameMode.GetPropInt("iRoundState") == StateRunning)
    {
        ReplyToCommand(client, "现在不可设置VSP状态。");
        return Plugin_Stop;
    }

    int value = -1;
    if ( !GetCmdArgIntEx(1, value) )
    {
        ReplyToCommand(client, "无效值。");
        return Plugin_Stop;
    }

    g_VSPState = view_as<SpecialRoundType>(value);
    ReplyToCommand(client, "已更改VSPState为: %i", view_as<int>(g_VSPState));
    return Plugin_Stop;
}

public void OnLibraryAdded(const char[] name)
{
    if (StrEqual(name, "VSH2"))
    {
        VSH2_Hook(OnRoundEndInfo, VSR_OnRoundEndInfo);
        VSH2_Hook(OnRoundStart, VSR_OnRoundStart);
        VSH2_Hook(OnCallDownloads, VSR_OnCallDownloads);
        VSH2_Hook(OnTraceAttack, VSR_OnTraceAttack);
        VSH2_Hook(OnBossThinkPost, VSR_OnBossThinkPost);
        VSH2_Hook(OnSoundHook, VSR_OnSoundHook);
    }
}

public void OnLibraryRemoved(const char[] name)
{
    if (StrEqual(name, "VSH2"))
    {
        VSH2_Unhook(OnRoundEndInfo, VSR_OnRoundEndInfo);
        VSH2_Unhook(OnRoundStart, VSR_OnRoundStart);
        VSH2_Unhook(OnCallDownloads, VSR_OnCallDownloads);
        VSH2_Unhook(OnTraceAttack, VSR_OnTraceAttack);
        VSH2_Unhook(OnBossThinkPost, VSR_OnBossThinkPost);
        VSH2_Unhook(OnSoundHook, VSR_OnSoundHook);
    }
}

void VSR_OnRoundEndInfo(const VSH2Player player, bool bossBool, char message[MAXMESSAGE])
{
    switch(g_VSPState)
    {
        case SRT_MannPower:
        {
            GameRules_SetProp("m_bPowerupMode", 0);
            FindConVar("tf_grapplinghook_enable").SetInt(0);
        }

        case SRT_Survival:
        {
            g_bSurvivalEnabled = false;
        }
    }
    
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
                SetEntPropFloat(bosses[i].index, Prop_Send, "m_flHeadScale", 2.5);
                SetEntPropFloat(bosses[i].index, Prop_Send, "m_flHandScale", 0.5);
            }
            for(i = 0; i < red_count; i++)
            {
                SetEntPropFloat(red_players[i].index, Prop_Send, "m_flHeadScale", 2.5);
                SetEntPropFloat(red_players[i].index, Prop_Send, "m_flHandScale", 0.5);
            }

            CPrintToChatAll("{purple}[特殊回合]{default}头变大，手变小。");
        }
        
        case SRT_SmallHead:
        {
            int i;
            for(i = 0; i < boss_count; i++)
            {
                SetEntPropFloat(bosses[i].index, Prop_Send, "m_flHeadScale", 0.5);
                SetEntPropFloat(bosses[i].index, Prop_Send, "m_flHandScale", 2.5);
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
            CreateTimer(45.0, HammerTime, _, TIMER_REPEAT);
            CPrintToChatAll("{purple}[特殊回合]{default}每隔一段时间会有重锤落下。");
        }

        case SRT_BattleRoyale:
        {
            Dome_OnRoundStart();
            CPrintToChatAll("{purple}[特殊回合]{default}可行动的区域会不断缩小。");
        }
        
        case SRT_BombKing:
        {
            CreateTimer(5.0, BombKing, _, TIMER_REPEAT);
            CPrintToChatAll("{purple}[特殊回合]{default}用近战攻击敌人或队友来转移炸弹。");
        }

        case SRT_TowerDefense:
        {
            int target;
            target = GetRandomClient(true, VSH2Team_Boss);
            float pos[3];   GetClientAbsOrigin(target, pos);
            float ang[3];   GetClientAbsAngles(target, ang);
            SpawnSentry(target, pos, ang, 3, false, false, 8);

            target = GetRandomClient(true, VSH2Team_Red);
            GetClientAbsOrigin(target, pos);
            GetClientAbsAngles(target, ang);
            SpawnSentry(target, pos, ang, 3, false, false, 8);
            
            CPrintToChatAll("{purple}[特殊回合]{default}红蓝队重生点获得一个步哨枪。");
        }

        case SRT_MannPower:
        {
            FindConVar("tf_grapplinghook_enable").SetInt(1);
            GameRules_SetProp("m_bPowerupMode", 1);

            int i;
            for(i = 0; i < boss_count; i++)
            {
                bosses[i].SpawnWeapon("tf_weapon_grapplinghook", 1152, 1, 10, "241 ; 0 ; 280 ; 26 ; 712 ; 1");
            }
            for(i = 0; i < red_count; i++)
            {
                TF2_RemoveWeaponSlot(red_players[i].index, 6);
                red_players[i].SpawnWeapon("tf_weapon_grapplinghook", 1152, 1, 10, "241 ; 0 ; 280 ; 26 ; 712 ; 1");
            }

            MannPower_OnRoundStart();

            CPrintToChatAll("{purple}[特殊回合]{default}获得钩爪，地图生成增益道具。注意，重生点内的增益道具无法捡起。");
        }

        case SRT_Survival:
        {
            float time = 25.0 * float(red_count);
            g_fwdSurvivalTime.Update(time);
            g_bSurvivalEnabled = true;

            CPrintToChatAll("{purple}[特殊回合]{default}BOSS的愤怒值会自行增加，红队生存指定时间之后即可胜利。");
        }
    }
}

void VSR_OnCallDownloads()
{
    PrecacheModel("models/props_halloween/hammer_gears_mechanism.mdl");
    PrecacheModel("models/props_halloween/hammer_mechanism.mdl");
    PrecacheModel("models/props_halloween/bell_button.mdl");

    PrecacheSound("misc/halloween/strongman_fast_impact_01.wav");
    PrecacheSound("ambient/explosions/explode_1.wav");
    PrecacheSound("misc/halloween/strongman_fast_whoosh_01.wav");
    PrecacheSound("misc/halloween/strongman_fast_swing_01.wav");
    PrecacheSound("doors/vent_open2.wav");

    PrecacheSound("mvm/sentrybuster/mvm_sentrybuster_intro.wav");
    PrecacheSound("mvm/sentrybuster/mvm_sentrybuster_loop.wav");

    Dome_MapStart();
}

void VSR_OnBossThinkPost(VSH2Player player)
{
    if (VSH2GameMode.GetPropInt("iRoundState") != StateRunning) return;

    switch(g_VSPState)
    {        
        case SRT_BombKing:
        {
            if (g_iBomgKingUserid == -1) return;
            
            int client = GetClientOfUserId(g_iBomgKingUserid);
            if (!client)
            {
                g_iBomgKingUserid = -1;
                return;
            }

            if (!IsPlayerAlive(client))
            {
                g_iBomgKingUserid = -1;
                return;
            }
            
            if ( g_fwdBomgKingTime.WithinTime() )
            {
                SetHudTextParams(-1.0, 0.58, 0.11, 255, 0, 0, 255);
                ShowSyncHudText(client, g_hHUDText, "%.1f秒\n你身上有炸弹！近战攻击任何人来传递炸弹！", g_fwdBomgKingTime.Elapsed());
            }   else    {
                g_iBomgKingUserid = -1;
                float pos[3];   GetClientAbsOrigin(client, pos);
                DoExplosion(client, 700, 100, pos);
                StopSound(client, SNDCHAN_AUTO, "mvm/sentrybuster/mvm_sentrybuster_loop.wav");
            }
        }

        case SRT_Survival:
        {
            SetHudTextParams(-1.0, 0.2, 0.11, 255, 255, 255, 255);
            if (g_bSurvivalEnabled)
            {
                for(int i = 1; i <= MaxClients; i++)
                {
                    if ( IsClientInGame(i) )
                    {
                        ShowSyncHudText(i, g_hHUDText, "生存模式：%.0f秒", g_fwdSurvivalTime.Elapsed());
                    }
                }

                if (!g_fwdSurvivalTime.WithinTime())
                {
                    ForceTeamWin(VSH2Team_Red);
                    g_bSurvivalEnabled = false;
                }   else    {
                    player.SetPropFloat("flRAGE", player.GetPropFloat("flRAGE") + 0.02);
                }
            }
        }
    }
}

void VSR_OnTraceAttack(const VSH2Player victim, const VSH2Player attacker, int& inflictor, float& damage, int& damagetype, int& ammotype, int hitbox, int hitgroup)
{
    switch(g_VSPState)
    {
        case SRT_BombKing:
        {
            if (g_iBomgKingUserid == -1) return;

            if ( attacker.userid == g_iBomgKingUserid && g_fwdBomgKingTime.WithinTime() && IsWeaponSlotActive(attacker.index, TFWeaponSlot_Melee) )
            {
                g_iBomgKingUserid = victim.userid;
                if ( g_fwdBomgKingTime.Elapsed() < 5.0 )  {
                    g_fwdBomgKingTime.Update(5.0);
                }
                StopSound(attacker.index, SNDCHAN_AUTO, "mvm/sentrybuster/mvm_sentrybuster_loop.wav");
                EmitSoundToClient(victim.index, "mvm/sentrybuster/mvm_sentrybuster_intro.wav");
                EmitSoundToClient(victim.index, "mvm/sentrybuster/mvm_sentrybuster_loop.wav");
            }
        }
    }
}

void VSR_OnSoundHook(const VSH2Player player, char sample[PLATFORM_MAX_PATH], int& channel, float& volume, int& level, int& pitch, int& flags)
{
    switch(g_VSPState)
    {
        case SRT_BigHead:
        {
            if (!player.bIsBoss)
            {
                if (!StrContains(sample, "vo/"))
                {
                    pitch = RoundToNearest((175.0 / (1.0 + (6.0 * 2.5))) + 75.0);
                }
            }
        }

        case SRT_SmallHead:
        {
            if (!player.bIsBoss)
            {
                if (!StrContains(sample, "vo/"))
                {
                    pitch = RoundToNearest((175.0 / (1.0 + (6.0 * 0.5))) + 75.0);
                }
            }
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



// 炸弹王计时器
Action BombKing(Handle timer)
{
    if (VSH2GameMode.GetPropInt("iRoundState") != StateRunning) return Plugin_Stop;

    if (g_iBomgKingUserid != -1)    return Plugin_Continue;

    int client = GetRandomClient(true, VSH2Team_Red);
    g_iBomgKingUserid = GetClientUserId(client);
    g_fwdBomgKingTime.Update(25.0);
    EmitSoundToClient(client, "mvm/sentrybuster/mvm_sentrybuster_intro.wav");
    EmitSoundToClient(client, "mvm/sentrybuster/mvm_sentrybuster_loop.wav");

    return Plugin_Continue;
}

// 锤子时间代码。Most codes yoink from Pelipoika & RTD2
Action HammerTime(Handle timer)
{
    if (VSH2GameMode.GetPropInt("iRoundState") != StateRunning) return Plugin_Stop;

    int target;
    if ( GetRandomBool() )
    {
        target = GetRandomClient(true, VSH2Team_Red);
    }
    else
    {
        target = GetRandomClient(true, VSH2Team_Boss);
    }

    if (target != -1)
    {
        NecroMash_Call(target);
        SetHudTextParams(-1.0, 0.58, 3.0, 255, 0, 0, 255);
        for(int i = 0; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && IsPlayerAlive(i))
            {
                ShowSyncHudText(i, g_hHUDText, "※锤子来袭※");
            }
        }
    }

    return Plugin_Continue;
}


void NecroMash_Call(int client)
{
    if(GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") > -1)
        NecroMash_SmashClient(client);
    else CreateTimer(0.1, Timer_NecroMash_Retry, GetClientUserId(client), TIMER_REPEAT);
}

Action Timer_NecroMash_Retry(Handle hTimer, int iUserId)
{
    int client = GetClientOfUserId(iUserId);
    if(!client) return Plugin_Stop;

    if(GetEntProp(client, Prop_Send, "m_hGroundEntity") < 0)
        return Plugin_Continue;

    NecroMash_SmashClient(client);
    return Plugin_Stop;
}

void NecroMash_SmashClient(int client)
{
    float flPos[3], flPpos[3], flAngles[3];
    GetClientAbsOrigin(client, flPos);
    GetClientAbsOrigin(client, flPpos);
    GetClientEyeAngles(client, flAngles);
    flAngles[0] = 0.0;

    float vForward[3];
    GetAngleVectors(flAngles, vForward, NULL_VECTOR, NULL_VECTOR);
    flPos[0] -= (vForward[0] * 750);
    flPos[1] -= (vForward[1] * 750);
    flPos[2] -= (vForward[2] * 750);

    flPos[2] += 350.0;
    int gears = CreateEntityByName("prop_dynamic");
    if(IsValidEntity(gears)){
        DispatchKeyValueVector(gears, "origin", flPos);
        DispatchKeyValueVector(gears, "angles", flAngles);
        DispatchKeyValue(gears, "model", "models/props_halloween/hammer_gears_mechanism.mdl");
        DispatchSpawn(gears);
    }

    int hammer = CreateEntityByName("prop_dynamic");
    if(IsValidEntity(hammer)){
        DispatchKeyValueVector(hammer, "origin", flPos);
        DispatchKeyValueVector(hammer, "angles", flAngles);
        DispatchKeyValue(hammer, "model", "models/props_halloween/hammer_mechanism.mdl");
        DispatchSpawn(hammer);
    }

    int button = CreateEntityByName("prop_dynamic");
    if(IsValidEntity(button)){
        flPos[0] += (vForward[0] * 600);
        flPos[1] += (vForward[1] * 600);
        flPos[2] += (vForward[2] * 600);

        flPos[2] -= 100.0;
        flAngles[1] += 180.0;

        DispatchKeyValueVector(button, "origin", flPos);
        DispatchKeyValueVector(button, "angles", flAngles);
        DispatchKeyValue(button, "model", "models/props_halloween/bell_button.mdl");
        DispatchSpawn(button);

        Handle pack;
        CreateDataTimer(1.3, Timer_NecroMash_Hit, pack);
        WritePackFloat(pack, flPpos[0]); //Position of effects
        WritePackFloat(pack, flPpos[1]); //Position of effects
        WritePackFloat(pack, flPpos[2]); //Position of effects

        Handle pack2;
        CreateDataTimer(1.0, Timer_NecroMash_Whoosh, pack2);
        WritePackFloat(pack2, flPpos[0]); //Position of effects
        WritePackFloat(pack2, flPpos[1]); //Position of effects
        WritePackFloat(pack2, flPpos[2]); //Position of effects

        EmitSoundToAll("misc/halloween/strongman_fast_swing_01.wav", _, _, _, _, _, _, _, flPpos);
    }

    SetVariantString("OnUser2 !self:SetAnimation:smash:0:1");
    AcceptEntityInput(gears, "AddOutput");
    AcceptEntityInput(gears, "FireUser2");

    SetVariantString("OnUser2 !self:SetAnimation:smash:0:1");
    AcceptEntityInput(hammer, "AddOutput");
    AcceptEntityInput(hammer, "FireUser2");

    SetVariantString("OnUser2 !self:SetAnimation:hit:1.3:1");
    AcceptEntityInput(button, "AddOutput");
    AcceptEntityInput(button, "FireUser2");

    KILL_ENT_IN(gears,5.0)
    KILL_ENT_IN(hammer,5.0)
    KILL_ENT_IN(button,5.0)
}

Action Timer_NecroMash_Hit(Handle timer, any pack)
{
    ResetPack(pack);

    float pos[3];
    pos[0] = ReadPackFloat(pack);
    pos[1] = ReadPackFloat(pack);
    pos[2] = ReadPackFloat(pack);

    int shaker = CreateEntityByName("env_shake");
    if(shaker != -1){
        DispatchKeyValue(shaker, "amplitude", "10");
        DispatchKeyValue(shaker, "radius", "1500");
        DispatchKeyValue(shaker, "duration", "1");
        DispatchKeyValue(shaker, "frequency", "2.5");
        DispatchKeyValue(shaker, "spawnflags", "4");
        DispatchKeyValueVector(shaker, "origin", pos);

        DispatchSpawn(shaker);
        AcceptEntityInput(shaker, "StartShake");

        KILL_ENT_IN(shaker,1.0)
    }

    EmitSoundToAll("ambient/explosions/explode_1.wav", _, _, _, _, _, _, _, pos);
    EmitSoundToAll("misc/halloween/strongman_fast_impact_01.wav", _, _, _, _, _, _, _, pos);

    float pos2[3], Vec[3], AngBuff[3];
    for(int i = 1; i <= MaxClients; i++){
        if(IsClientInGame(i) && IsPlayerAlive(i)){
            GetClientAbsOrigin(i, pos2);
            if(GetVectorDistance(pos, pos2) <= 500.0){
                MakeVectorFromPoints(pos, pos2, Vec);
                GetVectorAngles(Vec, AngBuff);
                AngBuff[0] -= 30.0;
                GetAngleVectors(AngBuff, Vec, NULL_VECTOR, NULL_VECTOR);
                NormalizeVector(Vec, Vec);
                ScaleVector(Vec, 500.0);
                Vec[2] += 250.0;
                TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, Vec);
            }

            if(GetVectorDistance(pos, pos2) <= 60.0)
                SDKHooks_TakeDamage(i, i, i, 900.0, DMG_CLUB|DMG_ALWAYSGIB|DMG_BLAST);
        }
    }

    pos[2] += 10.0;
    NecroMash_CreateParticle("hammer_impact_button", pos);
    NecroMash_CreateParticle("hammer_bones_kickup", pos);

    return Plugin_Stop;
}

Action Timer_NecroMash_Whoosh(Handle timer, any pack)
{
    ResetPack(pack);

    float pos[3];
    pos[0] = ReadPackFloat(pack);
    pos[1] = ReadPackFloat(pack);
    pos[2] = ReadPackFloat(pack);

    EmitSoundToAll("misc/halloween/strongman_fast_whoosh_01.wav", _, _, _, _, _, _, _, pos);

    return Plugin_Stop;
}

stock void NecroMash_CreateParticle(char[] particle, float pos[3])
{
    int tblidx = FindStringTable("ParticleEffectNames");
    char tmp[256];
    int count = GetStringTableNumStrings(tblidx);
    int stridx = INVALID_STRING_INDEX;

    for(int i = 0; i < count; i++){
        ReadStringTable(tblidx, i, tmp, sizeof(tmp));
        if(StrEqual(tmp, particle, false)){
            stridx = i;
            break;
        }
    }

    for(int i = 1; i <= MaxClients; i++){
        if(!IsValidEntity(i)) continue;
        if(!IsClientInGame(i)) continue;
        TE_Start("TFParticleEffect");
        TE_WriteFloat("m_vecOrigin[0]", pos[0]);
        TE_WriteFloat("m_vecOrigin[1]", pos[1]);
        TE_WriteFloat("m_vecOrigin[2]", pos[2]);
        TE_WriteNum("m_iParticleSystemIndex", stridx);
        TE_WriteNum("entindex", -1);
        TE_WriteNum("m_iAttachType", 2);
        TE_SendToClient(i, 0.0);
    }
}

// 建造一个超牛逼步哨枪
stock int SpawnSentry(int builder, float Position[3], float Angle[3], int level, bool mini=false, bool disposable=false, int flags=4){

	float m_vecMinsMini[3] = {-15.0, -15.0, 0.0}, m_vecMaxsMini[3] = {15.0, 15.0, 49.5};
	float m_vecMinsDisp[3] = {-13.0, -13.0, 0.0}, m_vecMaxsDisp[3] = {13.0, 13.0, 42.9};

	int sentry = CreateEntityByName("obj_sentrygun");

	if(!IsValidEntity(sentry)) return 0;

	int iTeam = GetClientTeam(builder);

	//SetEntPropEnt(sentry, Prop_Send, "m_hBuilder", builder);

	SetVariantInt(iTeam);
	AcceptEntityInput(sentry, "SetTeam");

	DispatchKeyValueVector(sentry, "origin", Position);
	DispatchKeyValueVector(sentry, "angles", Angle);

	if(mini){
		SetEntProp(sentry, Prop_Send, "m_bMiniBuilding", 1);
		SetEntProp(sentry, Prop_Send, "m_iUpgradeLevel", level);
		SetEntProp(sentry, Prop_Send, "m_iHighestUpgradeLevel", level);
		SetEntProp(sentry, Prop_Data, "m_spawnflags", flags);
		SetEntProp(sentry, Prop_Send, "m_bBuilding", 1);
		SetEntProp(sentry, Prop_Send, "m_nSkin", level == 1 ? iTeam : iTeam -2);
		DispatchSpawn(sentry);

		SetVariantInt(100);
		AcceptEntityInput(sentry, "SetHealth");

		SetEntPropFloat(sentry, Prop_Send, "m_flModelScale", 0.75);
		SetEntPropVector(sentry, Prop_Send, "m_vecMins", m_vecMinsMini);
		SetEntPropVector(sentry, Prop_Send, "m_vecMaxs", m_vecMaxsMini);
	}else if(disposable){
		SetEntProp(sentry, Prop_Send, "m_bMiniBuilding", 1);
		SetEntProp(sentry, Prop_Send, "m_bDisposableBuilding", 1);
		SetEntProp(sentry, Prop_Send, "m_iUpgradeLevel", level);
		SetEntProp(sentry, Prop_Send, "m_iHighestUpgradeLevel", level);
		SetEntProp(sentry, Prop_Data, "m_spawnflags", flags);
		SetEntProp(sentry, Prop_Send, "m_bBuilding", 1);
		SetEntProp(sentry, Prop_Send, "m_nSkin", level == 1 ? iTeam : iTeam -2);
		DispatchSpawn(sentry);

		SetVariantInt(100);
		AcceptEntityInput(sentry, "SetHealth");

		SetEntPropFloat(sentry, Prop_Send, "m_flModelScale", 0.60);
		SetEntPropVector(sentry, Prop_Send, "m_vecMins", m_vecMinsDisp);
		SetEntPropVector(sentry, Prop_Send, "m_vecMaxs", m_vecMaxsDisp);
	}else{
		SetEntProp(sentry, Prop_Send, "m_iUpgradeLevel", level);
		SetEntProp(sentry, Prop_Send, "m_iHighestUpgradeLevel", level);
		SetEntProp(sentry, Prop_Data, "m_spawnflags", flags);
		SetEntProp(sentry, Prop_Send, "m_bBuilding", 1);
		SetEntProp(sentry, Prop_Send, "m_nSkin", iTeam -2);
		DispatchSpawn(sentry);
	}
	return sentry;
}