import wayland;
import egl;

void main()
{
    try {
        auto wl = new WlState;
        auto window = new Window!Egl(wl);

        window.size(200, 400);
        
        app.run();
    }
    catch(Exception e) {
        writeln(e.msg);
    }
}