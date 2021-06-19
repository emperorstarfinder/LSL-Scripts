// :SHOW:
// :CATEGORY:Scripting
// :NAME:Script Tests
// :AUTHOR:Justin Clark-Casey (justincc)
// :KEYWORDS:Opensim
// :CREATED:2019-04-04 20:49:51
// :EDITED:2019-04-04  19:49:51
// :ID:1124
// :NUM:1982
// :REV:1
// :WORLD:Opensim
// :DESCRIPTION:
// One of many tests for Opensim
// :CODE:

default
{
   state_entry()
   {
       llSay( 0, "Hello, Avatar! Touch to launch me straight up.");
       llSetStatus( 1, TRUE );  // turn on physics.
   }

   touch_start(integer total_number)
   {  
       vector start_color = llGetColor( ALL_SIDES ); // save current color. 
       llSetColor( < 1.0, 0.0, 0.0 > , ALL_SIDES );  // set color to red.
       
       float objMass = llGetMass();
       float Z_force = 20.0 * objMass;
       
       llApplyImpulse( < 0.0, 0.0, Z_force >, FALSE );
       
       llSay( 0, "Impulse of " + (string)Z_force + " applied." );
       llSetColor( start_color , ALL_SIDES ); // set color to green.
   }
}

