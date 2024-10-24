
import display;
import window;

int main()
{
    try {
        auto dpy = default_display();

        //Создаем панель на 0-м экране(основном), высотой 50, 
        //привязанную к верхнему краю, шириной равной ширине экрана
        auto view = new View();
        view.onClose = (){ dpy.stop(); }

        view.content(
            Background(Color(0, 100, 125, 1))
        );
        
        dpy.add(0, view).horizontal(50, Anchor.TOP);
        dpy.run_loop();
    }
    catch(Exception e) {
        writeln(e.msg);
        return 1;
    }

    return 0;
}