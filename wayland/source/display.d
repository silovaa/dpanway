module wayland.display;

import core.sys.posix.poll;
import core.stdc.errno;
import std.exception;
import std.string;

import wayland.internal.core;
import wayland_import;

/** 
 * Статический класс для одного потока
 */
struct Display
{
public:
    @disable this(this);

    static ref Display connect(T...)(const(char)* name = null)
    {
        if (!instance.m_display){ 

            instance.m_globals.reserve(T.length * 2);
            static foreach (Type; T) {
                Type.registry(instance.m_globals);
            }

            instance.m_globals.assumeSafeAppend();

            instance.construct(name);
        }

        return instance;
    }

    void event_wait() 
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
                    ret = poll(fds.ptr, 1, -1);
                } while (ret < 0 && errno == EINTR);
            }
        }

        if (ret < 0) {
            wl_display_cancel_read(m_display);
            throw new Exception("failed to display flush");
        }

        do {
            ret = poll(m_fds.ptr, EventT.count - 1, -1); //To do add system interrupts
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
            kb_repeat.emit(m_fds[EventT.key].fd);
        }
    }

    ~this()
    {
        if (m_display) {
            foreach(Surface surf; m_surface_pool)
                surf.dispose();
            foreach(Global global; m_globals)
                global.dispose();

            m_globals.length = 0; //??

	        wl_proxy_destroy(cast(wl_proxy*)m_compositor);
	        wl_proxy_destroy(m_registry);

	        wl_display_disconnect(m_display);
            m_display = null;
        }
    }

package:
    static Display instance;

    static wl_display* native()
    {
        return instance.m_display;
    }

    static wl_compositor* compositor()
    {
        return instance.m_compositor;
    }

    Timer kb_repeat;

private:

    Global[] m_globals;
    wl_display* m_display;

    static immutable(wl_registry_listerner) lsr;

    wl_proxy*   m_registry;  
    wl_compositor* m_compositor;

     enum EventT {
        system, wayland, key, count
    }

    pollfd[EventT.count] m_fds;

    SurfaceInterface[wl_surface*] m_surface_pool;

    void construct(const(char)* name)
    {
        m_display = enforce(wl_display_connect(name), 
                            "failed to create display");
       
	    m_registry = enforce(wl_proxy_marshal_flags(cast(wl_proxy*) wl_display,
			                WL_DISPLAY_GET_REGISTRY, 
                            &wl_registry_interface, 
                            wl_proxy_get_version(cast(wl_proxy*)wl_display), 
                            0, null),
                        "failed to create registry");

        auto iter = GlobalIterator(m_globals);

        enforce(wl_proxy_add_listener(m_registry, 
                                    cast(Callback*) &lsr, 
                                    &iter) >= 0,
                "add registry listener failed");

        if (wl_display_roundtrip(m_display) < 0) 
		    throw new Exception("wl_display_roundtrip() failed");

        m_compositor = enforce(iter.compositor, 
		                    "compositor doesn't support wl_compositor");

        m_fds[EventT.wayland].fd = wl_display_get_fd(m_display);
		m_fds[EventT.wayland].events = POLLIN;
        m_fds[EventT.system].fd = -1; //To do add system interrupts

        m_fds[EventT.key].fd = -1;
        m_fds[EventT.key].events = POLLIN;
    }
}

package:
/** 
 * Базовый класс для всех отображаемых поверхностей
 */

import core.sys.linux.timerfd;
import core.sys.posix.unistd : close, read;

interface SurfaceInterface
{
    void dispose();
}

struct Timer
{
    this(void function() callback)
    {
        cb_emit = callback;
        Display.instance.m_fds[Display.EventT.key].fd = 
            timerfd_create(CLOCK_MONOTONIC,
                           TFD_CLOEXEC | TFD_NONBLOCK);
    }

    ~this()
    {
        int fd = Display.instance.m_fds[Display.EventT.key].fd;
        if (fd >= 0){
            Display.instance.m_fds[Display.EventT.key].fd = -1;
            close(fd);
        }
    }

    void set_time(ref itimerspec tspec) const nothrow
    {
        auto fd = Display.instance.m_fds[Display.EventT.key].fd;
        timerfd_settime(fd, 0, &tspec, null);
    }

private:
    void function() cb_emit;

    void emit(int fd) 
    {
        ulong repeats;
        if (read(fd, &repeats, repeats.sizeof) == 8) {
            for (ulong i = 0; i < repeats; i++)
                cb_emit();
        }
    }
}

private:

/////////////////////////////////////////////////////////////////////////////////////////////////
// Display impl
/////////////////////////////////////////////////////////////////////////////////////////////////

struct GlobalIterator
{
    this(Global[] protocols)
    {
        m_protocols = protocols;
    }

    wl_compositor* compositor;

    bool find_compositor(const char* str) nothrow
    {
        if (!compositor && (strcmp(str, wl_compositor_interface.name) == 0))
            return true;

        return false;
    }

    Global[] m_protocols;
    int index;

    Global find(const(char)* str) nothrow
    {
        for(size_t i = index; i < m_protocols.length; ++i) {
            if (strcmp(str, m_protocols[i].name()) == 0){
                auto res = m_protocols[i];

                if (i != index){
                    m_protocols[i] = m_protocols[index];
                    m_protocols[index] = res;
                }

                ++index;
                return res;
            }
        }

        return null;
    }
}

extern (C) {

    struct wl_registry_listerner
    {
        void function (void* data,
                       wl_proxy* wl_registry,
                       uint name,
                       const(char)* iface,
                       uint ver) global = &handle_global;
  
        void function (void *data,
                       wl_proxy *wl_registry,
                       uint name) global_remove = &handle_global_rem;
    }

    void handle_global(void* data, wl_proxy* registry,
		               uint name, const(char)* iface, uint ver) 
    {
        auto iter = cast(GlobalIterator*) data;

        if (iter.find_compositor(iface))
            iter.compositor =
                cast(wl_compositor*)wl_proxy_marshal_flags(wl_registry,
			        WL_REGISTRY_BIND, &wl_compositor_interface, ver, 0, name, iface, ver, null);

        else
            if (auto item = iter.find(iface))
                item.bind(registry, name, ver);
    }

    void handle_global_rem(void *data, wl_proxy *registry, uint name) 
    {
        //writeln("handle_global_rem");
    }

    //struct wl_display;
    //struct wl_compositor; 
    // wl_display* wl_display_connect(const(char)* name);
    // int wl_display_get_fd(wl_display*);
    // int wl_display_dispatch(wl_display*);
    // int wl_display_dispatch_pending(wl_display*);
    // int wl_display_flush(wl_display*);
    // int wl_display_roundtrip(wl_display*);
    // void wl_display_disconnect(wl_display*);

    // enum uint WL_DISPLAY_SYNC = 0;
    // enum uint WL_DISPLAY_GET_REGISTRY = 1;

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Surface impl
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // struct wl_surface;
    // struct wp_fractional_scale_v1;

    // extern __gshared wl_interface wp_fractional_scale_manager_v1_interface;
}



