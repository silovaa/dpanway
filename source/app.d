import wayland.display;
import wayland.xdg_shell_protocol;
import wayland.logger;

import window;

import std.stdio;

int main()
{
    try {
        auto ref dpy = Display.connect!(XDGTopLevel);//, XDGDecoration);

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
