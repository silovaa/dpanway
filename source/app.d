//import wayland.display;
//import wayland.xdg_shell_protocol;
//import wayland.logger;
//import wayland;

import window;

import std.stdio;

int main()
{
    try {
        bool isrun = true;
        auto window = new Window(200, 400);

        window.setTitle("Example application");
        window.onClosed = (){isrun = false;};

        while(isrun) {
            dpy.event_wait();
        }
    }
    catch(Exception e) {
        writeln(e.msg);
        return 1;
    }

    return 0;
}
