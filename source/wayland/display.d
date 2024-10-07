module wayland.display;

import core.sys.posix.poll: poll, pollfd, POLLIN, POLLOUT;
import std.exception;
import std.string;
import std.stdio;

import wayland.core;
import wayland.layer_shell;

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
        m_display = enforce(wl_display_connect(name), 
                            "failed to create display");
       
	    m_registry = wl_proxy_marshal_constructor(
                cast(Wl_proxy*) m_display,
                WL_DISPLAY_GET_REGISTRY, &wl_registry_interface, null);

        enforce(wl_proxy_add_listener(m_registry, 
                                    cast(Callback*) &m_registry_listener, 
                                    &this) < 0,
                "add registry listener failed");

        if (wl_display_roundtrip(m_display) < 0) 
		    throw new Exception("wl_display_roundtrip() failed");

	    if (m_compositor is null) 
		    throw new Exception("compositor doesn't support wl_compositor");
		
	    if (m_shm is null)
		    throw new Exception("compositor doesn't support wl_shm");
	
        if (m_layer_shell is null) 
            throw new Exception("compositor doesn't support zwlr_layer_shell_v1");

        // m_cursor.create(22);

        fds[EventT.system].fd = -1;
		fds[EventT.system].events = POLLIN;

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

        while (isRuning) {
            
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

                if (fds[EventT.system].revents & POLLIN) 
			        break;
		    
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

    Wl_display*    m_display;

    Wl_proxy*   m_registry;
    immutable Wl_registry_listerner m_registry_listener;  

    Wl_proxy* m_compositor;
    Wl_proxy* m_shm;
    Wl_proxy* m_layer_shell;
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

            writeln("add output name:", name_str);
        }
    }

	//xdg_activation_v1 *m_xdg_activation;
	//struct wp_cursor_shape_manager_v1 *cursor_shape_manager;

    //Cursor m_cursor;
}

// struct Cursor
// {
// 	uint32_t size;
// 	uint32_t scale;
// 	wl_cursor_theme *theme;
// 	const wl_cursor_image *image;
// 	wl_surface *surface;

//     void create(uint req_size)
//     {
//         // Set up the cursor. It needs a wl_surface with the cursor loaded into it.
//         // If one of these fail, mako will work fine without the cursor being able to change.
//         const char *cursor_size_env = getenv("XCURSOR_SIZE");
        
//         if (cursor_size_env != NULL) {
//             errno = 0;
//             char *end;
//             int temp_size = (int)strtol(cursor_size_env, &end, 10);
//             if (errno == 0 && cursor_size_env[0] != 0 && end[0] == 0 && temp_size > 0) {
//                 cursor_size = temp_size;
//             } else {
//                 fprintf(stderr, "Error: XCURSOR_SIZE is invalid\n");
//             }
//         }

// 	    size = cursor_size;
//     }	
// }

struct Screen
{
    LayerSurface[] surfaces;

    Wl_proxy* output;
    immutable Wl_output_listener output_listener = {
        geometry: &handle_geometry,
        scale:    &handle_scale,
        name:     &handle_name
    };

    uint global_name;
    uint scale = 1;
    const(char)[] name;

    enum Wl_output_subpixel {
        /**
        * unknown geometry
        */
        UNKNOWN = 0,
        /**
        * no geometry
        */
        NONE = 1,
        /**
        * horizontal RGB
        */
        HORIZONTAL_RGB = 2,
        /**
        * horizontal BGR
        */
        HORIZONTAL_BGR = 3,
        /**
        * vertical RGB
        */
        VERTICAL_RGB = 4,
        /**
        * vertical BGR
        */
        VERTICAL_BGR = 5,
    } 

    int subpixel;

    @property bool isValid() const
    {
        return output != null;
    }

    extern (C) nothrow {

        //static void noop(void *,...) nothrow {}

        struct Wl_output_listener
        {
            void function (void *data,
                        Wl_proxy *wl_output,
                        int x,
                        int y,
                        int physical_width,
                        int physical_height,
                        int subpixel,
                        const(char)* make,
                        const(char)* model,
                        int transform) geometry;
            
            void function (void *data,
		                Wl_proxy *wl_output,
		                uint flags,
		                int width,
		                int height,
		                int refresh) mode = (void*,Wl_proxy*,uint,int,int,int){};

            void function (void *data,
		                Wl_proxy *wl_output) done = (void*,Wl_proxy*){};

            void function (void *data,
		                Wl_proxy *wl_output,
		                int factor) scale;

            void function (void *data,
		                Wl_proxy *wl_output,
		                const(char)* name) name;

            void function (void *data,
			            Wl_proxy *wl_output,
			            const(char)* description) description = (void*,Wl_proxy*,const(char)*){};
        }

        static void handle_geometry(void *data, Wl_proxy* wl_output,
		            int x, int y, int phy_width, int phy_height,
		            int subpixel, const(char)* make, const(char)* model,
		            int transform) 
        {

            auto self = cast(Screen*) data;
            self.subpixel = subpixel;
        }

        static void handle_scale(void *data, Wl_proxy* wl_output,
                        int factor) 
        {
            auto self = cast(Screen*) data;
            self.scale = factor;
        }

        static void handle_name(void *data, Wl_proxy* wl_output,
            const char *name) 
        {
            auto self = cast(Screen*) data;
            self.name = fromStringz(name);
        }
    } 
}

private:
extern (C) {

    extern const Wl_interface wl_registry_interface;
    extern const Wl_interface wl_compositor_interface;
    extern const Wl_interface wl_shm_interface;

    struct Wl_registry_listerner
    {
        void function (void* data,
                       Wl_proxy* wl_registry,
                       uint name,
                       const(char)* iface,
                       uint ver) global = &handle_global;
  
        void function (void *data,
                       Wl_proxy *wl_registry,
                       uint name) global_remove = &handle_global_rem;
    }
    
    Wl_display* wl_display_connect(const(char)* name = null);
    int wl_display_get_fd(Wl_display*);
    int wl_display_dispatch(Wl_display*);
    int wl_display_dispatch_pending(Wl_display*);
    int wl_display_flush(Wl_display*);
    int wl_display_roundtrip(Wl_display*);
    void wl_display_disconnect(Wl_display*);

    enum uint WL_DISPLAY_SYNC = 0;
    enum uint WL_DISPLAY_GET_REGISTRY = 1;
    enum uint WL_REGISTRY_BIND = 0;

    void handle_global(void* data, Wl_proxy* registry,
		               uint name, const(char)* iface, uint ver) 
    {
        import core.stdc.string: strcmp;
        import wlr_layer_shell_protocol;

	    auto state = cast(DisplayLoop*) data;

        if (strcmp(iface, wl_compositor_interface.name) == 0) {
            state.m_compositor = wl_proxy_marshal_constructor(registry, 
                                                            WL_REGISTRY_BIND, 
                                                            &wl_compositor_interface, name, 
                                                            wl_compositor_interface.name, 
                                                            4, null);
        } else if (strcmp(iface, wl_shm_interface.name) == 0) {
            state.m_shm = wl_proxy_marshal_constructor(registry, 
                                                            WL_REGISTRY_BIND, 
                                                            &wl_shm_interface, name, 
                                                            wl_shm_interface.name, 
                                                            1, null);
        } else if (strcmp(iface, LayerSurface.wl_iface.name) == 0) {
            state.m_layer_shell = wl_proxy_marshal_constructor(registry, 
                                                            WL_REGISTRY_BIND, 
                                                            &LayerSurface.wl_iface, name, 
                                                            LayerSurface.wl_iface.name, 
                                                            4, null);
        } else if (strcmp(iface, wl_seat_interface.name) == 0) {
            // wl_seat* seat = wl_proxy_marshal_constructor(registry, 
            //                                                 WL_REGISTRY_BIND, 
            //                                                 wl_seat_interface, name, 
            //                                                 wl_seat_interface.name, 
            //                                                 3, null);
            // create_seat(state, seat);

            writeln("add seat name:", iface);

        } else if (strcmp(iface, wl_output_interface.name) == 0) {
            state.add_screen(wl_proxy_marshal_constructor(registry, 
                                                        WL_REGISTRY_BIND, 
                                                        &wl_output_interface, name, 
                                                        wl_output_interface.name, 
                                                        4, null),
                            name, iface);
        }
        //  else if (strcmp(iface, xdg_wm_base_interface.name) == 0) {
        //     state.m_xdg_wm_base = wl_proxy_marshal_constructor(registry, 
        //                                                     WL_REGISTRY_BIND, 
        //                                                     xdg_wm_base_interface, name, 
        //                                                     xdg_wm_base_interface.name, 
        //                                                     1, null);
        //      writeln("add xdg_activation name:", iface);
        // } else if (strcmp(iface, wp_cursor_shape_manager_v1_interface.name) == 0) {
        //     // state.cursor_shape_manager = wl_proxy_marshal_constructor(registry, 
        //     //                                                 WL_REGISTRY_BIND, 
        //     //                                                 wp_cursor_shape_manager_v1_interface, name, 
        //     //                                                 wp_cursor_shape_manager_v1_interface.name, 
        //     //                                                 1, null);
        //     writeln("add cursor_shape name:", iface);
        // }
    }

    void handle_global_rem(void *data, Wl_proxy *registry, uint name) 
    {
        writeln("handle_global_rem");
    }
}
