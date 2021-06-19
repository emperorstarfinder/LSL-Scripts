// :SHOW:
// :CATEGORY:Scripting
// :NAME:Script Tests
// :AUTHOR:Justin Clark-Casey (justincc)
// :KEYWORDS:Opensim
// :CREATED:2019-04-04 20:49:51
// :EDITED:2019-04-04  19:49:51
// :ID:1124
// :NUM:2011
// :REV:1
// :WORLD:Opensim
// :DESCRIPTION:
// One of many tests for Opensim
// :CODE:

integer count = 0;
integer refreshRate = 300;
string URL1 = "http://icons.wunderground.com/data/640x480/2xus_rd.gif";  
string URL2 = "http://icons.wunderground.com/data/640x480/2xus_sf.gif"; 
string URL3 = "http://icons.wunderground.com/data/640x480/2xus_st.gif"; 
string dynamicID="";
string contentType="image";
    
refresh_texture()
{
    count++;
    string url = "";
    integer c = count % 3;
    
    if (c == 0) {
        url = URL1;    
    } else if (c == 1) {
        url = URL2;
    } else {
        url = URL3;
    }
    // refresh rate is not yet respected here, which is why we need the timer
    osSetDynamicTextureURL(dynamicID, contentType ,url , "", refreshRate );
}
        
default
{
    state_entry()
    {
        refresh_texture();
        llSetTimerEvent(refreshRate); // create a "timer event" every 300 seconds.
    }
   
    timer()
    {
        refresh_texture();
    }
    
    touch_start(integer times)
    {
        refresh_texture();
    }
}
