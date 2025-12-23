module wayland.display;

import core.sys.posix.poll: poll, pollfd, POLLIN, POLLOUT;
import std.exception;
import std.string;
import std.stdio;

import wayland.core;

/** 
 * Статический класс для одного потока
 */
struct Display
{
public:

    static ref const(Display) connect(T...)(const(char)* name = null)
    {
        if (!m_display){ 

            s_globals = new Global[T.length];
            static foreach (Type; T) {
                Type.registry(s_globals);
            }

            get() = Display(name);
        }

        return get();
    }

    void event_wait() const
    {
        while (wl_display_prepare_read(m_display) != 0) {
            if (wl_display_dispatch_pending(m_display) < 0)
                throw new Exception("failed to dispatch pending Wayland events");
        }

        int ret;

        while ((ret = wl_display_flush(m_display)) < 0) {
            if (errno == EINTR) {
                continue;
            }

            if (errno == EAGAIN) {
                pollfd[1] fds;
                fds[0].fd = m_fds[EventT.wayland].fd;
                fds[0].events = POLLOUT;

                do {
                    ret = poll(fds, 1, -1);
                } while (ret < 0 && errno == EINTR);
            }
        }

        if (ret < 0) {
            wl_display_cancel_read(m_display);
            throw new Exception("failed to display flush");
        }

        do {
            ret = poll(m_fds, EventT.count - 1, -1); //To do add system interrupts
        } while (ret < 0 && errno == EINTR);

        if (ret < 0) {
            if (m_fds[EventT.wayland].revents & POLLHUP)
                throw new Exception("disconnected from wayland");

            wl_display_cancel_read(m_display);
            throw new Exception("failed to poll():");
        }

        if (m_fds[EventT.wayland].revents & POLLIN) {

            if (wl_display_read_events(m_display) < 0)
                throw new Exception("failed to read Wayland events");
        }
        else
            wl_display_cancel_read(m_display);

        if (wl_display_dispatch_pending(m_display) < 0)
            throw new Exception("failed to dispatch pending Wayland events");

        if (m_fds[EventT.key].revents & POLLIN) {
            key_repeat_emit();// from seat patition
        }
    }

    ~this()
    {
        if (m_display) {
            foreach(Global global; s_globals)
                global.destroy();

            s_globals.init;

	        if (m_compositor)  wl_proxy_destroy(m_compositor);
	        if (m_registry) wl_proxy_destroy(m_registry);

	        wl_display_disconnect(m_display);
            m_display = null;
        }
    }

package:
    static ref Display get()
    {
        static Display dpy;
        return dpy;
    }

    static wl_display* native()
    {
        return m_display;
    }

    static wl_compositor* compositor()
    {
        return get().m_compositor;
    }

private:

    static Global[] s_globals;
    static wl_display* m_display;

    wl_proxy*   m_registry;
    immutable Wl_registry_listerner m_registry_listener;  

    wl_compositor* m_compositor;

    enum EventT {
        system, wayland, key, count
    }

    pollfd[EventT.count] m_fds;

    this(const(char)* name)
    {
        m_display = enforce(wl_display_connect(name), 
                            "failed to create display");
       
	    m_registry = wl_proxy_marshal_constructor(
                cast(Wl_proxy*) m_display,
                WL_DISPLAY_GET_REGISTRY, &wl_registry_interface, null);

        enforce(wl_proxy_add_listener(m_registry, 
                                    cast(Callback*) &m_registry_listener, 
                                    &this) >= 0,
                "add registry listener failed");

        if (wl_display_roundtrip(m_display) < 0) 
		    throw new Exception("wl_display_roundtrip() failed");

	    if (m_compositor is null) 
		    throw new Exception("compositor doesn't support wl_compositor");


        m_fds[EventT.wayland].fd = wl_display_get_fd(m_display);
		m_fds[EventT.wayland].events = POLLIN;
        m_fds[EventT.system].fd = -1; //To do add system interrupts

        m_fds[EventT.key].fd = key_repeat_fd();
        m_fds[EventT.key].events = POLLIN;
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
        import wayland.wlr_layer_shell_protocol;

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
        } else if (LayerShellInterface.isSame(iface)) {
            state.m_layer_shell = wl_proxy_marshal_constructor(registry, 
                                                            WL_REGISTRY_BIND, 
                                                            LayerShellInterface.native, name, 
                                                            LayerShellInterface.native.name, 
                                                            4, null);
        } else if (strcmp(iface, wl_seat_interface.name) == 0) {
            // wl_seat* seat = wl_proxy_marshal_constructor(registry, 
            //                                                 WL_REGISTRY_BIND, 
            //                                                 wl_seat_interface, name, 
            //                                                 wl_seat_interface.name, 
            //                                                 3, null);
            // create_seat(state, seat);

            writeln("add seat name: ", iface);

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
