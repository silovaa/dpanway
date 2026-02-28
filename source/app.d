//import wayland.display;
//import wayland.xdg_shell_protocol;
//import wayland.logger;
import wayland;

import window;

import std.stdio;

int main()
{
    try {
       
        //Подключение к дисплею происходит автоматически
        auto window = new Window(200, 400);

        // Цикл сообщений для одного окна,
        // повторный add(win) не имеет эффект.
        // По идее этот цикл можно перенести в окно или даже
        // в базовый класс и запускать методом window.show()
        // но пока оставим так, что бы не усложнять наследование
        auto loop = SinglEventLoop();

        window.setTitle("Example application");
        //window.onClosed = (){isrun = false;};
        
        //Если не добавить ни одного окна в run() сработает assert
        loop.add(window);

        //При закрытии последнего окна цикл завершится
        loop.run();
    }
    catch(Exception e) {
        writeln(e.msg);
        return 1;
    }

    return 0;
}
