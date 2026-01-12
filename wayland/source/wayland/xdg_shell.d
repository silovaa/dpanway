module wayland.xdg_shell;

import wayland.internal.core;
import wayland.surface;
import wayland.sensitive_layer;
import wayland.logger;

import std.exception;

enum XDGState
{
    resizing  = 1 << XDG_TOPLEVEL_STATE_RESIZING,
    maximized = 1 << XDG_TOPLEVEL_STATE_MAXIMIZED,
    activated = 1 << XDG_TOPLEVEL_STATE_ACTIVATED,
    fullscreen = 1 << XDG_TOPLEVEL_STATE_FULLSCREEN
}

class XDGTopLevel: Surface
{
public:
    this()
    {
        construct();
    }

    this(SensitiveLayer input)
    {
        super(input);
        construct();
    }

    final void setTitle(const(char)* title)
    {xdg_toplevel_set_title(m_top.c_ptr(), title);}

    final void setAppID(const(char)* id)
    {xdg_toplevel_set_app_id(m_top.c_ptr(), id);}

    // final inout(xdg_toplevel)* c_ptr() inout
    // {return m_top.c_ptr();}

package(wayland):
    mixin RegistryProtocols!XDGWmBase;

private:
    Proxy!(xdg_surface,  XDG_SURFACE_DESTROY)  m_xdg_surfase;
    Proxy!(xdg_toplevel, XDG_TOPLEVEL_DESTROY) m_top;

    void construct()
    {
        auto xdg_base = XDGWmBase.get();

        if (!xdg_base.empty()){
            m_xdg_surfase = enforce(xdg_wm_base_get_xdg_surface(xdg_base.c_ptr, c_ptr),
                                    "Can't create xdg surface");
                
            m_top = enforce(xdg_surface_get_toplevel(m_xdg_surfase.c_ptr),
                            "Can't create toplevel role");

            __gshared xdg_toplevel_listener toplevel_lsr = {
                configure: &cb_configure,
                close    : &cb_close,
                configure_bounds: &cb_configure_bounds,
                wm_capabilities : &cb_wm_capabilities
            };
            xdg_toplevel_add_listener(m_top.c_ptr(), &toplevel_lsr, cast(void*)this);

            __gshared xdg_surface_listener surface_lsr = {
                configure: &cb_xdgconfigure
            };
            xdg_surface_add_listener (m_xdg_surfase.c_ptr(), 
                                      &surface_lsr,cast(void*) this);
            
            commit();
        }
    }

protected:

    abstract void closed();

    /**
     * configure called by the composer when the state (s) 
     * and/or window dimensions (w, h) change 
     */
    abstract void configure(uint w, uint h, uint s);

    bool askConfigure() 
    {
        return true;
    }
}

template TopLevel(Protocols...) {
    static if (Protocols.length == 0) {
        // Без декораторов
        class WithProtocols : XDGTopLevel {
            this() {
                super();
            }
        }
    } else {
        // Применяем декораторы
        alias FirstProtocol = Protocols[0];
        alias RestProtocols = Protocols[1..$];
        alias InnerType = WithProtocols!(RestProtocols);
        
        class WithProtocols : FirstProtocol!(InnerType) {
            this() {
                auto inner = new InnerType();
                super(inner);
            }
        }
    }
}

enum DecorMode {
    ServerSide = ZXDG_TOPLEVEL_DECORATION_V1_MODE_SERVER_SIDE
}

class DecoratedXDGTopLevel: XDGTopLevel
{
    this()
    {
        super();
        auto manager = XDGDecorationManager.get;
        if (!manager.empty())
            m_decor = zxdg_decoration_manager_v1_get_toplevel_decoration(manager.c_ptr,
                                                                        m_top.c_ptr);
        decorMode(DecorMode.ServerSide);
    }

    this(SensitiveLayer input)
    {
        super(input, width, heigh);
        auto manager = XDGDecorationManager.get;
        if (!manager.empty())
            m_decor = zxdg_decoration_manager_v1_get_toplevel_decoration(manager.c_ptr,
                                                                        m_top.c_ptr);
        decorMode(DecorMode.ServerSide);
    }

    final void decorMode(DecorMode mode)
    {
        zxdg_toplevel_decoration_v1_set_mode(m_decor.c_ptr, mode);
    }

package(wayland):
    mixin RegistryProtocols!XDGDecorationManager;

private:
    Proxy!(zxdg_toplevel_decoration_v1, 
           ZXDG_TOPLEVEL_DECORATION_V1_DESTROY) m_decor;
}



private:

final class XDGWmBase: GlobalProxy!(XDGWmBase, xdg_wm_base, xdg_wm_base_interface, XDG_WM_BASE_DESTROY)
{   
    override void bind(wl_registry *reg, uint name, uint vers)
    {
        super.bind(reg, name, vers);

        __gshared xdg_wm_base_listener listener = {
            ping: &cb_ping
        };

        xdg_wm_base_add_listener (c_ptr(), &listener, null);
    }
}

final class XDGDecorationManager: GlobalProxy!(XDGDecorationManager, 
                                            zxdg_decoration_manager_v1, 
                                            zxdg_decoration_manager_v1_interface, 
                                            ZXDG_DECORATION_MANAGER_V1_DESTROY)
{}

extern (C) nothrow {

void cb_ping(void*, xdg_wm_base *wm_base, uint serial)
{
    try{
        xdg_wm_base_pong(wm_base, serial);
    }
    catch(Exception e)
        Logger.error("Callback XDGWmBase ping failed: %s", e.msg);
}

void cb_configure(void* data, xdg_toplevel *tt,
                    int width, int height, wl_array* states)
{
    try{
        auto inst = cast(XDGTopLevel)data;
        uint state_res;

        uint32_t[] statesSlice = 
            (cast(uint32_t*) states.data)[0 .. states.size / uint32_t.sizeof];

        foreach (state; statesSlice) {
            state_res |= (1 << state);
        }

        inst.configure(width, height, state_res);
    }
        catch(Exception e)
            Logger.error("Callback XDGTopLevel configure failed: %s", e.msg);
}

void cb_close(void *data, xdg_toplevel*)
{
    auto inst = cast(XDGTopLevel)data;
    try{
        inst.closed();
    }
    catch(Exception e)
        Logger.error("Callback XDGTopLevel close failed: %s", e.msg);
}

void cb_configure_bounds(void* data, xdg_toplevel*, int32_t width, int32_t height)
{}

void cb_wm_capabilities(void *data, xdg_toplevel *xdg_toplevel,
                            wl_array *capabilities)
{}

void cb_xdgconfigure(void* data, xdg_surface *xdg_surf, uint32_t serial)
{
    auto inst = cast(XDGTopLevel)data;

    try{
        if (inst.askConfigure)
            xdg_surface_ack_configure(xdg_surf, serial);
    }
    catch(Exception e)
        Logger.error("Callback XDGTopLevel configure failed: %s", e.msg);
}

}

