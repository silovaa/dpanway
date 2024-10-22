module display;

import std.stdio;
import core.sys.posix.poll: poll, pollfd, POLLIN, POLLOUT;

import wayland.display;
import wayland.compositor;
import wayland.wlr_layer_shell_protocol;

class Widget
{
    uint width;
    uint height;
    Layer layer;
    Anchor anchor;
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
    /**
    * Привязывает виджет к экрану с заданным номером
    * 0-й экран считаем основным. 
    * To do сортировать экраны по локальным координатам 
    * протокола xdg-output если он поддерживается композитором
    **/
    void addWidget(uint num_screen, Widget widget)
    {
        //widget.m_id_screen = num_screen;

        if (m_outputs.length >= num_screen){
            m_outputs[num_screen].m_surfaces ~= Surface(widget);
            m_outputs[num_screen].native.onDone = &create_all_surface;
        }
            
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

    WlCompositor m_compositor;
    WlShm shm;
    WlrLayerShell m_layer_shell;
    Output[] m_outputs;

    bool isRuning = false;

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
            
            WlOutput output;
            registry.bind(output, iface_str, name, ver);
            m_outputs ~= Output(output);
        }
    }

    void create_all_surface()
    {

    }
}

private:

    struct Output
    {
        this(WlOutput native)
        {
            this.native = native;
            this.native.onName = &name_cb;
            this.native.onDone = &done_cb;
        }

        WlOutput native;
        string name;
        uint scale;
        Surface[] m_surfaces;
    }

    struct Surface
    {
        Widget m_widget;
        WlSurface m_surface;
        WlrLayerSurface m_layer_surface;
        uint m_id_screen;

        this(uin screen, Widget widget, in ref Display dpy)
        {
            m_widget = widget;
            m_id_screen = screen;
            m_surface = dpy.m_compositor.create_surface();

            //To do create region

            m_layer_surface = dpy.m_layer_shell.create_surface(m_surface, 
                                                dpy.m_outputs[screen].native, widget.layer);

            m_layer_surface.onConfig = &configure_cb;
            m_layer_surface.onClosed = &closed_cb;

            m_layer_surface.setSize(widget.width, widget.height);
            m_layer_surface.setAnchor(widget.anchor);
            m_surface.commit();
        }

        void configure_cb(uint w, uint h) nothrow
        {
            
        }

        void closed_cb() nothrow
        {

        }
    }

    