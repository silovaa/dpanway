module wayland.surface;

import wayland.display;
import wayland.internal.core;
import wayland.sensitive_layer;

package(wayland):

class Surface: SurfaceInterface
{
    ~this()
    {
        if (m_native) {
            Display.instance.m_window_pool.remove(m_native.c_ptr);
        }
    }

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

        wl_surface_add_listener(m_native.c_ptr, &surface_lsr, this);

        auto manager = ScaleManager.get();
        if (!manager.empty()) {
            m_fscale = wp_fractional_scale_manager_v1_get_fractional_scale(manager.c_ptr, m_native.c_ptr);

            if (m_fscale) 
                wp_fractional_scale_v1_add_listener(m_fscale.c_ptr, &scale_lsr, this);
        }

        Display.instance.m_window_pool[m_native.c_ptr] = this;
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
        m_fscale = null;
        m_native = null;
    }

    abstract void on_scale_changed(float /*factor*/);

package(wayland):
    mixin RegistryProtocols!ScaleManager;

    final SensitiveLayer inputHandler()
    {
        if (input_handler is null)
            input_handler = cast(SensitiveLayer)this;

        return input_handler;
    }

private:
    Proxy!(wl_surface, WL_SUBSURFACE_DESTROY) m_native;
    Proxy!(wp_fractional_scale_v1,
              WP_FRACTIONAL_SCALE_V1_DESTROY) m_fscale;
              
    SensitiveLayer input_handler;
     
    static immutable(WpFractionalScaleV1Listener) scale_lsr;
    static immutable(WlSurfaceListener)  surface_lsr;
}

private:

class ScaleManager: Global
{ 
    mixin GlobalProxy!(ScaleManager,
                        wp_fractional_scale_manager_v1,
                        wp_fractional_scale_manager_v1_interface,
                        WP_FRACTIONAL_SCALE_MANAGER_V1_DESTROY);
}

extern(C){
    struct WlSurfaceListener
    {
        auto enter = (void* data, wl_surface* s, wl_output* o) {
                // Пусто
        };

        auto leave = (void *data,
                        wl_surface *wl_surface,
                        wl_output *output){};

        auto preferred_buffer_scale = (void *data,
                        wl_surface *wl_surface,
                        int factor){};

        auto preferred_buffer_transform = (void *data,
                        wl_surface *wl_surface,
                        uint transform){};
    }

    struct WpFractionalScaleV1Listener 
    {
        auto preferred_scale = (void* data, wp_fractional_scale_v1 *, 
                        uint scale){
            auto surface = cast(Surface) data;
            float val = scale / 120;

            surface.on_scale_changed(val);
        };
    }
}

