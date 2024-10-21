module display;

import wayland.display;
import wayland.compositor;
import wayland.wlr_layer_shell_protocol;

struct Bar
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

class Display
{
    Bar* addBar(uint num_screen)
    {
        
    }

    void run_loop()
    {

    }

private:
    WlDisplay display; 

    WlCompositor compositor;
    WlShm shm;
    WlrLayerShell layer_shell;
    WlOutput[] output;

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

    