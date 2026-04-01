module wayland.display;

import core.sys.posix.poll;
import core.stdc.errno;
import std.exception;
import std.string;

import wayland.internal.core;
import wayland.logger;
import std.stdio;

/** 
 * Статический класс для одного потока
 */
struct Display
{
public:
    @disable this(this);

    static ref Display connect(const(char)* name = null)
    {
        assert(!native, "Display already initialized");
    
        inst = Display(name);
        return inst;
    }

    void dispose()
    {
        if (native) {
            
            foreach(global; globals){ 
                global.dispose();
            }

            wl_proxy_destroy(cast(wl_proxy*)m_compositor);
            wl_registry_destroy(m_registry);

            wl_display_disconnect(native);
        }
    }

    void event_wait(int time = -1) 
    {
        while (wl_display_prepare_read(native) != 0) {
            if (wl_display_dispatch_pending(native) < 0)
                throw new Exception("failed to dispatch pending Wayland events");
        }

        int ret;

        while ((ret = wl_display_flush(native)) < 0) {
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
            wl_display_cancel_read(native);
            throw new Exception("failed to display flush");
        }

        do {
            ret = poll(m_fds.ptr, EventT.count - 1, time); //To do add system interrupts
        } while (ret < 0 && errno == EINTR);

        if (ret < 0) {
            if (m_fds[EventT.wayland].revents & POLLHUP)
                throw new Exception("disconnected from wayland");

            wl_display_cancel_read(native);
            throw new Exception("failed to poll():");
        }

        if (m_fds[EventT.wayland].revents & POLLIN) {

            if (wl_display_read_events(native) < 0)
                throw new Exception("failed to read Wayland events");
        }
        else
            wl_display_cancel_read(native);

        if (wl_display_dispatch_pending(native) < 0)
            throw new Exception("failed to dispatch pending Wayland events");

        if (m_fds[EventT.key].revents & POLLIN) {
            key_timer.read(m_fds[EventT.key].fd);
        }
    }

    void start()
    {
    
    }

package:
    static wl_display* native;

    static ref Display instance() nothrow @nogc
    {
        assert(native !is null, "wayland display is not initialized");

        return inst;
    }

    static wl_compositor* compositor() nothrow @nogc
    {
        return instance.m_compositor;
    }

    KeyTimer key_timer;

private:
    static Display inst;
    
    wl_registry*   m_registry;  
    wl_compositor* m_compositor;

    pollfd[EventT.count] m_fds;

    LoopTask[] m_task;
    uint m_active_task;

    this(const(char)* name)
    {
        native = enforce(wl_display_connect(name), 
                            "failed to create display");
       
	    m_registry = enforce(wl_display_get_registry(native),
                        "failed to create registry");

        auto iter = GlobalIterator(globals);

        __gshared wl_registry_listener lsr = {
            global: &handle_global,
            global_remove: &handle_global_rem
        };

        enforce(wl_registry_add_listener(m_registry, &lsr, &iter) >= 0,
                "add registry listener failed");

        if (wl_display_roundtrip(native) < 0) 
		    throw new Exception("wl_display_roundtrip() failed");
        
        m_compositor = enforce(iter.compositor, 
		                    "compositor doesn't support wl_compositor");

        globals = iter.protocols;

        m_fds[EventT.wayland].fd = wl_display_get_fd(native);
		m_fds[EventT.wayland].events = POLLIN;
        m_fds[EventT.system].fd = -1; //To do add system interrupts

        m_fds[EventT.key].fd = -1;
        m_fds[EventT.key].events = POLLIN;
    }
}

interface LoopTask
{
    //void activate(ref Display);
    //void deactivate();
    bool isClosed();
    void invoke();   
}

// interface EventLoop
// {
//     void add(LoopTask);
//     void run();
// }

interface RenderBuffer
{
    void setup(ref Display);
    void dispose();

    void makeCurrent(Surface);
    bool isValid();
    void resize(uint, uint);
    void flush();
}

package:

/++ 
 + Базовая поверхность, наследуется TopSurface, ShellSurface, SubSurface.
 + Surface(BUF) - не очень хорошо, инициализировать буфер нужно после
 + протоколов, а протоколы в дочернем классе
 +/
class Surface: LoopTask
{
    final bool isClosed()
    { return m_native is null;}

    final void refresh()
    {
        if (m_farame) {
            wl_callback_destroy(m_farame);
        }
        
        // Создаем новый
        m_farame = wl_surface_frame(c_ptr);
        wl_callback_add_listener(m_farame, &frame_lsr, cast(void*)this);
        
        // Сбрасываем флаг готовности
        //need_redraw = false;
    }

protected:
    this()
    {
        auto ref dpy = Display.instance;
        m_native = enforce(wl_compositor_create_surface(dpy.compositor), 
                            "Can't create surface");

        wl_surface_add_listener(m_native, &surface_lsr, null);

        dpy.m_task ~= this;
        dpy.m_active_task++;
    }

    final void commit()
    {
        wl_surface_commit(c_ptr);
    }

    abstract void draw();

package:
    final inout(wl_surface*) c_ptr() inout
    {
        return m_native;
    }
    
    // final void setup(ref Display dpy)
    // {
    //     m_native = enforce(wl_compositor_create_surface(dpy.compositor), 
    //                         "Can't create surface");

    //     wl_surface_add_listener(m_native, &surface_lsr, null);

    //     assert(m_buffer);
    //     m_buffer.setup(dpy, this);
    // }

    final void dispose()
    {
        if (m_native){
            if (m_frame) {
                wl_callback_destroy(m_frame);
            }

            wl_surface_destroy(m_native);
            m_native = null;
            Display.instance.m_active_task--;
        }
    }

private:
    wl_surface* m_native;
    wl_callback* m_frame;
    bool need_redraw;

    override void invoke()
    {
        if (need_redraw) {
            need_redraw = false;
            draw();
        }
    }
}

import core.sys.linux.timerfd;
import core.sys.posix.unistd : close, read;

 enum EventT {
    system, wayland, key, count
}

struct Timer
{
    void attach(void delegate() func)
    {
        assert(Display.instance.m_fds[EventT.key].fd >= 0);

        emit = func;
        Display.instance.m_fds[EventT.key].fd = 
            timerfd_create(CLOCK_MONOTONIC,
                           TFD_CLOEXEC | TFD_NONBLOCK);
    }

    void detach()
    {
        int fd = Display.instance.m_fds[EventT.key].fd;
        if (fd >= 0){
            Display.instance.m_fds[EventT.key].fd = -1;
            close(fd);
        }
    }

    void set_time(ref itimerspec tspec) nothrow @nogc
    {
        auto fd = Display.instance.m_fds[EventT.key].fd;
        timerfd_settime(fd, 0, &tspec, null);
    }

private:
    void delegate() emit;

    void read(int fd) 
    {
        ulong repeats;
        if (read(fd, &repeats, repeats.sizeof) == 8) {
            for (ulong i = 0; i < repeats; i++)
                emit();
        }
    }
}

private:
/////////////////////////////////////////////////////////////////////////////////////////////////
// Display impl
/////////////////////////////////////////////////////////////////////////////////////////////////

import core.stdc.string : strcmp;

struct GlobalIterator
{
    this(Global[] protocols)
    {
        m_protocols = protocols;
    }

    wl_compositor* compositor;

    bool find_compositor(const char* str) nothrow @nogc
    {
        if (!compositor && (strcmp(str, wl_compositor_interface.name) == 0))
            return true;

        return false;
    }

    Global[] m_protocols;
    uint index;

    Global find(const(char)* str) nothrow @nogc
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

    Global[] protocols()  
    {
        if (index == 0){
            foreach (prot; m_protocols)
                Logger.info("the %s protocol is not supported by the composer.", 
                            prot.name);
            return null;
        }

        auto i = index + 1;
        if (i < m_protocols.length){
            foreach (prot; m_protocols[i..$])
                Logger.info("the %s protocol is not supported by the composer.", 
                            prot.name);
            return m_protocols[0..i];
        }

        return m_protocols;
    }
}

extern (C) nothrow {
    void handle_global(void* data, wl_registry* registry,
                        uint name, const(char)* iface, uint ver) 
    {
        try{
            auto iter = cast(GlobalIterator*) data;

            if (iter.find_compositor(iface))
                iter.compositor =
                    cast(wl_compositor*)wl_registry_bind(registry, name, 
                                                        &wl_compositor_interface, ver);

            else
                if (auto item = iter.find(iface))
                    item.bind(registry, name, ver);
        }
        catch(Exception)
            Logger.error("fatal error in registry bind");
    }

    void handle_global_rem(void *data, wl_registry *registry, uint name) 
    {
        //writeln("handle_global_rem");
    }
}

/////////////////////////////////////////////////////////////////////////////////////////////////
// Surface impl
/////////////////////////////////////////////////////////////////////////////////////////////////

__gshared wl_surface_listener surface_lsr =
{
    enter: &cb_enter,
    leave: &cb_leave,
    preferred_buffer_scale: &cb_preferred_buffer_scale,
    preferred_buffer_transform: &cb_preferred_buffer_transform
};

__gshared wl_callback_listener frame_lsr =
{
    &cb_frame
};

extern(C) nothrow {
    void cb_frame(void* data, wl_callback* callback, uint)
    {
        auto surf = cast(Surface) data;

        wl_callback_destroy(callback);
        surf.m_farame = null;

        surf.need_redraw = true;
    }

    void cb_enter(void* data, wl_surface* s, wl_output* o) 
    {
                    // Пусто
    }

    void cb_leave(void *data, wl_surface *wl_surface,
                wl_output *output){}

    void cb_preferred_buffer_scale(void *data,
                            wl_surface *wl_surface,
                            int factor){}

    void cb_preferred_buffer_transform(void *data,
                            wl_surface *wl_surface,
                            uint transform){}
}



