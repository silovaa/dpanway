//import wayland.display;
//import wayland.xdg_shell_protocol;
//import wayland.logger;
import wayland;

import window;

import std.stdio;

int main()
{
    try {

        auto ref dpy = Display.connect();
       
        //Подключение к дисплею происходит автоматически но
        //он должен быть подключен. 
        auto window = new Window(200, 400);

        //wayland объекты перед подобными вызовами должны быть проинициализированы
        window.setTitle("Example application");
        //window.onClosed = (){isrun = false;};

        //При закрытии последнего окна цикл завершится
        dpy.run();
    }
    catch(Exception e) {
        writeln(e.msg);
        return 1;
    }

    return 0;
}
