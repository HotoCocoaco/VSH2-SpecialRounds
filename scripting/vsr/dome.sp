#define DOME_PROP_RADIUS 10000.0	//Dome prop radius, exactly 10k weeeeeeeeeeee

#define DOME_FADE_START_MULTIPLIER 0.7
#define DOME_FADE_ALPHA_MAX 64

#define DOME_START_SOUND "vsh_rewrite/cp_unlocked.mp3"
#define DOME_NEARBY_SOUND "ui/medic_alert.wav"
#define DOME_PERPARE_DURATION 4.5

// Configs
#define DOME_RADIUS_START 7000.0
#define DOME_RADIUS_END 1200.0

// CP
float g_vecDomeCP[3];	//Pos of CP

//Dome prop
int g_iDomeEntRef;
int g_iDomeColor[4] = {255, 255, 255, 255};

float g_flDomeRadius = 0.0;
bool g_bDomePlayerOutside[MAXPLAYERS+1];
Handle g_hDomeTimerBleed = null;

StaticTime g_staticDomeStartTime;
float g_fPlayerOutDomeTime[MAXPLAYERS+1];

void Dome_MapStart()
{
    //Huge prop
    PrepareModel("models/kirillian/brsphere_huge.mdl");
    PrepareMaterial("materials/models/kirillian/brsphere/br_fog");
    PrepareSound(DOME_START_SOUND);
    PrecacheSound(DOME_NEARBY_SOUND);
}

void Dome_OnRoundStart()
{
    g_iDomeEntRef = 0;

    g_staticDomeStartTime.Update();
    g_flDomeRadius = 0.0;
    g_hDomeTimerBleed = null;

    for(int i = 1; i <= MaxClients; i++)
    {
        g_bDomePlayerOutside[i] = false
        g_fPlayerOutDomeTime[i] = 0.0;
    }

    int CPm = -1;
    while( (CPm = FindEntityByClassname(CPm, "team_control_point")) != -1 ) {
        if( CPm > MaxClients && IsValidEntity(CPm) )
        {
            GetEntPropVector(CPm, Prop_Send, "m_vecOrigin", g_vecDomeCP);
        }
    }

    Dome_Start();
}

bool Dome_Start(int iCP = 0)
{
    int dome = CreateEntityByName("prop_dynamic");
    if (dome <= MaxClients) return false;

    if (iCP <= MaxClients)
    {
        iCP = FindEntityByClassname(-1, "team_control_point");
        if (iCP <= MaxClients)  return false;
    }

    g_flDomeRadius = DOME_RADIUS_START;

    DispatchKeyValueVector(dome, "origin", g_vecDomeCP);
    DispatchKeyValue(dome, "model", "models/kirillian/brsphere_huge.mdl");
    DispatchKeyValue(dome, "disableshadows", "1");
    SetEntPropFloat(dome, Prop_Send, "m_flModelScale", SquareRoot(g_flDomeRadius / DOME_PROP_RADIUS));

    DispatchSpawn(dome);

    SetEntityRenderMode(dome, RENDER_TRANSCOLOR);
    SetEntityRenderColor(dome, 255, 255, 255, 0);
    EmitSoundToAll(DOME_START_SOUND);
    g_staticDomeStartTime.Update();
    
    g_iDomeEntRef = EntIndexToEntRef(dome);
    RequestFrame(Dome_Frame_Prepare);
    return true;
}

void Dome_Frame_Prepare()
{
    if (g_VSPState != SRT_BattleRoyale) return;
    
    int iDome = EntRefToEntIndex(g_iDomeEntRef);
    if (!IsValidEntity(iDome)) return;

    if (g_staticDomeStartTime.WithinTime(DOME_PERPARE_DURATION))
    {
        float flRender = g_staticDomeStartTime.Elapsed();
        while (flRender > 1.0) flRender -= 1.0;

        if (flRender > 0.5) flRender = (1.0 - flRender);

        flRender *= 2 * 255.0;
        SetEntityRenderColor(iDome, 255, 255, 255, RoundToFloor(flRender));
        
        //Create fade to players near/outside of dome
        for(int iClient = 1; iClient <= MaxClients; iClient++)
        {
            if ( IsClientInGame(iClient) && IsPlayerAlive(iClient) )
            {
                TFTeam team = TF2_GetClientTeam(iClient);
                if (team <= TFTeam_Spectator) continue;

                // 0.0 = centre of CP
                //<1.0 = inside dome
                // 1.0 = at border of dome
                //>1.0 = outside of dome
                float flDistanceMultiplier = Dome_GetDistance(iClient) / g_flDomeRadius;

                if (flDistanceMultiplier > DOME_FADE_START_MULTIPLIER)
                {
                    float flAlpha;
                    if (flDistanceMultiplier > 1.0)
                        flAlpha = DOME_FADE_ALPHA_MAX * (flRender/255.0);
                    else
                        flAlpha = (flDistanceMultiplier - DOME_FADE_START_MULTIPLIER) * (1.0/(1.0-DOME_FADE_START_MULTIPLIER)) * DOME_FADE_ALPHA_MAX * (flRender/255.0);

                    CreateFade(iClient, _, g_iDomeColor[0], g_iDomeColor[1], g_iDomeColor[2], RoundToNearest(flAlpha));
                }
            }
        }
        RequestFrame(Dome_Frame_Prepare);
    }
    else
    {
        //Start the shrink
        SetEntityRenderColor(iDome, g_iDomeColor[0], g_iDomeColor[1], g_iDomeColor[2], g_iDomeColor[3]);
        g_hDomeTimerBleed = CreateTimer(0.5, Dome_TimerBleed, _, TIMER_REPEAT);
        g_staticDomeStartTime.Update();
        RequestFrame(Dome_Frame_Shrink);
    }
}

void Dome_Frame_Shrink()
{
    if (VSH2GameMode.GetPropInt("iRoundState") != StateRunning) return;
    
    if (g_VSPState != SRT_BattleRoyale) return;
    int iDome = EntRefToEntIndex(g_iDomeEntRef);
    if (!IsValidEntity(iDome)) return;

    Dome_UpdateRadius();
    SetEntPropFloat(iDome, Prop_Send, "m_flModelScale", SquareRoot(g_flDomeRadius / DOME_PROP_RADIUS));

    //Give client bleed if outside of dome
    for (int iClient = 1; iClient <= MaxClients; iClient++)
    {
        if (IsClientInGame(iClient) && IsPlayerAlive(iClient))
        {
            // 0.0 = centre of CP
            //<1.0 = inside dome
            // 1.0 = at border of dome
            //>1.0 = outside of dome
            TFTeam nTeam = TF2_GetClientTeam(iClient);
            float flDistanceMultiplier = Dome_GetDistance(iClient) / g_flDomeRadius;

            if (flDistanceMultiplier > 1.0 && nTeam > TFTeam_Spectator)
            {
                //Client is outside of dome, state that player is outside of dome
                g_bDomePlayerOutside[iClient] = true;

                //Add time on how long player have been outside of dome
                g_fPlayerOutDomeTime[iClient] += g_staticDomeStartTime.Elapsed();

                //give bleed if havent been given one
                if (!TF2_IsPlayerInCondition(iClient, TFCond_Bleeding))
                    TF2_MakeBleed(iClient, iClient, 9999.0);	//Does no damage, ty sourcemod
            }
            else if (g_bDomePlayerOutside[iClient])
            {
                //Client is not outside of dome, remove bleed
                TF2_RemoveCondition(iClient, TFCond_Bleeding);
                g_bDomePlayerOutside[iClient] = false;
            }

            //Create fade
            if (flDistanceMultiplier > DOME_FADE_START_MULTIPLIER && nTeam > TFTeam_Spectator)
            {
                float flAlpha;
                if (flDistanceMultiplier > 1.0)
                    flAlpha = float(DOME_FADE_ALPHA_MAX);
                else
                    flAlpha = (flDistanceMultiplier - DOME_FADE_START_MULTIPLIER) * (1.0/(1.0-DOME_FADE_START_MULTIPLIER)) * DOME_FADE_ALPHA_MAX;

                CreateFade(iClient, _, g_iDomeColor[0], g_iDomeColor[1], g_iDomeColor[2], RoundToNearest(flAlpha));
            }
        }
    }

    g_staticDomeStartTime.Update();

    RequestFrame(Dome_Frame_Shrink);
}

Action Dome_TimerBleed(Handle hTimer)
{
    if (g_hDomeTimerBleed != hTimer)    return Plugin_Stop;

    if (g_VSPState != SRT_BattleRoyale) return Plugin_Stop;

    if (VSH2GameMode.GetPropAny("iRoundState") != StateRunning) return Plugin_Stop;

    for (int iClient = 1; iClient <= MaxClients; iClient++)
    {
        if (IsClientInGame(iClient) && IsPlayerAlive(iClient))
        {
            TFTeam nTeam = TF2_GetClientTeam(iClient);
            if (nTeam <= TFTeam_Spectator)  continue;

            StopSound(iClient, SNDCHAN_AUTO, DOME_NEARBY_SOUND);

            //Check if player is outside of dome
            if (g_bDomePlayerOutside[iClient])
            {
                float flDamage;
                if (VSH2Player(iClient).bIsBoss)
                {
                    //Calculate max possible damage to deal boss based from player count
                    flDamage = float(GetTeamPlayerCount(VSH2Team_Red)) * 25.0;

                    //Scale damage down by current progress dome is at
                    float flRadiusMax = DOME_RADIUS_START;
                    float flRadiusMin = DOME_RADIUS_END;
                    float flRadiusPrecentage = (g_flDomeRadius - flRadiusMin) / (flRadiusMax - flRadiusMin);
                    flDamage *= (1.0 - flRadiusPrecentage);
                }
                else
                {
                    //Calculate damage, the longer the player is outside of the dome, the more damage it deals
                    flDamage = Pow(2.0, g_fPlayerOutDomeTime[iClient]);
                }

                if (flDamage < 1.0) flDamage = 1.0;

                //Deal damage
                if (VSH2Player(iClient).bIsBoss)
                {
                    SDKHooks_TakeDamage(iClient, 0, 0, flDamage, DMG_PREVENT_PHYSICS_FORCE);
                    EmitSoundToClient(iClient, DOME_NEARBY_SOUND);
                }
                else
                {
                    SDKHooks_TakeDamage(iClient, 0, iClient, flDamage, DMG_PREVENT_PHYSICS_FORCE);
                    EmitSoundToClient(iClient, DOME_NEARBY_SOUND);
                }
            }
        }
    }

    //Deal damage to engineer buildings
    int iEntity = MaxClients+1;
    while ((iEntity = FindEntityByClassname(iEntity, "obj_*")) > MaxClients)
    {
        if (Dome_GetDistance(iEntity) <= g_flDomeRadius)    continue;
        if (GetEntProp(iEntity, Prop_Send, "m_bCarried"))   continue;

        SetVariantInt(15);
        AcceptEntityInput(iEntity, "RemoveHealth");
    }

    return Plugin_Continue;
}

void Dome_UpdateRadius()
{
  //Get distance to travel
  float flRadiusStart = DOME_RADIUS_START;
  float flRadiusEnd = DOME_RADIUS_END;
  float flRadiusDistance = flRadiusStart - flRadiusEnd;

  //Calculate speed dome should be
  float flSpeed = flRadiusDistance / 360.0;

  //Calculate new radius from speed and time
  float flRadius = g_flDomeRadius - (flSpeed * g_staticDomeStartTime.Elapsed());

  //Check if we already reached min value
  if (flRadius < flRadiusEnd)
    flRadius = flRadiusEnd;

  //Update global variable
  g_flDomeRadius = flRadius;
}

float Dome_GetDistance(int entity)
{
    float vec[3];

    // client
    if (0 < entity <= MaxClients && IsClientInGame(entity) && IsPlayerAlive(entity))
        GetClientEyePosition(entity, vec);

    //Buildings
    else if (IsValidEntity(entity))
        GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vec);

    else return -1.0;

    return GetVectorDistance(vec, g_vecDomeCP);
}

stock void CreateFade(int client, int duration = 2000, int red = 255, int green = 255, int blue = 255, int alpha = 255)
{
	BfWrite bf = UserMessageToBfWrite(StartMessageOne("Fade", client));
	bf.WriteShort(duration);	//Fade duration
	bf.WriteShort(0);
	bf.WriteShort(0x0001);
	bf.WriteByte(red);			//Red
	bf.WriteByte(green);		//Green
	bf.WriteByte(blue);		//Blue
	bf.WriteByte(alpha);		//Alpha
	EndMessage();
}