// :SHOW:1
// :CATEGORY:Mover
// :NAME:Move-From-Point-To-Point
// :AUTHOR:Unknown
// :KEYWORDS:
// :CREATED:2019-08-30 11:39:48
// :EDITED:2021-04-26  22:40:29
// :ID:1125
// :NUM:2012
// :REV:2
// :WORLD:Second Life
// :DESCRIPTION:
// Move From point to pint tour guide
// :CODE:




integer     m_STEPS = 64;

motionTo(vector dest,rotation rot) {
    integer i;
    vector currentpos   = llGetPos();
    vector step         = (dest - currentpos) / m_STEPS;

    for (i = 1;i <= m_STEPS; i++)
    {
        if (i == (m_STEPS / 2))
        {
            llSetRot(rot);
        }
        llSetPos(currentpos + (step * i));

    }
    llSensor("Track",NULL_KEY,ACTIVE | PASSIVE,10,PI/4);
}

default {
    state_entry()    {
        llSensor("Track",NULL_KEY,ACTIVE | PASSIVE,10,PI/4);
    }
    changed(integer what) {
        if (what & CHANGED_REGION_START){
            llResetScript();
        }
    }
    sensor(integer n) {
        motionTo(llDetectedPos(0),llDetectedRot(0));
    }
    no_sensor()
    {
        llSetTimerEvent(10);
    }
    timer() {
        llSensor("Track",NULL_KEY,ACTIVE | PASSIVE,10,PI/4);
        llSetTimerEvent(0);
    }


}

