module wayland.surface;

import wayland.display;
import wayland.internal.core;
import wayland.logger;

import std.exception;
import std.stdio;

// struct ProtocolStore(T) {
//     Surface surface;

//     T protocols;
//     alias protocols this;
    
//     // получение ссылки на протокол по его ТИПУ
//     // Использование: auto p = store.get!ScaleFactor;
//     auto ref get(Proto)() {
//         // Ищем имя поля, тип которого совпадает с Proto
//         enum fieldName = () {
//             foreach (name; __traits(allMembers, T)) {
//                 // Используем тип T напрямую, чтобы избежать проблем с контекстом экземпляра
//                 if (is(typeof(__traits(getMember, T, name)) == Proto)) {
//                     return name;
//                 }
//             }
//             return null;
//         }();

//         static if (fieldName !is null) {
//             return __traits(getMember, protocols, fieldName);
//         } else {
//             static assert(0, "Протокол " ~ Proto.stringof ~ " не найден в " ~ T.stringof);
//         }
//     }

//     void setupAll() 
//     {
//         surface.setup();

//         static foreach (memberName; __traits(allMembers, T)) {
//             {
//                 // Используем компилируемую проверку, чтобы не упасть на полях без setup
//                 static if (__traits(hasMember, typeof(__traits(getMember, protocols, memberName)), "setup")) {
//                     __traits(getMember, protocols, memberName).setup(this);
//                 }
//             }
//         }
//     }

//     // Освобождение в обратном порядке (ВАЖНО для Wayland)
//     void dispose() 
//     {
//         // static foreach_reverse — лучший способ для 2026 года
//         static foreach_reverse (memberName; __traits(allMembers, T)) {
//             {
//                 static if (__traits(hasMember, typeof(__traits(getMember, protocols, memberName)), "dispose")) {
//                     __traits(getMember, protocols, memberName).dispose();
//                 }
//             }
//         }

//         surface.dispose();
//     }
// }

struct ScaleFactor
{
private:
    alias ScaleManager = GlobalProxy!(wp_fractional_scale_manager_v1,
                                    wp_fractional_scale_manager_v1_interface,
                                    WP_FRACTIONAL_SCALE_MANAGER_V1_DESTROY);
    
    wp_fractional_scale_v1* m_fscale;

    mixin GlobalFactory!ScaleManager;

    void delegate(float /*factor*/) cbScaleChanged;

public:
    template Iface(alias ctx) 
    {
        @property void onScaleChanged(void delegate(float /*factor*/) cb)
        {
            ctx.cbScaleChanged = cb;
        }
    }

package(wayland):
    void setup(Surface surface) 
    {
        if (globalValid()) 
        {
            m_fscale = wp_fractional_scale_manager_v1_get_fractional_scale(
                m_global.c_ptr, 
                surface.c_ptr
            );

            if (m_fscale) 
                wp_fractional_scale_v1_add_listener(
                    m_fscale, 
                    &scale_lsr, 
                    cast(void*)&this
                ); 
        }
    }

    void dispose()
    {
        if (m_fscale) {
            wp_fractional_scale_v1_destroy(m_fscale);
            m_fscale = null;
        }
    }
}

package:

/++ 
 + Базовая поверхность, наследуется TopSurface, ShellSurface, SubSurface.
 +/
class Surface
{
protected:
    this(RenderBuffer buf)
    {
        m_buffer = buf;
    }

    final inout(wl_surface*) c_ptr() inout
    {
        return m_native;
    }

    final void commit()
    {
        wl_surface_commit(c_ptr);
    }

    final void refresh()
    {
        if (m_farame) {
            wl_callback_destroy(m_farame);
        }
        
        // Создаем новый
        m_farame = wl_surface_frame(c_ptr);
        wl_callback_add_listener(m_farame, &frame_lsr, cast(void*)this);
        
        // Сбрасываем флаг готовности
        need_redraw = false;
    }

    abstract void draw();

package:
    protected void setup(ref Display dpy)
    {
        assert(m_buffer);
        m_buffer.setup(dpy);

        m_native = enforce(wl_compositor_create_surface(dpy.compositor), 
                            "Can't create surface");

        wl_surface_add_listener(m_native, &surface_lsr, null);
    }

    protected void dispose()
    {
        m_buffer.dispose();
        wl_surface_destroy(m_native);
    }

    final void drawProcess()
    {
        if (need_redraw) {
            draw();
            need_redraw = false;
        }
    }

    RenderBuffer m_buffer;

private:
    wl_surface* m_native;
    wl_callback* m_farame;
    bool need_redraw;
}

interface RenderBuffer
{
    void setup(in Display);
    void dispose();

    void makeCurrent(Surface);
    bool isValid();
    void resize(uint, uint);
    void flush();
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

void cb_preferred_scale(void* data, wp_fractional_scale_v1 *, 
                        uint scale)
{
    auto sf = cast(ScaleFactor*)data;
    float val = scale / 120.0f;
    
    try{
        if (sf.cbScaleChanged)
            sf.cbScaleChanged(val);
    }
    catch(Exception e)
        Logger.error("Callback ScaleManager preferred_scale failed: %s", e.msg);
}

}

