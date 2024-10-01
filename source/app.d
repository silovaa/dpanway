import wayland.display;
import window;

int main()
{
    try {
        auto loop = DisplayLoop(null);
        
        loop.get_screen().add(new Window(200, 400));
        
        loop.run();
    }
    catch(Exception e) {
        writeln(e.msg);
        return 1;
    }

    return 0;
}