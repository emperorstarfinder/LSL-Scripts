// :SHOW:1
// :CATEGORY:NPC
// :NAME:All In One NPC Recorder and Player
// :AUTHOR:Ferd Frederix
// :KEYWORDS:NPC, Puppeteer
// :CREATED:2013-09-08 18:27:47
// :EDITED:2015-08-11  13:07:14
// :ID:27
// :NUM:1822
// :REV:3.6
// :WORLD:OpenSim
// :DESCRIPTION:
// All in one NPC recorder player.
// Supports both absolute and relative paths and many new commands
// Add animations named "Fly, Walk, Stand and Run"
// Click Prim to use.
// Should be worn as a HUD to record.
// Put it on the ground and click Sensor or Start NPC when done.
// :CODE:
// This is Rev 3.6  08/11/2015
  
// Revision History
// Rev 1.1 10-2-2014 @Sit did not work.  Minor tweaks to casting for lslEditor
// Rev 1.2 10-14-2014 @ sit had wrong type.
// Rev 1.3 relative movement fixed for @fly
// Rev 1.4 4-3-2014 allow anyone to use this, non owners and non group members can only start and stop.
// Rev 1.5 5-17-2014 set sensor to auto start on reboot of sim
// Rev 1.6 5-24-2014 move menu so you can get it by touching, removed many of the KeyValues to RAM for efficiency
// Rev 1.7 CHANGED_REGION_START, not CHANGED_REGION_START (Opensim difference)
// Rev 1.8 tuned up Kill NPC, added more flexible upgrader
// Rev 1.9 Better script injection by link message// Rev 2.0 Added osSetSpeed so you can speed up or slow down an NPC.
// Rev 2.1 No laggy sensor used exept to sit on stuff
// Rev 2.2 Various sensor fixes
// Rev 2.3 Sets No Sensor in menu, must be started by hand
// Rev 2.4 - reserved for patches to 2.3 if needed
// Rev 3.0 Refactor out into subs, not states to make command injection easier
//            New command: @appearance=Notecardname so you can switch to a new notecard on the fly
//            New command: @speed=1.0  which slows up  ( < 1 )  or speeds up ( > 1)
// Rev 3.1 Commands are not interruptible by Link Message
// Rev 3.2 Sensor patches for consistency in removing the NPC
// Rev 3.3 Added Touch command by Neo.Cortex@hbase42/hopto/org:8002
//         Added Menu 3 for notecard and appearance commands
// Rev 3.4 animation timer cannot be zero or it shuts off timer tweaked
//         solves the NPC starting up when no sensor is set.
// Rev 3.5 fixes saving in !Path  notecard
// Rev 3.6 @delete acts like @stop. TYjhe NPC now rezzes after an @go back in where it was deleted 

 //*******************************************************************//


// Instructions on how to use this is at http://www.outworldz.com/opensim/posts/NPC/
// This is an OpenSim-only script.
// Author: Ferd Frederix aka Fred Beckhusen - fred@mitsi.com

////////////////////////////////////////////////////////////////////////////////////////////
//    Original code was Copyright (C) 2013 Wizardry and Steamworks - License: GNU GPLv3    //
///////////////////////////////////////////////////////////////////////////////////////////
//  Please see: http://www.gnu.org/licenses/gpl.html for legal details,                  //
//  rights of fair usage, the disclaimer and warranty conditions.                        //
///////////////////////////////////////////////////////////////////////////////////////////
// The original NPC controller was from http://was.fm/opensim:npc
// Extensive additions and bug fixes by Fred Beckhusem, aka Ferd Frederix, fred@mitsi.com
// llSensor had two params swapped
// @Wander would wander where it had rezzed, not where it was.
// There was no 'no_sensor' event in sit, so if a @sit failed, the NPC got stuck
// The animation and walks always stopped old, then started new.  It should be start new, then stop old so the default stand would be suppressed.
// New code:
// Merged with new Route recorder and notecard writer
// If the NPC failed to reach a destination it never moved on. Added WAIT global to tune this
// Exposed many tunable variables and ported the code to LSLEditor.
// Added floating point to times in notecard.

// Added @sound, @randsound, @whisper, @shout, and @cmd controls.
//
// notecards integers are not floats for better control
// 
// Link Messages may be used to perform external control by injecting @commands into the stream of actions
// Example:
// To chat something, such as with a chat robot
//  llMessageLinked(LINK_SET,0,"@npc_say=Hello","");

// This script assumes that NPCs and OSSl scripting is enabled in the OpenSim configuration.
// In order to enable them, the following changes must be made in the OpenSim.ini configuration file:
//
// ; Turn on OSSL
// AllowOSFunctions = true
// OSFunctionThreatLevel = Severe

//[NPC]
//    ;# {Enabled} {} {Enable Non Player Character (NPC) facilities} {true false}
//    Enabled = true
//
// and then the server has to be restarted.


// Commands: All commands begin with an @ sign.  All other lines are ignored
// @commands may have optional parameters.  The syntax is always:
//  @cmd=parm1|parm2
//  NaN in the table below meand Not a Number.   This means there is no parameter

//Command     First Parameter             Second Parameter        Description
//@spawn      name                        location (vector)       Rezzes an NPC with name at a location.
//@appearance NoteCardName                NaN                     switch the NPC appearance to a new notecard
//@walk       destination (vector)        NaN                     Makes the NPC walk to destination.
//@fly        destination (vector)        NaN                     Makes the NPC fly to destination.
//@land       destination (vector)        NaN                     Makes the NPC land at destination.
//@say        string                      NaN                     Makes the NPC speak a phrase.
//@whisper    string                      NaN                     Makes the NPC whisper a phrase.
//@shout      string                      NaN                     Makes the NPC shout a phrase.
//@pause      seconds (float)             NaN                     Makes the NPC wait for a multiple of seconds.
//@wander     radius (float)              cycles (integer)        Makes the NPC wander in radius, for cycles seconds.
//@delete     NaN                         NaN                     Removes the NPC.  Requires a link message to continue
//@goto       label (string)              NaN                     Jump to the label label in the script.
//@animate    animation (string)          time (float)            Makes the NPC trigger the animation animation for time seconds.
//@sound      sound_name                  NaN                     plays a sound from inventory
//@randsound  NaN                         NaN                     Plays a random sound from inventory
//@rotate     degrees (float)             NaN                     Rotate the NPC degrees around the Z axis.
//@sit        primitive name              NaN                     Sit on a primitive with a given name.
//@touch      primitive name              NaN                     Touch on a primitive with a given name.
//@stand      NaN                         NaN                     If sitting on a primitive, stand up.
//@cmd        channel (integer)           string                  Says string on channel, for controlling external gadgets
//@stop       NaN                         NaN                     Halts the NPC script indefinitely. Can be started with a link message
//@go         NaN                         NaN                     Continues on next notecard line, for use in link messages
//@speed      speed (float)               NaN                     from 0 to N, where 1.0 ius a normal speed of an avatar.  0.2 is a turtle.
//@notecard   notename (string)           NaN                     load a new Path notecard

  
//////////////////////////////////////////////////////////
//                  DEBUG                               //
//////////////////////////////////////////////////////////
integer debug = FALSE;         // set to TRUE or FALSE for debug chat on various actions
integer Editor = FALSE;        // set to to TRUE to working in  LSLEditor, FALSE for in-world.
                              // you must also include the NPC commands found in the other script since LSLEditor does not support OpenSim
integer iTitleText = TRUE;    // set to TRUE to see debug info in text above the controller
 
//////////////////////////////////////////////////////////
//                  TUNABLE CONFIGURATION               //
//////////////////////////////////////////////////////////
float     TIMER = 0.5;         // how often the system checks the distance traveled.  Fastest you can go is 0.5 seconds
float     QUICK = 0.020;        // when we need to move to the next state, we use a QUICK timer
string    Appearance = "!Appearance";  // The name of the recorded Appearance notecard
string    Notecard = "!Path"; // The name of the recorded routes
integer   allowUsers = FALSE;  // If true, any user can get a Start NPC and Stop NPC menu.  Only groups and owners can get all commands if TRUE, or FALSE
float     MAXDIST = 2.0;       // how close a NPC has to get to a dest pos to continue to next state. Do not lower this too much, as it may miss the target
integer   WANDERRAND = TRUE;   // set to TRUE and they will pause during wanders a random number of seconds
float     WANDERTIME = 3.0;    // how long they stand after each @wander,if WANDERRAND is FALSE. If WANDERRAND is  TRUE, this is the max time
integer   WAIT = 30;           // wait for this number of seconds for the NPC to reach a destination (for safety). If it fails to reach a target, it will move on after this time.
float     RANGE = 50;        // 1 to N meters  - anyone this close to the controller will start NPCS if Sensor button is clicked
float     REZTIME = 2.0;      // wait this long for NPC to rez in, then start the process
string    STAND = "Stand";     // the name of the default Stand animation
string    WALK = "Walk";       // the name of the default Walk animation
string    FLY = "Fly";        // the name of the default Fly animation
string    RUN = "Run";        // the name of the default Run animation
string    LAND = "Land";      // the name of the default land animation ( for birds only)
float     OffsetZ = 0.5;      // appear 0.5 meter above ground, this is added to all destinations to keep them from sinking in.  
float    SPEEDMULT =1.0;     // 1.0 = regular avatar speed. Smaller numbers slow down walks. Large numbers speed them up.
integer  FLIGHT = 299;        // For controlling wings.  A channel that is shouted at when flight starts and ends. "flying" or "landing" 

// DESCRIPTIONS FIELDS HAVE TO SURVIVE A RESET
//  These vars are stored  by saving them with KeyValueSet
// "pr" is a 0 if it is set for Owner Only, 1 for Group control
// "se" is "on" if Started
// "co" = "R" or "A" for relative or absolute addressing mode
// "key" = NPC key

// These Globals used to be stored in description.   Moved to RAM in V1.6
float RAMPause;          // @pause param
float RAMwd ;            // @wander distance
integer RAMwc;           // @wander count
float RAMrot;            //  @rotate
string RAMsit;           // @sit primname
string RAMtouch;         // @touch primname
string RAManimationName; // @animate animation (string) time (float)
float RAManimationTime;

// other globals section
integer iChannel;        // a listen channel, randomly assigned
integer iHandle;         // the handle to it

// NPC controls
vector newDest ;                // tmp storage for the walks
integer iWaitCounter ;          // wait for this number of seconds for the NPC to reach a desrtination
string sNPCName;                // the name of the NPC that may be in world. So we can remove it.
integer bNPC_STOP = FALSE;      // boolean to reuse a listener
integer Stopped = FALSE;        // set to TRUE by link messages so we do not remember them
float  fTimerVal ;              // how long we wait when wandering (calculated)
float NPCEnabled;               // true if the NPC is suppodes to be running

// OS_NPC_CREATOR_OWNED will create an 'owned' NPC that will only respond to osNpc* commands issued from scripts that have the same owner as the one that created the NPC.
// OS_NPC_NOT_OWNED will create an 'unowned' NPC that will respond to any script that has OSSL permissions to call osNpc* commands.
integer  NPCOptions = OS_NPC_CREATOR_OWNED;    // only yhe owner of this box can control this NPC.

integer walkstate = 0;  // helps us reshare the walk state for run, fly and land - a bit of a hack, but it saves RAM. Has to be done this way because some bits of NPCWalkOption are asserted as 0

integer NPCWalkOption;   // Some notes for what happens to NPCWalkOption:
// OS_NPC_FLY - Fly the avatar to the given position. The avatar will not land unless the OS_NPC_LAND_AT_TARGET option is also given.
// OS_NPC_NO_FLY - Do not fly to the target. The NPC will attempt to walk to the location. If it's up in the air then the avatar will keep bouncing hopeless until another move target is given or the move is stopped
//OS_NPC_LAND_AT_TARGET - If given and the avatar is flying, then it will land when it reaches the target. If OS_NPC_NO_FLY is given then this option has no effect.
// OS_NPC_RUNNING - if given, NPC avatar moves at running/fast flying speed, otherwise moves at walking/slow flying speed.

// menus
string mSensor="Sense is Off";    // Sensor or "No Sensor"

list lAtButtons = ["Menu","-",   ">>",         "@run",    "@walk",   "@fly",  "@land", "@wander",    "@sit",   "@stand","@animate","@rotate"];
list lMenu2 = ["<<", "@comment", ">>>",        "@stop",      "@say",    "@whisper","@shout","@sound","@randsound","@cmd",  "@pause",  "@delete"];
list lMenu3 = ["<<<","@notecard","@appearance", "@touch", "@speed",       "-",     "-","-", "-", "-", "-", "-" ];

string sCommand;  // place to store a command for two-prompted ones
string sParam2;   // place to store a prompt for two-prompted ones
string priPub = "Owner Only";    // Private or Group
key kUserKey;        // the person who is controlling the avatar, not the Owner  
// the command lists
list lCommands;  // commands are stored here
list lNPCScript; // Storage for the NPC script.
string npcAction; // Storage for the next action. @cmd=0|hello, this becomes @cmd
string npcParams; // Storage for the param, @cmd=0|hello, this becomes 0|hello

// misc vars
string sNotecard; // commands are stored here temporarily for dumping
vector  vWanderPos; // a place to wander to
string lastANIM ;   // last animation run
// Sensor
integer avatarPresent;   // Sensor sets this flag when people are within Range.

// Coordinate control
vector vInitialPos ; // Vector that will be filled by the script with the initial starting position in region coordinates.
vector vDestPos = ZERO_VECTOR; // Storage for destination position.
string relAbs = "Relative";    // absolute vs relative positioning
vector lastKnownPos; // last known NPC position when we deleted it

// STATES
integer MENU ;             // processing a dialog box state, may be concurrent with STATE
integer STATE;             // state storage
integer MakeNotecard = 1;  // displaying a text box for NPC name
integer RecordPath = 2;    // displaying a path notecard menu
integer NobodyHome = 3;    // looking for an avatar
integer Spawning = 4;      // spawning an avatar
integer Animate = 5;       // animation timer needed
integer Walking = 6;       // Hey! I am walking here!
integer Wander = 7;        // Wandering around neeeds a timer, too
integer WanderHold = 8;    // We reached a wander point
integer DoProcess = 9;     // Set this to make it process a new command

key gNpcKey = NULL_KEY;   // global key storage for the one NPC, to save CPU cycles
list Stack ;              // a command stack from link message input

integer SensorFunc = 0;    // define which function shall be triggered inside the sensor function
                           // 0 means none, 1 sit, 2 touch
///////////////////////////////////////////////////////////////////////////
//                              FUNCTIONS                                //
///////////////////////////////////////////////////////////////////////////

// Do* functions are much like states from the old scripts.
    
// Save a Path notecard
DoSave()
{ 
    STATE = MakeNotecard;
    makeText("Stand where you want the NPC to appear, and enter the NPC Name");
}

// This function is used to record the path for the NPC
// Each command can take 0, 1, or 2 params
DoMenuForCommands() {
    makeMenu(lAtButtons);
}


// No one is here when sensors were on, so we kill off the NPC
DoNobodyHome()
{
    DEBUG("Nobody Home");
    STATE = NobodyHome;
    if (NPCKey() != NULL_KEY) {
        osNpcRemove(NPCKey());
        SaveKey(NULL_KEY);
    }
    TimerEvent(5);  // keep ticking to sense avatars   
}

// Create a NPC
DoSpawn() {
    DEBUG("state spawn");
    NPCEnabled = TRUE; //  in world
    // see if there is already one out there.
    if (NPCKey() != NULL_KEY) {
        DEBUG("Already living");
        return;
    }
    
    STATE = Spawning;
    
    list name = llParseString2List(sNPCName, [" "], []);
   // notecard is stored as offsets from this box with relative addressing.  Convert to absolute
   vector tvInitialPos = lastKnownPos;
   DEBUG("lastPos:"+ (string) lastKnownPos);
   
    if (relAbs == "Relative"){
        tvInitialPos += llGetPos();
    }

    DEBUG("Rez NPC:" + (string) tvInitialPos);
    key aKey = osNpcCreate(llList2String(name, 0), llList2String(name, 1), tvInitialPos, Appearance, NPCOptions);

    SaveKey(aKey ); // save in desceription and global, too
    
    osSetSpeed(aKey,SPEEDMULT);   // 1.9 speed multiplier
    TimerEvent(REZTIME);
    NPCAnimate(STAND);
}
 
DoRotate() {
    DEBUG("state rotate");
    osNpcSetRot(NPCKey(), llEuler2Rot(<0,0,RAMrot> * DEG_TO_RAD));
}  

DoSit() {
    DEBUG ("state sit - looking for " + RAMsit);
    SensorFunc = 1; //triggers osNpcSit
    llSensor(RAMsit, "", PASSIVE|ACTIVE|SCRIPTED,  96, PI);
}

DoTouch() {
    DEBUG ("state touch - looking for " + RAMtouch);
    SensorFunc = 2; //triggers osNpcTouch
    llSensor(RAMtouch, "", PASSIVE|ACTIVE|SCRIPTED,  96, PI);
}
 
DoStand() {
    
    DEBUG("state stand");
    osNpcStand(NPCKey());
}


DoAnimate() {
    
    DEBUG("state animate");
    STATE = Animate;
    NPCAnimate(RAManimationName);
    if (RAManimationTime <=0 )    // V 3.4 tweak
        RAManimationTime = 1;
    TimerEvent(RAManimationTime);
}
    
DoWalk() {

    DEBUG("NPCWalkOption = " + (string) NPCWalkOption);
    STATE = Walking;
            
    // walk, fly, run, land
   if (walkstate == 1) {
        NPCAnimate(WALK);
    } else if (walkstate == 2)  {
        llShout(FLIGHT,"flying");
        NPCAnimate(FLY);
    } else if (walkstate == 3) {
        NPCAnimate(RUN);
    } else if (walkstate == 4) {
        NPCAnimate(LAND);
    } 
    newDest = vDestPos ;
    newDest.z += OffsetZ;
        
    // notecard is stored as offsets from this box with relative addressing.  Convert to absolute
    if (relAbs == "Relative"){
        newDest += llGetPos();
    }

    DEBUG("Moveto:" + (string) newDest);
    osNpcMoveToTarget(NPCKey(), newDest, NPCWalkOption);
    iWaitCounter = WAIT;            // wait 60 seconds to get to a destination.
    TimerEvent(TIMER);
}


DoWander(){
    DEBUG("state wander");
    STATE = Wander;
    
    vector point = CirclePoint(RAMwd);
    DEBUG("CirclePoint:" + (string) point);
    vWanderPos = vDestPos + point;
    DEBUG("vWanderPos:" + (string) vWanderPos);

    fTimerVal = WANDERTIME;    // default time to pause after each wander
    if (WANDERRAND)
        fTimerVal = llFrand(WANDERTIME) + 1;    // override, they want random times

    NPCAnimate(WALK);

    DEBUG("Wander to:" + (string) vWanderPos);

    osNpcMoveToTarget(NPCKey(), vWanderPos, NPCWalkOption);
    iWaitCounter = WAIT;            // wait 60 seconds to get to a destination.
    TimerEvent(TIMER);      
}

DoWanderhold() {

    DEBUG("Wander Hold");
    STATE = WanderHold;
       
     // now that we have reached a wander spot, slow the timer down to the desired value
    TimerEvent(fTimerVal);
}

// @pause=10 will do nothing for 10 seconds
DoPause() {
    
    DEBUG("state pause");
    if (RAMPause < 0.1)
        RAMPause = 0.1;
        
    TimerEvent(RAMPause);
}


// @stop makes the NPC stop moving in whatever state it is in.  You have to linkmessage to get moving again
DoStop() {    
    DEBUG("NPC is Stopped");
    Stopped = TRUE; // Link controlled - we mnust have a @go to continue with notecards
    TimerEvent(0);
}
    
// @delete removes the NPC forever. Next command starts it up again at the beginning
DoDelete() {
    DEBUG("state delete");
     
    vector v= osNpcGetPos(NPCKey());
    if (v != ZERO_VECTOR) 
        lastKnownPos = v; 
    else
        lastKnownPos = llGetPos();
        
    if (relAbs == "Relative"){
        lastKnownPos -= llGetPos();  
    }
    osNpcRemove(NPCKey());
    SaveKey(NULL_KEY);
    Stopped = TRUE; // Link controlled - we mnust have a @go to continue with notecards
    TimerEvent(0);
}

// change the appearance of the NPC
DoAppearance(string notecard) {
    DEBUG("state appearance");
    if (llGetInventoryType(notecard) == INVENTORY_NOTECARD){
        DEBUG("Load appearance " + notecard);
        osNpcLoadAppearance(NPCKey(),notecard);
    }
}

// Change the avatar speed
DoSpeed(string speed) {
    float newspeed = (float) speed;
    if (newspeed > 0.1 && newspeed < 5.0) // sanity check
        osSetSpeed(NPCKey(),newspeed);
}
DoNewNote (string card) {
    DEBUG("Load Notecard " + card);    
    NPCReadNoteCard(card);
    Stopped = FALSE;
}
    
// This loops over the notecard, processing each command
DoProcessNPCLine() {
    DEBUG("ProcessNPCLine");
    STATE = 0;

        // auto load a notecard
    if (! llGetListLength(lNPCScript)) {
        DEBUG("Read Notecard");
        NPCReadNoteCard(Notecard);
        Stopped = FALSE;
    }

    // look for link messages on the stack
    string next = llList2String(Stack,0);    // lets see if there is anithing from a link message
    if (llStringLength(next))
    {
        Stack = llDeleteSubList(Stack,0,0);
        ProcessCmd(next);        //lets do this command instead.
        return;
    }

    // @stop issued?
    if (Stopped) {
        TimerEvent(0);
        DEBUG("Waiting for input");
        return;
    }

    // No, we have an @go for liftoff
    next = llList2String(lNPCScript, 0);        // get the next command
    DEBUG("Execute:" + next);
    lNPCScript = llDeleteSubList(lNPCScript, 0, 0);      // delete it
        
    if (llGetListLength(lNPCScript) == 0) {
        DEBUG("EOF");
    }
    ProcessCmd(next); 

} 



ProcessCmd(string cmd) {

    DEBUG("ProcessCmd:" + cmd);

    if (llGetSubString(cmd, 0, 0) != "@") {
        DEBUG("ignoring");
        STATE = DoProcess;
        TimerEvent(QUICK);  // this is so we do not recurse the stack
        return;
    }

    list data  = llParseString2List(cmd, ["="], []);
    npcAction = llToLower(llStringTrim(llList2String(data, 0), STRING_TRIM));

    DEBUG("Action:" + npcAction);
    npcParams = llStringTrim(llList2String(data, 1), STRING_TRIM);

    @commands;

    ProcessSensor();
    if (! avatarPresent){
        DoNobodyHome();
        DEBUG("No avatar nearby");
        return;
    } else {
        if ( NPCKey() == NULL_KEY) {
            DoSpawn();
        }
    }
    
    if(npcAction == "@spawn") {
        DEBUG("@spawn");
        list spawnData = llParseString2List(npcParams, ["|"], []);
        sNPCName =llList2String(spawnData, 0);    // V 1.6 name in RAM

        list spawnDest = llParseString2List(llList2String(spawnData, 1), ["<", ",", ">"], []);
        vInitialPos.x = llList2Float(spawnDest, 0);
        vInitialPos.y = llList2Float(spawnDest, 1);
        vInitialPos.z = llList2Float(spawnDest, 2);
        lastKnownPos = vInitialPos ;
        DoSpawn();
        
        return;
    }
    else if(npcAction == "@stop") {
        DEBUG("@stop");
        DoStop();
        return;
    }
    else if(npcAction == "@goto") {
        DEBUG("goto");
        integer lastIdx = llGetListLength(lNPCScript)-1;
        lNPCScript = llDeleteSubList(lNPCScript, lastIdx, lastIdx);
        // Wind commands till goto label.
        @wind;
        string next1 = llList2String(lNPCScript, 0);
        lNPCScript = llDeleteSubList(lNPCScript, 0, 0);
        lNPCScript += next1;
        if(next1 != npcParams) jump wind;
        // Wind the label too.
        next1 = llList2String(lNPCScript, 0);
        lNPCScript = llDeleteSubList(lNPCScript, 0, 0);
        lNPCScript += next1;
        // Get next command.
        list data1  = llParseString2List(next1, ["="], []);
        npcAction = llToLower(llStringTrim(llList2String(data1, 0), STRING_TRIM));
        npcParams = llStringTrim(llList2String(data1, 1), STRING_TRIM);
        // Reschedule.
        jump commands;
    }
    else if(npcAction == "@sound") {
        DEBUG("sound");
        llTriggerSound(npcParams,1.0);
    }
    else if(npcAction == "@randsound") {
        DEBUG("@randsound");
        integer N = llGetInventoryNumber(INVENTORY_SOUND);
        integer rand = llCeil(llFrand(N)) -1;    // pick a random sound
        string toPlay = llGetInventoryName(INVENTORY_SOUND,rand);
        llTriggerSound(toPlay,1.0);
    }
    else if(npcAction == "@walk") {
        DEBUG("@walk");
        GetDest(npcParams);
        walkstate = 1;//  walking
        NPCWalkOption = OS_NPC_NO_FLY ;
        DoWalk();
        return;
    }
    else if(npcAction == "@fly") {
        GetDest(npcParams);
        walkstate = 2;//  flying
        NPCWalkOption = OS_NPC_FLY ;
        DoWalk();
        return;
    }
    else if(npcAction == "@run") {
        DEBUG("@run");
        GetDest(npcParams);
        walkstate = 3;//  running
        NPCWalkOption = OS_NPC_NO_FLY | OS_NPC_RUNNING;
        DoWalk();
        return;
    }
    else if(npcAction == "@land") {
        DEBUG("@land");
        GetDest(npcParams);
        walkstate = 4;//  landing
        NPCWalkOption= OS_NPC_FLY | OS_NPC_LAND_AT_TARGET ;
        DoWalk();
        return;
    }
    else if(npcAction == "@say") {
        DEBUG("@say " + npcParams);
        osNpcSay(NPCKey(), 0, npcParams);
    }
    else if(npcAction == "@shout") {
        DEBUG("@shout");
        osNpcShout(NPCKey(),0, npcParams);
    }
    else if(npcAction == "@whisper") {
        DEBUG("@whisper " + npcParams);
        osNpcWhisper(NPCKey(),0, npcParams);
    }
    // speak a command on a channel, so you can open doors and control stuff.
    else if(npcAction == "@cmd") {
        DEBUG("@cmd");
        list dataToSpeak = llParseString2List(npcParams, ["|"], []);
        string channel = llList2String(dataToSpeak,0);
        DEBUG("Channel:"+(string) channel);
        integer iChannel = (integer) channel;
        string stringToSpeak = llList2String(dataToSpeak,1);
        llSay(iChannel, stringToSpeak);
    }
    // stop everything
    else if(npcAction == "@pause") {
        DEBUG("@pause");
        RAMPause = (float) npcParams;
        DoPause();
        return;
    }
    else if(npcAction == "@wander") {
        DEBUG("@wander");
        list wanderData = llParseString2List(npcParams, ["|"], []);
        RAMwd = (float) llList2String(wanderData, 0);
        RAMwc = (integer) llList2String(wanderData, 1);

        vDestPos = osNpcGetPos(NPCKey());        // set the wander start
        DEBUG("Starting at " + (string) vDestPos);
        DoWander();
        return;
    }
    else if(npcAction == "@rotate") {
        DEBUG("@rotate");
        RAMrot = (float) npcParams;
        DoRotate();
    }
    else if(npcAction == "@sit") {
        DEBUG("@sit");
        RAMsit= npcParams;
        DoSit();
        return;
    }
    else if(npcAction == "@touch") {
        DEBUG("@touch");
        RAMtouch= npcParams;
        DoTouch();
        return;
    }
    else  if(npcAction == "@stand") {
        DEBUG("@stand");
        DoStand();
    }
    else if(npcAction == "@delete") {
        DEBUG("@delete");
        DoDelete();
        return;
    }
    else if(npcAction == "@animate") {
        DEBUG("@animate");
        list animateData = llParseString2List(npcParams, ["|"], []);
        RAManimationName = llList2String(animateData, 0);
        RAManimationTime = (float) llList2String(animateData, 1);
        DoAnimate();
        return;
    }
    else if(npcAction == "@appearance" )
    {
        DEBUG("@appearance");
        DoAppearance(npcParams);
    }
    else if (npcAction =="@speed") {
        DEBUG("@speed");
        DoSpeed(npcParams);
    }
    else if (npcAction =="@notecard") {
        DEBUG("@notecard");
        DoNewNote(npcParams);
        Notecard = npcParams;
    }

    STATE = DoProcess;
    TimerEvent(QUICK);  // yeah I know, not possible this fast, we just go as fast as we can go - this is so we do not recurse the stack 
}
 


/////////////////// UTILITY Functions, not state-like //////////////////

// DEBUG(string) will chat a string or display it as hovertext if debug == TRUE
DEBUG(string str) {
    if (debug)
        llOwnerSay( str);                    // Send the owner debug info so you can chase NPCS
    if (iTitleText) {
        llSetText(str,<1.0,1.0,1.0>,1.0);    // show hovertext
    
    }
}

GetDest(string npcParams) {
    list dest = llParseString2List(npcParams, ["<", ",", ">"], []);
    vDestPos.x = llList2Float(dest, 0);
    vDestPos.y = llList2Float(dest, 1);
    vDestPos.z = llList2Float(dest, 2);
}

NPCReadNoteCard(string Note) {
    DEBUG("NPCReadNoteCard");             
    lNPCScript = llParseString2List(osGetNotecard(Note), ["\n"], []);
}  
  
integer SenseAvatar()
{
    //Returns a strided list of the UUID, position, and name of each avatar in the region
    list avatars = llGetAgentList(AGENT_LIST_REGION ,[]);
    integer numOfAvatars = llGetListLength(avatars);
    if (numOfAvatars == 0)
    {
        DEBUG("No people");
        return 0;
    }
    //DEBUG("Located " + (string)numOfAvatars + " avatars and NPC's"); 
        
    integer nAvatars;
    integer i;
    for( i = 0;i < numOfAvatars; i++) {
        key aviKey = llList2Key(avatars,i);
        if (!osIsNpc(aviKey)) {
            list detail = llGetObjectDetails(aviKey,[OBJECT_POS]);
            vector pos = llList2Vector(detail,0);
            float dist = llVecDist(pos, llGetPos());
            if (dist  < RANGE)
            {
                nAvatars++;
                DEBUG("In range:" + llKey2Name(aviKey));
            }
        }
    }
    //DEBUG("Located " + (string) nAvatars + " avatars");
    return nAvatars;
} 
 
// return TRUE if the avatar is owner when private is set, or TRUE if the avatar is in the same group and GROUP is set.
integer checkPerms() {

    integer group = (integer) KeyValueGet("pr");
    if (! group)
        priPub = "Owner Only";
    else
        priPub = "Group";
    
    
    if (llDetectedKey(0) == llGetOwner()){
        kUserKey = llDetectedKey(0);
        return TRUE;
    }
 
    if ( group && llDetectedGroup(0)) {
        kUserKey = llDetectedKey(0);
        return TRUE;
    }
    kUserKey = llDetectedKey(0);
    return FALSE;
}



NPCAnimate(string anim)
{
    DEBUG("Start Anim: " + anim);
    if (llGetInventoryType(anim) == INVENTORY_ANIMATION ) {
        
        if (lastANIM != anim) {
            if(llStringLength(lastANIM)) {
                osNpcStopAnimation(NPCKey(), lastANIM);  
            }
            osNpcPlayAnimation(NPCKey(), anim);
            lastANIM = anim;
        }            
    } else {
        llSay(DEBUG_CHANNEL, "No animation named " + anim);
    }
} 


TimerEvent(float timesent)
{
    DEBUG("Setting  timer: " + (string) timesent);
    llSetTimerEvent(timesent);
}

// Kill a NPC by Name
Kill(string param)
{
    integer count;
    list avatars = osGetAvatarList(); // Returns a strided list of the UUID, position, and name of each avatar in the region except the owner.\    
    integer i;
    integer j = llGetListLength(avatars);
    for (i=0 ; i <= j; i+=3){
        
        string desired = llList2String(avatars,i+2);
        desired = llStringTrim(desired,STRING_TRIM);    // should not be needed but is needed
        
        if (desired == param){
            vector v = llList2Vector(avatars,i+1);
            key target = llList2Key(avatars,i);    // get the UUID of the avatar
            osNpcRemove(target);
            SaveKey(NULL_KEY );  
            llOwnerSay("Removed " + param+ " at  location " + (string) v);
            count++;
        }
    }
    
    NPCEnabled = FALSE; // not in world
    
    if (count)
        llOwnerSay("Removed " + (string) count + " NPC's");
    else
        llOwnerSay("Could not locate " + param);
}


// return a String for the position we are at. Strings used as the caller wants strings
string Pos()
{
    vector where = llGetPos(); // find the box position
   
    where.z +=    OffsetZ;  // use the ground position + an offset 
        
    if (Editor)
        where  = <128,128,31 + llFrand(1)>; // center of sim for editing
   
   // if attached the height will be too high by 1/2 the agent size
    if (llGetAttached()) {
        vector size = llGetAgentSize(llGetOwner());   
        float Z = size.z;
        where.z -= Z/2;  
    }
   
    // DEBUG("Pos= " + (string) where);
    return (string) where;
}

// setup a menu with a timer for timeouts, called by all make*()
menu()
{
    llListenRemove(iHandle);
    iChannel = llCeil(llFrand(100000) + 20000);
    iHandle = llListen(iChannel,"","","");
    TimerEvent(30.0);
    MENU = TRUE;
}

// make a text box
makeText(string Param)
{ 
    menu();
    llTextBox(kUserKey, Param, iChannel);
}

// top level menu
makeMainMenu()
{
    menu();
    list buttons = ["Appearance","Recording","Save","Help","-","Erase RAM", priPub,relAbs,"-","Stop NPC",mSensor,"Start NPC"];
    llDialog(kUserKey,(string) llGetListLength(lCommands) + " Records",buttons,iChannel);
}


// Rev 1.4
// top level menu for non group/ non owners
makeUserMenu()
{
    if (!allowUsers) return;
    
    menu();
    list buttons = ["Start NPC","Stop NPC"];
    llDialog(kUserKey,"Choose",buttons,iChannel);
}



// programmable menu for @commands
makeMenu(list buttons)
{
    menu();
    llDialog(kUserKey,(string) llGetListLength(lCommands) + " Record",buttons,iChannel);
}


// make one or two text boxes with prompts
Text(string cmd, string p1, string p2)
{
    sCommand = cmd;
     sParam2 = "";
    if (llStringLength(p2))
        sParam2 = p2;

    makeText(p1);
} 

// Set the Avatar Present flag - if sensors are off and we are forece run, there will be one present.
ProcessSensor()
{
    integer SensorOn;
    if ("on" == KeyValueGet("se"))
    {
        SensorOn = TRUE;        // we need to scan for avatars
    } else {
        SensorOn = FALSE;        // we need to scan for avatars
    }
    DEBUG("Sensor:" + (string) SensorOn);
    
    integer n = SenseAvatar();
    
    DEBUG("Avatars:" + (string) n);
    if (SensorOn && n)
        avatarPresent = TRUE;   // someone is here and we need to tell the system to run
    else if (SensorOn && !n)
        avatarPresent = FALSE;  // someone is not here and we need to tell the system to stop
    else {       // sensor is off, lete see if there is a NPC. If so, we are ON 
        DEBUG("NPCEnabled:" + (string) NPCEnabled);
        if (NPCEnabled)
            avatarPresent = TRUE;  
        else
            avatarPresent = FALSE;   
    }
    //DEBUG("Avatar Present: " + (string) avatarPresent);
}

vector CirclePoint(float radius) {
    float x = llFrand(radius *2) - radius;        // +/- radius, randomized
    float y = llFrand(radius *2) - radius;        // +/- radius, randomized
    return <x, y, 0>;        // so this should always happen
}

string KeyValueGet(string var) {
    list dVars = llParseString2List(llGetObjectDesc(), ["&"], []);
    do {
        list data = llParseString2List(llList2String(dVars, 0), ["="], []);
        string k = llList2String(data, 0);
        if(k != var) jump continue;
        //DEBUG("got " + var + " = " +  llList2String(data, 1));
        return llList2String(data, 1);
        @continue;
        dVars = llDeleteSubList(dVars, 0, 0);
    } while(llGetListLength(dVars));
    return "";
} 

KeyValueSet(string var, string val) {

    //DEBUG("set " + var + " = " + val);
    list dVars = llParseString2List(llGetObjectDesc(), ["&"], []);
    if(llGetListLength(dVars) == 0)
    {
        llSetObjectDesc(var + "=" + val);
        return;
    }
    list result = [];
    do {
        list data = llParseString2List(llList2String(dVars, 0), ["="], []);
        string k = llList2String(data, 0);
        if(k == "") jump continue;
        if(k == var && val == "") jump continue;
        if(k == var) {
            result += k + "=" + val;
            val = "";
            jump continue;
        }
        string v = llList2String(data, 1);
        if(v == "") jump continue;
        result += k + "=" + v;
        @continue;
        dVars = llDeleteSubList(dVars, 0, 0);
    } while(llGetListLength(dVars));
    if(val != "") result += var + "=" + val;
    llSetObjectDesc(llDumpList2String(result, "&"));
}


// clear RAM
Clr() {

    lCommands = [];
    llOwnerSay("RAM Memory cleared. Notecards, if any, are not modified.");
    makeMainMenu();
}

integer checkNoteCards()
{
    // Check that they have saved an Appeaance and Path notecard
    integer num = llGetInventoryNumber(INVENTORY_NOTECARD);    // how many notecards overall
    
    integer i;
    integer count;
    for (; i < num; i++){
        if (llGetInventoryName(INVENTORY_NOTECARD,i) == Notecard)
            count++;
        if (llGetInventoryName(INVENTORY_NOTECARD,i) == Appearance)
            count++;
    }
    DEBUG("Checked " + (string) count + " Notecards");
    // if we have both, run the NPC
    return count;
}

Update(string SName) {
         
    // delete all NPC*scripts except myself
    integer i;
    integer j = llGetInventoryNumber(INVENTORY_SCRIPT);
    for (i = 0; i < j; i++) {
        string name = llGetInventoryName(INVENTORY_SCRIPT,i);
        string match = llGetSubString(name,0,2);
        if (match == SName && llGetScriptName() != name)
        {
            llRemoveInventory(name);
            llOwnerSay("Upgraded");
        }
    }

}

// Get all default saved params from the Description
GetSwitches()
{
         string rA = KeyValueGet("co"); // Get the remembered menu setting for Abs Vs Relative
        if (rA == "A")
            relAbs = "Absolute";
        else  if (rA == "R")
            relAbs = "Relative";
        else
            relAbs = "Absolute";

            
        // reenable NPC if sensor is on.
        if ("on" == KeyValueGet("se"))
        {
            NPCEnabled = TRUE;
            mSensor  = "Sense is On";
            ProcessSensor();       // fake 1 avatar to get it rezzed
        } else {
            mSensor  = "Sense is Off";
        }
    }


SaveKey(key akey)
{
    DEBUG("Saving Key of " + (string) akey);
    KeyValueSet("key", akey);
    if (akey !=  (key) KeyValueGet("key") )
    {
        DEBUG("Fatal error, cannot save key");
    }
    gNpcKey = akey;
}


key NPCKey()
{
    key akey = gNpcKey;   // from cached copy
    // gNpcKey saves a lot of CPU processing by caching the key, if blank we get it from the description
    if (gNpcKey == NULL_KEY)
    {
        //DEBUG("Get DKey");
        akey = KeyValueGet("key");    // from Description of the prim
    }
   // DEBUG("NPC KEY:" + (string) akey);   
    return  akey;
}


/////////////////// CODE BEGINS //////////////////


default
{
     changed(integer change) {
        if(change & CHANGED_REGION_START) {
            llResetScript();
        }
    }
    
    on_rez(integer start_param)
    {
        llResetScript();
    }

    state_entry() {
        
        llSetText("",<1,1,1>,1.0);  // clr all hovertext- we may not be using it.
        DoDelete(); // kill any NPC that is out running
        Update("NPC"); // If dragged and ropped into a prim with any script named "NPC...", this will replace it.
        GetSwitches(); // Get all default saved params from the Description
        llSetTimerEvent(TIMER);
    } 


    touch_start(integer n) 
    {           // if touched, make a menu
    
        if (checkPerms()) {
            if (RecordPath == STATE) {
                makeMenu(lAtButtons); 
            }   else {
                makeMainMenu();
            }
        } else {
            makeUserMenu();
        }
    }

    // menu listener
    listen(integer iChannel, string name, key id, string message) {
          
        if (MENU) {
            llListenRemove(iHandle);
            MENU = 0;       // menu is off
            iHandle = 0;
        }
        
        if (message == "Stop NPC")
        {
            lNPCScript = []; // force reload of notecard
            NPCEnabled = FALSE;
            if (NPCKey() != NULL_KEY){
                Kill(sNPCName);
                sNPCName = "";
            } else {
                bNPC_STOP = TRUE;
                makeText("Enter name of an NPC to stop");
            }
        }
        else if (message == "Menu" ) {
            makeMainMenu();
        }
        else if (message == "Erase RAM"){
            Clr();
        }
        else if (message == "Relative"){
            relAbs = "Absolute";
            KeyValueSet("co","A");   // remember coordinates = A
            Clr();
        }
        else if (message == "Absolute"){
            relAbs = "Relative";
            KeyValueSet("co","R");   // remember coordinates = R
            Clr();
        }
        else if (message == "Recording"){
            DoMenuForCommands();        // show them the recording menu
        }
        else if (message == "Owner Only") {
            priPub = "Group";
            KeyValueSet("pr","1");

            llOwnerSay("Group members have control");
            makeMainMenu();
        }
        else if (message == "Group") {
            priPub = "Owner Only";
            KeyValueSet("pr","0");
            llOwnerSay("Only you have control");
            makeMainMenu();
        }
        else if (message == "Sense is On") {
            mSensor ="Sense is Off";
            KeyValueSet("se", "off");
            llOwnerSay(mSensor);
            makeMainMenu();
        }
        else if (message == "Sense is Off") {
            mSensor ="Sense is On";
            llOwnerSay(mSensor);
            KeyValueSet("se", "on");
            
            NPCEnabled = FALSE;
            
            integer count = checkNoteCards();
            if (count >= 2)  {
                DEBUG("Notecards approved , calling DoProcessNPCLine");
                DoProcessNPCLine();
                return;
            }
            if (Editor) {
                DoProcessNPCLine();
                return;
            }

            llOwnerSay("You have not saved a recording and/or appearance, so you cannot start a NPC");
            makeMainMenu();
        }
        else if (message == "Appearance")  {
            llRemoveInventory(Appearance);            // delete the notecard
            osAgentSaveAppearance(kUserKey,Appearance);    // make the ntecard 
            llOwnerSay("Your outfit has been saved");
            makeMainMenu();
        }
        else if (message == "Save") {
            if (llGetListLength(lCommands) == 0) {
                llOwnerSay("Nothing recorded, you need to make a recording first");
                makeMainMenu();
                return;
            }
            DoSave();
        }
        else if (message == "Help"){
            llLoadURL(kUserKey,"Click to view help","http://www.outworldz.com/opensim/posts/NPC/");
            makeMainMenu();
        }
        else if (message == "Start NPC")    {
            integer count = checkNoteCards();
            Stopped = FALSE; // Let's run the notecard
            NPCEnabled = TRUE;

            if (Editor) {
                DoProcessNPCLine();
                return;
            }
            
            if (count >= 2) {
                DEBUG("Notecards approved , calling DoProcessNPCLine");
                Stopped = FALSE; // Let's run the notecard
                DoProcessNPCLine();
                return;
            }

            llOwnerSay("You have not saved a recording or maybe an appearance, so we cannot start a NPC");
      
        }
        else if (bNPC_STOP){
            bNPC_STOP = FALSE;
            Kill(message);
        }
        else if (message == ">>"){
            makeMenu(lMenu2);
        }
        else if (message == ">>>"){
            makeMenu(lMenu3);
        }
        else if (message == "<<") {
            makeMenu(lAtButtons);
        }
        else if (message == "<<<") {
            makeMenu(lMenu2);
        }
        else if (message == "@comment"){
            Text("# ","Enter a comment","");
        }
        else if (message == "@stop"){
            lCommands += "@stop"+  "\n";
            makeMenu(lAtButtons);
        }
        else if (message == "@run"){
            lCommands += "@run=" + Pos() + "\n";
            llOwnerSay("Recorded position: " + Pos());
            makeMenu(lAtButtons);
        }
        else if (message == "@fly"){
            lCommands += "@fly=" + Pos() + "\n";
            llOwnerSay("Recorded position: " + Pos());
            makeMenu(lAtButtons);
        }
        else if (message == "@land"){
            lCommands += "@land=" + Pos() + "\n";
            llOwnerSay("Recorded position: " + Pos());
            makeMenu(lAtButtons);
        }
        else if (message == "@walk") {
            lCommands += "@walk=" + Pos() + "\n";
            llOwnerSay("Recorded position: " + Pos());
            makeMenu(lAtButtons);
        }
        else if (message == "@stop"){
            lCommands += "@stop"+  "\n";
            makeMenu(lAtButtons);
        }
        else if (message == "@sound"){
            Text("@sound=","Enter a sound name or UUID to trigger","");
        }
        else if (message == "@randsound"){
            lCommands += "@randsound"+  "\n";
            makeMenu(lAtButtons);
        }
        else if (message == "@say") {
            Text("@say=","Enter what the NPC will say","");
        }
        else if (message == "@whisper"){
            Text("@whisper=","Enter what the NPC will whisper","");
        }
        else if (message == "@shout"){
            Text("@shout=","Enter what the NPC will shout","");
        }
        else if (message == "@wander") {
            Text("@wander=","Enter radius to wander","Enter number of wanders");
        }
        else if (message == "@pause") {
            Text("@pause=","Enter time to pause","");
        }
        else if (message == "@rotate") {
            Text("@rotate=","Enter degrees to rotate","");
        }
        else if (message == "@sit"){
            Text("@sit=","Enter name of object to sit on","");
        }
        else if (message == "@touch"){
            Text("@touch=","Enter name of object to touch","");
        }
        else if (message == "@cmd"){
            Text("@cmd=","Enter cjhannel to speak on","Enter text to speak");
        }
        else if (message == "@stand"){
            lCommands += "@stand\n";
            llOwnerSay("Stand Recorded");
            makeMenu(lAtButtons);
        }
        else if (message == "@animate"){
            Text("@animate=","Enter animation name to play","Enter time to play the animation");
        }
         else if (message == "@speed"){
            Text("@speed=","Enter a speed for the NPC, 1=100% normal speed, 0.5=50% speed","");
        }
               

        // Save NPC name
        else if (MakeNotecard == STATE) {
            sNPCName = message; // in case we need to kill it.
            
            vector  vDest = (vector)  Pos();

            if (relAbs == "Relative")
            {
                vDest  -= llGetPos();    // just an offset for relative
            }
            sNotecard = "@spawn=" + message + "|" +  (string) vDest  + "\n";
            integer i;
            integer j = llGetListLength(lCommands);
            for (; i < j; i++){
                // get the command to save to the notecard
                string line = llList2String(lCommands,i);
                if (relAbs == "Absolute") {
                    sNotecard += line;    // add the un-modified string to the notecard
                } else {
                        // since we have to record absolute coords since we do not know where the box goes until they press Save,
                        // we process the absolute to relative conversion for walks here
                        list parts = llParseString2List(line,["="],[]); //get the @command

                    if (llList2String(parts,0) == "@walk") {
                        vector vec = (vector) llList2String(parts,1) - llGetPos();
                        sNotecard += "@walk=" + (string) vec + "\n";
                    }
                    else if (llList2String(parts,0) == "@fly") {
                        vector vec = (vector) llList2String(parts,1) - llGetPos();
                        sNotecard += "@fly=" + (string) vec + "\n";
                    }
                    else if (llList2String(parts,0) == "@run") {
                        vector vec = (vector) llList2String(parts,1) - llGetPos();
                        sNotecard += "@run=" + (string) vec + "\n";
                    }
                    else if (llList2String(parts,0) == "@land") {
                        vector vec = (vector) llList2String(parts,1) - llGetPos();
                        sNotecard += "@land=" + (string) vec + "\n";
                    }
                    else {
                        sNotecard += line;    // add the un-modified string to the notecard
                    }
                }
            }
            llRemoveInventory(Notecard);        // delete the old notecard
            osMakeNotecard(Notecard,sNotecard); // Makes the notecard.
            llOwnerSay("Commands notecard has been written");
            STATE = 0;
        } // MakeNotecard

        else  if (! llStringLength(sParam2)) {
            lCommands +=  sCommand + message + "\n";
            llOwnerSay("Recorded");
            makeMenu(lAtButtons);
        }
        else if (llStringLength(sParam2)){
            sCommand = sCommand + message + "|";
            llOwnerSay("Recorded");
            makeText(sParam2);
            sParam2 = "";
        }

    }



    timer(){
        DEBUG("tick");
        
        // if llDialog is up, kill the listener for the dialog box.
        if (iHandle) {
            llOwnerSay("Menu timed out");
            llListenRemove(iHandle);
            iHandle = 0;
            return;             // ^^^^^^^^^^^^^^^^^^^^^^^
        }
        // if NoBodyHome, we are sensing for an avatar
        else if (NobodyHome == STATE) {
            if (! llGetRegionAgentCount()) {
                DoNobodyHome();
                return; // ^^^^^^^^^^^^^^^^^^^^^^^
            }
        }
        // if we are spawning, we need time to rez the NPC, then start processing NPC Commands.
        else if (Spawning == STATE) {
            STATE = 0;
            TimerEvent(TIMER);
        }
        // We end aniamtions with a timer
        else if (Animate == STATE){
            NPCAnimate(STAND);
            TimerEvent(TIMER);
        }
        
        else if (Walking == STATE) {
            if (--iWaitCounter) {
                if (llVecDist(osNpcGetPos(NPCKey()), newDest) > MAXDIST)  {
                    return;
                }
            }

            // walk, fly, run, land
            if (walkstate == 1) {
                NPCAnimate(STAND);
                NPCWalkOption = OS_NPC_NO_FLY;
            } else if (walkstate == 2)  {
                    // nothing
                } else if (walkstate == 3) {
                     NPCAnimate(STAND);
                     NPCWalkOption = OS_NPC_NO_FLY;
            } else if (walkstate == 4) {
                llShout(FLIGHT,"landing");
                NPCAnimate(STAND);
                NPCWalkOption = OS_NPC_NO_FLY;
            }
        }
        // Wandering timer 
        else if (Wander == STATE) {
            if (--iWaitCounter) {          // wait 60 seconds to get to a destination.
                if (llVecDist(osNpcGetPos(NPCKey()), vWanderPos) > MAXDIST)
                    return;
            }

            // see if wander counter == 0, if so, stop walking, go to stand and process next line
            if(RAMwc == 0) {
                NPCAnimate(STAND);
                DEBUG("Wander ended, calling DoProcessNPCLine");
                STATE = 0;
                DoProcessNPCLine();
                return;
            }
            // one less time to wander around
            RAMwc--;
            NPCAnimate(STAND);
            TimerEvent(TIMER);
            DoWanderhold();
            return;
        }
        // Wandering requires us to re-wander when we reach a destination
        else if (WanderHold == STATE) {
            DoWander();
            TimerEvent(TIMER);
            return;
        }
        else if (DoProcess == STATE) {
            TimerEvent(QUICK);
        }
       
        STATE = 0;

        // We always process a NPC line at end of timer.
        DEBUG("Tick end, calling DoProcessNPCLine");
        DoProcessNPCLine();
    }

    // sensors are used for sitting on prims
    // Neo Cortex: added different SensorFunc states to trigger sit or touch
    sensor(integer num) {
        if (SensorFunc == 1) {
            osNpcSit(NPCKey(), llDetectedKey(0), OS_NPC_SIT_NOW);
            DEBUG("Seated, calling DoProcessNPCLine");
            SensorFunc = 0;
        } else if (SensorFunc == 2) {
            osNpcTouch(NPCKey(), llDetectedKey(0), LINK_THIS);
            DEBUG("Touched, calling DoProcessNPCLine");
            SensorFunc = 0;
        }
        DoProcessNPCLine();
    }
    no_sensor(){
        DEBUG ("no target prim located, calling DoProcessNPCLine");
        SensorFunc = 0;
        DoProcessNPCLine();
    }

    
    link_message(integer sender, integer num, string str, key id){
        DEBUG("Command In:" + str);
        if (str=="@go") {
            Stopped = FALSE; // Let's run the notecard
            DEBUG("@go approved, calling DoProcessNPCLine");
            DoProcessNPCLine();
        } else {
            if (Stopped)
            {
                Stack += [str];    // take anything, the controller will filter away non @ stuff
                DoProcessNPCLine();
            } else {
                Stack += [str];    // take anything, the controller will filter away non @ stuff
                TimerEvent(TIMER);
            }
        }
    }
    
}






