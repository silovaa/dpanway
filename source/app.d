import wayland.display;
import wayland.compositor;
import wayland.wlr_layer_shell;

import std.stdio;
import core.sys.posix.poll: poll, pollfd, POLLIN, POLLOUT;

import window;

enum EventT
{
    system,
    wayland,
    count
}

struct DisplayLoop
{
    this(const(char)* name)
    {
        m_display = WlDisplay(name);
       
	    m_registry = WlRegistry(m_display);

        m_registry.onGlobal = &global_cb;

        if (wl_display_roundtrip(m_display) < 0) 
		    throw new Exception("wl_display_roundtrip() failed");

	    if (!m_compositor.isInit) 
		    throw new Exception("compositor doesn't support wl_compositor");
		
	    if (!m_shm.isInit)
		    throw new Exception("compositor doesn't support wl_shm");
	
        if (!m_layer_shell.isInit) 
            throw new Exception("compositor doesn't support zwlr_layer_shell_v1");

        // m_cursor.create(22);

        //fds[EventT.system].fd = -1;
		//fds[EventT.system].events = POLLIN;

        fds[EventT.wayland].fd = wl_display_get_fd(m_display);
		fds[EventT.wayland].events = POLLIN;
    }

    void global_cb(uint name, const(char)* iface_str, uint ver) nothrow
    {
        if (m_compositor.isSame(iface_str)) 
            m_registry.bind(m_compositor, iface_str, name, ver);
        else
        if (m_shm.isSame(iface_str))
            m_registry.bind(m_shm, iface_str, name, ver);
        else
        if (m_layer_shell.isSame(iface_str))
            m_registry.bind(m_layer_shell, iface_str, name, ver);
        else
        if (WlOutput.isSame(iface_str)) {

            //To do добавление нескольких мониторов
            if (m_output.isInit) return;

            m_registry.bind(m_output, iface_str, name, ver);
       
            LayerWindow[] valid_surf;
            foreach (win; m_window_pool) 
                if (win.make_surface(m_compositor, m_layer_shell, m_output))
                    valid_surf ~= win;

            m_window_pool =  valid_surf;
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
     * Создает поверхность и передат его окну
     */
    void add(LayerWindow win)
    {
        win.prepare(m_display);

        //если экрана нет, создание поверхности откладываем
        if (m_output.isInit)
            if (!win.make_surface(m_compositor, m_layer_shell, m_output))
                throw new Exception("make surface layer shell failed");

        m_window_pool ~= win;
    }

private:
    pollfd[EventT.count] fds;
    bool isRuning = false;

    WlDisplay m_display;
    WlRegistry m_registry; 

    WlCompositor m_compositor;
    WlShm m_shm;
    WlrLayerShell m_layer_shell;
    //Wl_proxy* m_xdg_wm_base;

    //To do добавление нескольких мониторов
    WlOutput m_output;
    LayerWindow[] m_window_pool;

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

        // auto m_display = WlDisplay(null);
	    // auto m_registry = WlRegistry(m_display); int tt = 99;

        // m_registry.onGlobal = (uint name, const(char)* iface, uint ver) nothrow {
        //                 try {
        //                 import std.string;  
        //                 writeln("Global name: ", fromStringz(iface), "  version: ", ver);
        //                 } catch (Exception ) return;
        //             };

        // if (wl_display_roundtrip(m_display) < 0) 
 		//     throw new Exception("wl_display_roundtrip() failed");
    }
    catch(Exception e) {
        writeln(e.msg);
        return 1;
    }

    return 0;
}