module wayland.internal.core;

public import wayland_import;
import wayland.logger;
import std.stdio;

package(wayland):

interface Global
{
    const(char)* name() const nothrow @nogc;
    void bind(wl_registry *reg, uint name, uint vers);
    void dispose();
} 

class GlobalProxy(T, alias wliface, int Destroy_code): Global
{
    final override const(char)* name() const nothrow @nogc 
    {
        return wliface.name; 
    }

    override void bind(wl_registry* reg, uint name_id, uint vers)
    {   
        m_proxy = cast(wl_proxy*)wl_registry_bind(reg, name_id, &wliface, vers);
    }

    override void dispose()
    {
        if (m_proxy){
            debug writeln("Destroy global", name);
            cast(void) wl_proxy_marshal_flags(m_proxy, Destroy_code, null, 
                                    wl_proxy_get_version(m_proxy),
                                    WL_MARSHAL_FLAG_DESTROY);
        
            m_proxy = null;
        }
    }

private: 
    wl_proxy* m_proxy = null;

package(wayland):

    final bool empty() const nothrow @nogc @safe
    {
        return m_proxy is null;
    }

    final inout(T)* c_ptr() inout
    {return cast(T*)m_proxy;}
}

mixin template GlobalFactory(GlobalClass) {
    private static GlobalClass m_global;

    private bool globalValid() const
    {
        assert(m_global !is null, "global not created");

        if (m_global.empty()){
            Logger.info("Protokol %s not supported", m_global.name);
            return false;
        }

        return true;
    }

    package(wayland)
        // Статическая функция создания
        static Global create() 
        {
            if (m_global is null) {
                m_global = new GlobalClass();
            }
            return m_global;
        }

        static GlobalClass get() nothrow @nogc
        {
            assert(m_global !is null, "global not created");

            return m_global;
        }
}

extern(C) nothrow @nogc {
    wl_proxy* wl_proxy_marshal_flags(wl_proxy*, uint32_t, wl_interface*,
		       uint32_t, uint32_t, ...);
    uint wl_proxy_get_version(wl_proxy*);
    alias Callback = void function();
    int wl_proxy_add_listener(wl_proxy*, Callback*, void*);
    void wl_callback_destroy(wl_callback*);
}
