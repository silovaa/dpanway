module wayland.internal.core;

public import wayland_import;
import wayland.logger;

package(wayland):

nothrow @nogc struct Proxy (T, int Destroy_code) 
{
    this(T* p) {m_ptr = p;}

    @disable this(this);

    ~this()
    {
        if (m_ptr)
            cast(void) wl_proxy_marshal_flags(cast(wl_proxy*)m_ptr, Destroy_code, null, 
                                   versionNum(), WL_MARSHAL_FLAG_DESTROY);
    }

    uint versionNum() const 
    {
        return m_ptr ? wl_proxy_get_version(cast(wl_proxy*)m_ptr) : 0;
    }

    void opAssign(T* ptr) 
    {
        if (m_ptr != ptr) {
            if (m_ptr)
                cast(void) wl_proxy_marshal_flags(cast(wl_proxy*)m_ptr, Destroy_code, null, 
                                    versionNum(), WL_MARSHAL_FLAG_DESTROY);
            m_ptr = ptr;
        }
    }

    B opCast(B: bool)() const
    {
        return m_ptr !is null;
    }

    inout(T)* c_ptr() inout
    {return m_ptr;}

private:
    T* m_ptr;
}

interface Global
{
    const(char)* name() const nothrow @nogc;
    void bind(wl_registry *reg, uint name, uint vers);
    void dispose();
} 

class GlobalProxy(Self, T, alias wliface, int Destroy_code): Global
{
private: 
    wl_proxy* m_proxy;
    static Self s_instance;

package(wayland):
    import std.stdio;

    static Global create()
    {
        //import std.conv : emplace;
        //To do emplace Self
        
        if (s_instance is null){
            s_instance = new Self;

            writeln("instance create ", Self.stringof);
        }

        return s_instance;
    }

    static Self get()
    {
        if(s_instance is null)
            writeln("instance is null ", Self.stringof);
        return s_instance;
    }

    final inout(T)* c_ptr() inout
    {return cast(T*)m_proxy;}

    final bool empty() const nothrow @nogc @safe
    {
        return m_proxy is null;
    }

protected:
    final override const(char)* name() const nothrow @nogc 
    {
        return wliface.name; 
    }

    override void bind(wl_registry* reg, uint name_id, uint vers)
    {
        m_proxy = cast(wl_proxy*)wl_registry_bind(reg, name_id, &wliface, vers);
    }

    override void dispose() const
    {
        cast(void) wl_proxy_marshal_flags(cast(wl_proxy*)m_proxy, Destroy_code, null, 
                                    wl_proxy_get_version(cast(wl_proxy*)m_proxy),
                                    WL_MARSHAL_FLAG_DESTROY);
    }
}

mixin template RegistryProtocols(T...)
{
    static void registry(out Global[] reg)
    {
        alias Parent = typeof(super);
        static if (__traits(hasMember, Parent, "registry"))
        {
            Parent.registry(reg);
        }

        // 2. Итерация по типам T и вызов их статических методов create
        static foreach (Type; T)
        {
            static if (__traits(hasMember, Type, "create"))
            {
                // Вызываем Type.create() и проверяем, что результат — это Global
                auto g = Type.create();

                static if (is(typeof(g) : Global))
                {
                    reg ~= g;
                }
                else
                {
                    static assert(0,
                     "Type " ~ Type.stringof ~ ".create() должен возвращать Global");
                }
            }
            else
            {
                static assert(0,
                 "Type " ~ Type.stringof ~ " должен иметь статическую функцию create()");
            }
        }
    }
}

extern(C) nothrow @nogc {
    wl_proxy* wl_proxy_marshal_flags(wl_proxy*, uint32_t, wl_interface*,
		       uint32_t, uint32_t, ...);
    uint wl_proxy_get_version(wl_proxy*);
    alias Callback = void function();
    int wl_proxy_add_listener(wl_proxy*, Callback*, void*);
}
