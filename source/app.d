import wayland.display;
import window;

import std.stdio;

struct DisplayLoop
{
    this(const(char)* name)
    {
        m_display = WlDisplay(name);
       
	    m_registry = WlRegistry(m_display);

        m_registry.listener(&global_cb);

        if (wl_display_roundtrip(m_display) < 0) 
		    throw new Exception("wl_display_roundtrip() failed");

	    if (m_compositor is null) 
		    throw new Exception("compositor doesn't support wl_compositor");
		
	    if (m_shm is null)
		    throw new Exception("compositor doesn't support wl_shm");
	
        if (m_layer_shell is null) 
            throw new Exception("compositor doesn't support zwlr_layer_shell_v1");

        // m_cursor.create(22);

        //fds[EventT.system].fd = -1;
		//fds[EventT.system].events = POLLIN;

        fds[EventT.wayland].fd = wl_display_get_fd(m_display);
		fds[EventT.wayland].events = POLLIN;
    }

    ~this()
    {
        if (m_display) {
            if (m_layer_shell) wl_proxy_destroy(m_layer_shell);
	        if (m_compositor)  wl_proxy_destroy(m_compositor);
	        if (m_shm) wl_proxy_destroy(m_shm);
	        if (m_registry) wl_proxy_destroy(m_registry);
        //wl_proxy_destroy(m_xdg_wm_base);
	        wl_display_disconnect(m_display);
        }
    }

    void run()
    {
        isRuning = true;

        while (isRuning) {writeln("enter to loop");
            
            // Wayland requests can be generated while handling non-Wayland events.
            // We need to flush these.
            int ret = 0;
            do {
                ret = wl_display_dispatch_pending(m_display);
                if (wl_display_flush(m_display) < 0) 
                    throw new Exception("failed to flush Wayland events");
            } while (ret > 0);
            if (ret < 0) 
                throw new Exception("failed to dispatch pending Wayland events");
            
            if (poll(fds.ptr, EventT.count, -1) > 0) {

                // if (fds[EventT.system].revents & POLLIN) 
			    //     break;
		    
                if (fds[EventT.wayland].revents & POLLIN) {
                    ret = wl_display_dispatch(m_display);
                    if (ret < 0) 
                        throw new Exception("failed to read Wayland events");    
                }
                if (fds[EventT.wayland].revents & POLLOUT) {
                    ret = wl_display_flush(m_display);
                    if (ret < 0) 
                        throw new Exception("failed to flush Wayland events");
                }
            }
            else throw new Exception("failed to poll(): ");
        }
    }

    /** 
     * Добавляет окно на экран  
     * Params:
     *   surface = окно
     * Создает поверхность и передат его окну
     */
    void add(LayerSurface ls)
    {
        ls.prepare(m_display);

        //если экрана нет, создание поверхности откладываем
        if (m_screen.isValid)
            if (!ls.make_surface(m_compositor, m_layer_shell, m_screen.output))
                throw new Exception("make surface layer shell failed");

        m_screen.surfaces ~= ls;
    }

private:
    pollfd[EventT.count] fds;
    bool isRuning = false;

    WlDisplay m_display;
    WlRegistry m_registry; 

    WlCompositor m_compositor;
    WlShm m_shm;
    WlLayerShell m_layer_shell;
    //Wl_proxy* m_xdg_wm_base;

    Screen m_screen;

    void add_screen(Wl_proxy* output, uint id, const(char)* name_str)
    {
        //To do добавление нескольких мониторов
        if (m_screen.isValid) return;

        m_screen.output = output; 
        m_screen.global_name = id; 
        m_screen.name = fromStringz(name_str);

        if (wl_proxy_add_listener(output, 
                                cast(Callback*) &m_screen.output_listener, 
                                &m_screen) < 0) {
            //To do нужно ли уничтожить output???
            //m_screen.output = null;
            writeln("err!!! output name:", name_str);
        }
        else {
            LayerSurface[] valid_surf;
            foreach (LayerSurface surf; m_screen.surfaces) 
                if (surf.make_surface(m_compositor, m_layer_shell, output))
                    valid_surf ~= surf;

            m_screen.surfaces =  valid_surf;

            writeln("add output name:", m_screen.name);
        }
    }

	//xdg_activation_v1 *m_xdg_activation;
	//struct wp_cursor_shape_manager_v1 *cursor_shape_manager;

    //Cursor m_cursor;
}


int main()
{
    try {
        auto loop = DisplayLoop(null);
        
        loop.add(new Window(200, 400));
        
        loop.run();
    }
    catch(Exception e) {
        writeln(e.msg);
        return 1;
    }

    return 0;
}