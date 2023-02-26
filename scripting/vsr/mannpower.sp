#include <tf2powups>

#define MAX_RUNES_INGAME 30

ArrayList
	hSpawnLocs
;

void MannPower_OnPluginStart()
{
	hSpawnLocs = new ArrayList();

	RegAdminCmd("sm_makerune", CmdMakeRune, ADMFLAG_ROOT);
}

void MannPower_OnRoundStart()
{
	hSpawnLocs.Clear();
	int i = -1;
	while ((i = FindEntityByClassname(i, "item_healthkit_*")) != -1)
		hSpawnLocs.Push(i);

	i = -1;
	while ((i = FindEntityByClassname(i, "item_ammopack_*")) != -1)
		hSpawnLocs.Push(i);

	int loc, rune;
	int len = hSpawnLocs.Length > 8 ? 8 : hSpawnLocs.Length;
	float pos[3];
	for (i = 0; i < len; ++i)
	{
		loc = hSpawnLocs.Get(GetRandomInt(0, hSpawnLocs.Length-1));
		GetEntPropVector(loc, Prop_Send, "m_vecOrigin", pos);

		rune = MakeRune(GetRandRune(), pos);
		SetEntProp(rune, Prop_Send, "m_nSkin", 0);
	}

	SetPawnTimer(DoCreateRune, 30.0);
}

void DoCreateRune()
{
	if (VSH2GameMode.GetPropInt("iRoundState") != StateRunning)	return;

	if (GetRuneInGame() >= MAX_RUNES_INGAME)
	{
		SetPawnTimer(DoCreateRune, 30.0);
		return;
	}

	int pack = hSpawnLocs.Get(GetRandomInt(0, hSpawnLocs.Length-1));
	float pos[3];
	GetEntPropVector(pack, Prop_Send, "m_vecOrigin", pos);
	int rune = MakeRune(GetRandRune(), pos);
	SetEntProp(rune, Prop_Send, "m_nSkin", 0);
	SetPawnTimer(DoCreateRune, 30.0);
}

Action CmdMakeRune(int client, int args)
{
	float pos[3]; GetAimPos(client, pos);

	RuneTypes type;
	if (!args)
		type = GetRandRune();
	else
	{
		char arg[4]; GetCmdArg(1, arg, sizeof(arg));
		type = view_as< RuneTypes >(StringToInt(arg));
	}
	int rune = MakeRune(type, pos);
	SetEntProp(rune, Prop_Send, "m_iTeamNum", -2);
	SetEntProp(rune, Prop_Send, "m_nSkin", 0);
	return Plugin_Handled;
}

public Action TF2_OnRuneSpawn(float pos[3], RuneTypes &type, int &teammaybe, bool &thrown, bool &idk3, float idk4[3])
{
	teammaybe = -2;
	return Plugin_Changed;
}

stock RuneTypes GetRandRune()
{
	int val;
	do
		val = GetRandomInt(0, 11);
		while (val == 10 || val == 8);
	return view_as< RuneTypes >(val);
}

stock int MakeRune(RuneTypes type, float pos[3], float ang[3] = NULL_VECTOR)
{
	int ent = CreateEntityByName("item_powerup_rune");
	TeleportEntity(ent, pos, ang, NULL_VECTOR);
	SetEntData(ent, FindDataMapInfo(ent, "m_iszModel")+24, type);
	DispatchSpawn(ent);
	SetEntData(ent, FindDataMapInfo(ent, "m_iszModel")+24, type);
	AcceptEntityInput(ent, "Enable");
	return ent;
}

stock bool GetAimPos(const int client, float vecPos[3])
{
	float StartOrigin[3], Angles[3];
	GetClientEyeAngles(client, Angles);
	GetClientEyePosition(client, StartOrigin);

	Handle trace = TR_TraceRayFilterEx(StartOrigin, Angles, MASK_NPCSOLID | MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitSelf, client);
	bool didhit = TR_DidHit(trace)
	if (didhit)
		TR_GetEndPosition(vecPos, trace);

	delete trace;
	return didhit;
}

stock int GetRuneInGame()
{
	int count;
	int i = -1;
	while( (i = FindEntityByClassname(i, "item_powerup_rune")) != -1 )
	{
		count++;
	}
	return count;
}