import wayland.display;
import window;

import std.stdio;

int main()
{
    try {
        auto loop = DisplayLoop(null);
        
        loop.add(new Window(200, 400));
        
        loop.run();
    }
    catch(Exception e) {
        writeln(e.msg);
        return 1;
    }

    return 0;
}