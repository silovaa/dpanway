import wayland;
import egl;

void main()
{
    try {
        auto app = new WlState;
        auto context = new EglState(app);
        auto window = new Window(context);

        window.size(200, 400);
        
        app.run();
    }
    catch(Exception e) {
        writeln(e.msg);
    }
}