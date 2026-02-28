module wayland.surface;

import wayland.display;
import wayland.internal.core;
import wayland.logger;

import std.exception;
import std.stdio;

struct Protocols(T...) 
{
    T data; 

    static foreach (size_t i, Type; T) {
        // Вклеиваем методы, передавая им ссылку на конкретное поле из кортежа data
        // Каждый протокол должен иметь template Iface(alias ctx) {набор методов}
        mixin Type.Iface!(data[i]);
    }
}

struct ProtocolStore(T) {
    Surface surface;

    T protocols;
    alias protocols this;
    
    // получение ссылки на протокол по его ТИПУ
    // Использование: auto p = store.get!ScaleFactor;
    auto ref get(Proto)() {
        // Ищем имя поля, тип которого совпадает с Proto
        enum fieldName = () {
            foreach (name; __traits(allMembers, T)) {
                // Используем тип T напрямую, чтобы избежать проблем с контекстом экземпляра
                if (is(typeof(__traits(getMember, T, name)) == Proto)) {
                    return name;
                }
            }
            return null;
        }();

        static if (fieldName !is null) {
            return __traits(getMember, protocols, fieldName);
        } else {
            static assert(0, "Протокол " ~ Proto.stringof ~ " не найден в " ~ T.stringof);
        }
    }

    void setupAll() 
    {
        surface.setup();

        static foreach (memberName; __traits(allMembers, T)) {
            {
                // Используем компилируемую проверку, чтобы не упасть на полях без setup
                static if (__traits(hasMember, typeof(__traits(getMember, protocols, memberName)), "setup")) {
                    __traits(getMember, protocols, memberName).setup(this);
                }
            }
        }
    }

    // Освобождение в обратном порядке (ВАЖНО для Wayland)
    void dispose() 
    {
        // static foreach_reverse — лучший способ для 2026 года
        static foreach_reverse (memberName; __traits(allMembers, T)) {
            {
                static if (__traits(hasMember, typeof(__traits(getMember, protocols, memberName)), "dispose")) {
                    __traits(getMember, protocols, memberName).dispose();
                }
            }
        }

        surface.dispose();
    }
}

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
    template Iface(alias ctx) {
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

package(wayland):


struct Surface
{
    inout(wl_surface*) c_ptr() inout
    {
        return m_native;
    }

    void commit()
    {
        wl_surface_commit(c_ptr());
    }

    void setup()
    {
        m_native = enforce(wl_compositor_create_surface(Display.compositor), 
                            "Can't create surface");

        wl_surface_add_listener(m_native, &surface_lsr, null);
    }

    void dispose()
    {
        wl_surface_destroy(m_native);
    }

private:
    wl_surface* m_native;
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

