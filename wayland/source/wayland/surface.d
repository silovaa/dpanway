module wayland.surface;

import wayland.display;
import wayland.internal.core;
import wayland.sensitive_layer;
import wayland.logger;

import std.exception;
import std.stdio;

interface Scale
{
    void on_scale_changed(float /*factor*/);

    final wl_proxy* initialize(Surface surf) const
    {
        auto manager = ScaleManager.create();
        
        if (!manager.empty()) {
            auto m_fscale =
                wp_fractional_scale_manager_v1_get_fractional_scale(manager.c_ptr,
                                                                    surf.c_ptr);

            if (m_fscale) {
                wp_fractional_scale_v1_add_listener(m_fscale,
                                                    &scale_lsr, cast(void*)this);
                return cast(wl_proxy*)m_fscale;
            }
        }

        return null;
    }

    final void dispose(wl_proxy* ptr)
    {
        Proxy!(wl_proxy, WP_FRACTIONAL_SCALE_V1_DESTROY) self = ptr;
    }
}

class ScaleManager: GlobalProxy!(ScaleManager,
                        wp_fractional_scale_manager_v1,
                        wp_fractional_scale_manager_v1_interface,
                        WP_FRACTIONAL_SCALE_MANAGER_V1_DESTROY)
{
    mixin RegistryProtocols!ScaleManager;
} 

package(wayland):

/** 
 * Базовый класс для всех отображаемых поверхностей
 */
class Surface
{

    final inout(wl_surface*) c_ptr() inout
    {
        return m_native.c_ptr;
    }

    final void commit()
    {
        wl_surface_commit(c_ptr());
    }

protected:
    this()
    {
        m_native = enforce(wl_compositor_create_surface(Display.compositor), 
                            "Can't create surface");

        wl_surface_add_listener(m_native.c_ptr, &surface_lsr, cast(void*)this);

    }

    /** 
     * Конструктор для передачи обработчика ввода если он реализован в отдельном классе не
     * являющемся наследником этого Surface
     * Params:
     *   handler = 
     */
    this(SensitiveLayer handler)
    {
        this();
        input_handler = handler;
    }

    /** 
     * Вызывается при разрушении Display, обеспечивает правильную последовательность
     * освобождения объектов wayland. При переопределении этого метода обязательно
     * передать управление родительскому dispose
     */
    override void dispose()
    {
        writeln("Destroy Surf");
        m_native = null;
    }

package(wayland):

    final SensitiveLayer inputHandler()
    {
        if (input_handler is null)
            input_handler = cast(SensitiveLayer)this;

        return input_handler;
    }

private:
    Proxy!(wl_surface, WL_SURFACE_DESTROY) m_native;
              
    SensitiveLayer input_handler;
}

private:

__gshared wl_surface_listener surface_lsr =
{
    enter: &cb_enter,
    leave: &cb_leave,
    preferred_buffer_scale: &cb_preferred_buffer_scale,
    preferred_buffer_transform: &cb_preferred_buffer_transform
};

__gshared wp_fractional_scale_v1_listener scale_lsr =
{
    preferred_scale: &cb_preferred_scale
};

extern(C) nothrow {

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
                        uint transform){};

void cb_preferred_scale(void* data, wp_fractional_scale_v1 *, 
                        uint scale)
{
    auto surface = cast(Scale)(cast(Surface)data);
    float val = scale / 120.0f;
    
    try{
        surface.on_scale_changed(val);
    }
    catch(Exception e)
        Logger.error("Callback ScaleManager preferred_scale failed: %s", e.msg);
};

}

