import std.stdio;
import core.sys.posix.poll: poll, pollfd, POLLIN, POLLOUT;

import display;
import window;

enum EventT
{
    system,
    wayland,
    count
}

    /** 
     * Добавляет окно на экран  
     * Создает поверхность и передат его окну
     */
    // void add(LayerWindow win)
    // {
    //     win.prepare(display);

    //     //если экрана нет, создание поверхности откладываем
    //     if (m_output.isInit)
    //         if (!win.make_surface(m_compositor, m_layer_shell, m_output))
    //             throw new Exception("make surface layer shell failed");

    //     m_window_pool ~= win;
    // }

void run_loop()
{
    isRuning = true;

    while (isRuning) {writeln("enter to loop");
        
        // Wayland requests can be generated while handling non-Wayland events.
        // We need to flush these.
        int ret = 0;
        do {
            ret = wl_display_dispatch_pending(display);
            if (wl_display_flush(display) < 0) 
                throw new Exception("failed to flush Wayland events");
        } while (ret > 0);
        if (ret < 0) 
            throw new Exception("failed to dispatch pending Wayland events");    
            
        if (poll(fds.ptr, EventT.count, -1) > 0) {

            // if (fds[EventT.system].revents & POLLIN) 
			//     break;
		    
            if (fds[EventT.wayland].revents & POLLIN) {
                ret = wl_display_dispatch(display);
                if (ret < 0) 
                    throw new Exception("failed to read Wayland events");    
            }
            if (fds[EventT.wayland].revents & POLLOUT) {
                ret = wl_display_flush(display);
                if (ret < 0) 
                    throw new Exception("failed to flush Wayland events");
            }
        }
        else throw new Exception("failed to poll(): ");
     }
}    

int main()
{
    try {
        auto dpy = default_display();

        auto bar = Bar(200, 400);
        dpy.addBar(0, bar);

        // bar.width(200).height(400).layer(Top);

        //dpy.addWidget(new Window(200, 400));
        
        dpy.run_loop();

        // auto display = WlDisplay(null);
	    // auto m_registry = WlRegistry(display); int tt = 99;

        // m_registry.onGlobal = (uint name, const(char)* iface, uint ver) nothrow {
        //                 try {
        //                 import std.string;  
        //                 writeln("Global name: ", fromStringz(iface), "  version: ", ver);
        //                 } catch (Exception ) return;
        //             };

        // if (wl_display_roundtrip(display) < 0) 
 		//     throw new Exception("wl_display_roundtrip() failed");
    }
    catch(Exception e) {
        writeln(e.msg);
        return 1;
    }

    return 0;
}