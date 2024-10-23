
import display;
import window;

int main()
{
    try {
        auto dpy = default_display();

        //Создаем панель на 0-м экране(основном), высотой 50, 
        //привязанную к верхнему краю, шириной равной ширине экрана
        auto view = new View(dpy.area(0).horizontal(50, Anchor.TOP));
        view.onClose = (){ dpy.stop(); }

        view.content(
            Background(Color(0, 100, 125, 1))
        )
        
        dpy.run_loop();
    }
    catch(Exception e) {
        writeln(e.msg);
        return 1;
    }

    return 0;
}