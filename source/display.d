module display;

import wayland.display;
import wayland.compositor;
import wayland.wlr_layer_shell_protocol;

class Widget
{
    uint width;
    uint height;
    Layer layer;
    Anchor anchor;

private:
    uint id_screen;
}

Display default_display()
{
    static Display dpy;
    if (dpy is null)
        dpy = new Display;

    return dpy;
}

enum EventT
{
    system,
    wayland,
    count
}

class Display
{
    void addWidget(uint num_screen, Widget widget)
    {
        
    }

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

private:
    WlDisplay display; 

    WlCompositor compositor;
    WlShm shm;
    WlrLayerShell layer_shell;
    WlOutput[] outputs;

    struct Surface
    {
        Widget widget;
        Wl_Surface base;
        WlrLayerSurface layer;
    }

    Surface[] surfaces;

//private:
    this()
    {
        display = WlDisplay(null);
        registry = WlRegistry(display);
        registry.onGlobal = &global_cb;

        if (wl_display_roundtrip(display) < 0) 
		    throw new Exception("wl_display_roundtrip() failed");

	    if (!compositor.isInit) 
		    throw new Exception("compositor doesn't support wl_compositor");
		
	    if (!shm.isInit)
		    throw new Exception("compositor doesn't support wl_shm");
	
        if (!layer_shell.isInit) 
            throw new Exception("compositor doesn't support zwlr_layer_shell_v1");

        if (output is null)
            throw new Exception("output not found");
    }

    WlRegistry registry;

    void global_cb(uint name, const(char)* iface_str, uint ver) nothrow
    {
        if (compositor.isSame(iface_str)) 
            registry.bind(compositor, iface_str, name, ver);
        else
        if (shm.isSame(iface_str))
            registry.bind(shm, iface_str, name, ver);
        else
        if (layer_shell.isSame(iface_str))
            registry.bind(layer_shell, iface_str, name, ver);
        else
        if (WlOutput.isSame(iface_str)) {

            //To do добавление нескольких мониторов
            if (output.isInit) return;

            registry.bind(output, iface_str, name, ver);
       
            // LayerWindow[] valid_surf;
            // foreach (win; m_window_pool) 
            //     if (win.make_surface(m_compositor, m_layer_shell, m_output))
            //         valid_surf ~= win;

            // m_window_pool =  valid_surf;
        }
    }
}

    