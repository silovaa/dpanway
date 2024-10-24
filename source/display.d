module display;

import std.stdio;
import core.sys.posix.poll: poll, pollfd, POLLIN, POLLOUT;

import wayland.display;
import wayland.compositor;
import wayland.wlr_layer_shell_protocol;

class ViewPlace
{
    uint width = 0;
    uint height = 0;
    Layer layer;
    Anchor anchor;
}

Display default_display()
{
    if (display.native is null){
        display = WlDisplay(null);
        registry = WlRegistry(wl_dpy);
        registry.onGlobal = &global_cb;

        if (wl_display_roundtrip(wl_dpy) < 0) 
		    throw new Exception("wl_display_roundtrip() failed");

	    if (!compositor.isInit) 
		    throw new Exception("compositor doesn't support wl_compositor");
		
	    if (!shm.isInit)
		    throw new Exception("compositor doesn't support wl_shm");
	
        if (!layer_shell.isInit) 
            throw new Exception("compositor doesn't support zwlr_layer_shell_v1");

        if (outputs is null)
            throw new Exception("output not found");
    }

    static auto dpy = Display(false);
    return dpy;
}

enum EventT
{
    system,
    wayland,
    count
}

struct Display
{
    /**
    * Привязывает виджет к экрану с заданным номером,
    * 0-й экран считаем основным. 
    * To do сортировать экраны по локальным координатам 
    * протокола xdg-output если он поддерживается композитором
    **/
    void add(uint screen, Widget widget, SurfaceCfg cfg)
    {
        m_surfaces[screen] ~= Surface(screen, widget);
        
        if (screen <= output.length){
            m_surfaces[screen][$ - 1].create(cfg, outputs[screen], this);
        }
    }

    void stop()
    {
        isRuning = false;
    }

    void run_loop()
    {
        if (isRuning) return;

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

    @disable this();

private:
    bool isRuning;
    Surface[][uint] m_surfaces;

    this(bool runing)
    {
       isRuning = runing;
    }
}

private: 
    WlCompositor compositor;
    WlShm shm;
    WlrLayerShell layer_shell;
    Output[] outputs;

    WlRegistry registry;
    WlDisplay display;

    struct Output
    {
        this(WlOutput native, Surface[] surfaces)
        {
            this.native = native;
            m_surfaces = surfaces;
            //this.native.onName = &name_cb;
            //this.native.onDone = &done_cb;
        }

        WlOutput native;
        string name;
        uint scale;
        Surface[] m_surfaces;

        void map(in ref SurfaceCfg cfg, in ref Display dpy) {

            if (m_surfaces is null) return;

            m_surfaces[$ - 1].create(cfg, this, dpy);
        }
    }

    struct Surface
    {
        Widget m_widget;
        uint m_id_screen;

        WlSurface m_surface;
        WlrLayerSurface m_layer_surface;
        
        this(uin screen, Widget widget, in ref Display dpy)
        {
            m_widget = widget;
            m_id_screen = screen;
        }

        void create(in ref SurfaceCfg cfg, in ref Output output, in ref Display dpy)
        {
            m_surface = dpy.m_compositor.create_surface();

            //To do create region

            m_layer_surface = dpy.m_layer_shell.create_surface(m_surface, 
                                                output.native, cfg.layer);

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

    