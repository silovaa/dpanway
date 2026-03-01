module wayland.xdg_shell;

import wayland.internal.core;
import wayland.surface;
import wayland.logger;
import wayland.display: Display;

import std.exception;

enum XDGState
{
    resizing            = 1 << XDG_TOPLEVEL_STATE_RESIZING,
    maximized           = 1 << XDG_TOPLEVEL_STATE_MAXIMIZED,
    activated           = 1 << XDG_TOPLEVEL_STATE_ACTIVATED,
    fullscreen          = 1 << XDG_TOPLEVEL_STATE_FULLSCREEN,
    tiled_left          = 1 << XDG_TOPLEVEL_STATE_TILED_LEFT,
    tiled_right         = 1 << XDG_TOPLEVEL_STATE_TILED_LEFT,
    tiled_top           = 1 << XDG_TOPLEVEL_STATE_TILED_TOP,
    tilled_bottom       = 1 << XDG_TOPLEVEL_STATE_TILED_BOTTOM,
    suspend             = 1 << XDG_TOPLEVEL_STATE_SUSPENDED,
    constrained_left    = 1 << XDG_TOPLEVEL_STATE_CONSTRAINED_LEFT,
    constrained_right   = 1 << XDG_TOPLEVEL_STATE_CONSTRAINED_RIGHT,
    constrained_top     = 1 << XDG_TOPLEVEL_STATE_CONSTRAINED_TOP,
    constrained_bottom  = 1 << XDG_TOPLEVEL_STATE_CONSTRAINED_BOTTOM
}

class XDGTopLevel: Surface
{
    this(RenderBuffer buf, uint w, uint h)
    {
        super(buf);
        m_width = w; 
        m_height = h;
    }

    final void setTitle(const(char)* title)
    {xdg_toplevel_set_title(m_toplevel, title);}

    final void setAppID(const(char)* id)
    {xdg_toplevel_set_app_id(m_toplevel, id);}

package:
    //Инициализация поверхностей
    //выполняем перед инициализацией протоколов
    override void setup(ref Display dpy)
    {
        if (globalValid() && m_buffer !is null){
            super.setup(dpy);
            
            m_xdg_surfase = enforce(xdg_wm_base_get_xdg_surface(m_global.c_ptr, 
                                                                c_ptr),
                                    "Can't create xdg surface");
                
            m_toplevel = enforce(xdg_surface_get_toplevel(m_xdg_surfase),
                            "Can't create toplevel role");

            __gshared xdg_toplevel_listener toplevel_lsr = {
                configure: &cb_configure,
                close    : &cb_close,
                configure_bounds: &cb_configure_bounds,
                wm_capabilities : &cb_wm_capabilities
            };
            xdg_toplevel_add_listener(m_toplevel, &toplevel_lsr, cast(void*)this);

            __gshared xdg_surface_listener surface_lsr = {
                configure: &cb_xdgconfigure
            };
            xdg_surface_add_listener (m_xdg_surfase, 
                                      &surface_lsr,cast(void*)this);
            
            commit();
        }
    } 

    override void dispose()
    {
        if (m_toplevel) {
            xdg_toplevel_destroy(m_toplevel);
            xdg_surface_destroy(m_xdg_surfase);
        }

        super.dispose();
    }

    mixin GlobalFactory!XDGWmBase;

protected:
    /** 
     * Вызывается после изменения размера буфера рисования
     * перед запросом кадра 
     */
    void configure(uint width, uint height, uint state){}

    /** 
     * Вызывается перед уничтожением всех ресурсов окна
     */
    void closed(){}

    uint m_width, m_height;

private:
    xdg_surface*  m_xdg_surfase;
    xdg_toplevel* m_toplevel;
}

enum DecorMode {
    ServerSide = ZXDG_TOPLEVEL_DECORATION_V1_MODE_SERVER_SIDE
}

struct XDGDecorated
{
    template Iface(alias ctx) 
    {
        void decorMode(DecorMode mode)
        {
            zxdg_toplevel_decoration_v1_set_mode(ctx.m_decor, mode);
        }
    }

package(wayland):
    void setup(XDGTopLevel prot) 
    {
        if (globalValid()){
           
            m_decor = zxdg_decoration_manager_v1_get_toplevel_decoration(
                m_global.c_ptr,
                prot.m_toplevel);

            zxdg_toplevel_decoration_v1_set_mode(m_decor, DecorMode.ServerSide);
        }
    }

    void dispose()
    {
        if (m_decor !is null){
            zxdg_toplevel_decoration_v1_destroy(m_decor);
            m_decor = null;
        }
    }

    mixin GlobalFactory!XDGDecorationManager;

private:
    zxdg_toplevel_decoration_v1* m_decor;
}

private:

final class XDGWmBase: GlobalProxy!(xdg_wm_base, xdg_wm_base_interface, XDG_WM_BASE_DESTROY)
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

alias XDGDecorationManager = GlobalProxy!(zxdg_decoration_manager_v1, 
                                        zxdg_decoration_manager_v1_interface, 
                                        ZXDG_DECORATION_MANAGER_V1_DESTROY);

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

        if (inst.onConfigure) inst.onConfigure(width, height, state_res);
    }
        catch(Exception e)
            Logger.error("Callback XDGTopLevel configure failed: %s", e.msg);
}

void cb_close(void *data, xdg_toplevel*)
{
    auto inst = cast(XDGTopLevel*)data;
    try{
        if(inst.onClosed) inst.onClosed();
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
    auto inst = cast(XDGTopLevel*)data;

    try{
        xdg_surface_ack_configure(xdg_surf, serial);
        if(inst.onAskConfigure) inst.onAskConfigure();
    }
    catch(Exception e)
        Logger.error("Callback XDGTopLevel configure failed: %s", e.msg);
}

}

