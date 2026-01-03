module wayland.xdg_shell_protocol;

import wayland.internal.core;
import wayland.surface;
import wayland.sensitive_layer;

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
    this(uint width, uint height)
    {
        construct(width, height);
    }

    this(SensitiveLayer input, uint width, uint heigh)
    {
        super(input);
        construct(width, height);
    }

    final void setTitle(const (char)* title)
    {xdg_toplevel_set_title(m_top.c_ptr(), title);}

    final void setAppID(const (char)* id)
    {xdg_toplevel_set_app_id(m_top.c_ptr(), id);}

    // final inout(xdg_toplevel)* c_ptr() inout
    // {return m_top.c_ptr();}

package(wayland):
    mixin RegistryProtocols!XDGWmBase;

private:
    Proxy!(xdg_surface,  XDG_SURFACE_DESTROY)  m_xdg_surfase;
    Proxy!(xdg_toplevel, XDG_TOPLEVEL_DESTROY) m_top;

    void construct(uint width, uint height)
    {
        auto xdg_base = XDGWmBase.get();
        if (!xdg_base.empty()){
            m_xdg_surfase = xdg_wm_base_get_xdg_surface(xdg_base.c_ptr, c_ptr);
            enforce(m_xdg_surfase, "Can't create xdg surface");
                
            m_top = xdg_surface_get_toplevel(m_xdg_surfase.c_ptr);
            enforce(m_top,"Can't create toplevel role");

            static immutable XdgToplevelListener toplevel_lsr;
            xdg_toplevel_add_listener(m_top.c_ptr(), 
                                    cast(Callback*) &toplevel_lsr, this);

            static immutable XdgSurfaceListener surface_lsr;
            xdg_surface_add_listener (m_xdg_surfase.c_ptr(), 
                                    cast(Callback*) &surface_lsr, this);
        }

        m_width  = width;
        m_height = height;
    }

protected:
    uint32_t m_width ;
    uint32_t m_height;
    uint32_t m_state ;

    abstract void closed();

    /**
     * configure called by the composer when the state (s) 
     * and/or window dimensions (w, h) change 
     */
    abstract void configure(uint w, uint h, uint s);
}

private:

final class XDGWmBase: Global
{
    mixin GlobalProxy!(XDGWmBase, xdg_wm_base, xdg_wm_base_interface, XDG_WM_BASE_DESTROY);
    
    override void bind(wl_registry *reg, uint name, uint vers) nothrow
    {
        set(reg, name, vers);

        static immutable XdgWmBaseListener listener;
        xdg_wm_base_add_listener (c_ptr(), &listener, null);
    }
}

extern (C) nothrow {

struct XdgWmBaseListener {
    auto ping = (void*, xdg_wm_base *wm_base, uint serial){
        xdg_wm_base_pong(wm_base, serial);
    };
}

struct XdgToplevelListener {
    auto configure = (void* data, xdg_toplevel *tt,
                    int width, int height, wl_array* states){

        auto inst = cast(XDGTopLevel)data;
        inst.m_state = 0;

        uint32_t[] statesSlice = 
            (cast(uint32_t*) states.data)[0 .. states.size / uint32_t.sizeof];

        foreach (state; statesSlice) {
             inst.m_state |= (1 << state);
        }

        if (width && height){
            inst.m_width  = width;
            inst.m_height = height;
        }
    };
    auto close = (void *data, xdg_toplevel*){
        auto inst = cast(XDGTopLevel)data;
        inst.closed();
    };
    auto configure_bounds = (void* data, xdg_toplevel*, int32_t width, int32_t height){

    };
    auto wm_capabilities = (void *data, xdg_toplevel *xdg_toplevel,
                                wl_array *capabilities){
    };
}

struct XdgSurfaceListener {
    auto configure = (void* data, xdg_surface *xdg_surf, uint32_t serial){

        auto inst = cast(XDGTopLevel)data;
        xdg_surface_ack_configure(xdg_surf, serial);

        inst.configure(inst.m_width, inst.m_height, inst.m_state);
    };
}

}

