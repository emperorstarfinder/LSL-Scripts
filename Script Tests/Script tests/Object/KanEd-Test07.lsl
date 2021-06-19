// :SHOW:
// :CATEGORY:Scripting
// :NAME:Script Tests
// :AUTHOR:Justin Clark-Casey (justincc)
// :KEYWORDS:Opensim
// :CREATED:2019-04-04 20:49:51
// :EDITED:2019-04-04  19:49:51
// :ID:1124
// :NUM:1981
// :REV:1
// :WORLD:Opensim
// :DESCRIPTION:
// One of many tests for Opensim
// :CODE:

vector rotationCenter;

default
{
   state_entry()
   {
       llSay( 0, "Hello, Avatar!");
       vector startPoint = llGetPos();
       rotationCenter = startPoint + < 3, 3, 3 >; 
       // distance to the point of rotation should probably be a
       // function of the max dimension of the object.
   }

   touch_start(integer total_number)
   {
       llSay( 0, "Touched." );

       // Define a "rotation" of 10 degrees around the z-axis.
       rotation Z_15 = llEuler2Rot( < 0, 0, 15 * DEG_TO_RAD > );
        
       integer i;
       for( i = 1; i < 100; i++ )   // limit simulation time in case of
       {                            // unexpected behavior.
           vector currentPosition = llGetPos();

           vector currentOffset = currentPosition - rotationCenter;
          
           // rotate the offset vector in the X-Y plane around the 
           // distant point of rotation. 
           vector rotatedOffset = currentOffset * Z_15;
           vector newPosition = rotationCenter + rotatedOffset;

           llSetPos( newPosition ); 
       }  
       llSay( 0, "Orbiting stopped" );              
   }
}  

