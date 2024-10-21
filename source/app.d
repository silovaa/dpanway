import std.stdio;
import core.sys.posix.poll: poll, pollfd, POLLIN, POLLOUT;

import display;
import window;

int main()
{
    try {
        auto dpy = default_display();

        //Минимальная конфигурация виджета это высота и ширина
        dpy.addWidget(0, new Panel(200, 400));
        
        dpy.run_loop();

    }
    catch(Exception e) {
        writeln(e.msg);
        return 1;
    }

    return 0;
}