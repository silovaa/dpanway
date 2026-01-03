module wayland.internal.core;

import core.stdc.string : strcmp;
public import wayland_import;

package(wayland):

// immutable class WlInterface
// {
//     private wl_interface* m_native;

//     this(immutable wl_interface* native)
//     {
//         m_native = native;
//     }

//     @property immutable(wl_interface)* native() nothrow
//     {
//         return m_native;
//     }

//     @property string name() nothrow
//     {
//         import std.string : fromStringz;
//         return fromStringz(m_native.name);
//     }

//     bool isSame(const(char*) str) nothrow
//     {
//         return strcmp(m_native.name, str) == 0;
//     }
// }

// bool wlIfaceEquals(immutable(WlInterface) a, immutable(WlInterface) b)
// {
//     return a is b || strcmp(a.m_native.name, b.m_native.name) == 0;
// }

struct Proxy (T, int Destroy_code) 
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

    T opCast(T : bool)() const 
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
    const(char)* name() const nothrow;
    void bind(wl_proxy *reg, uint name, uint vers) nothrow;
    void dispose();
} 

mixin template GlobalProxy(Self, T, alias wliface, int Destroy_code)
{
private: 
    Proxy!(T, Destroy_code) m_proxy;
    
    static ubyte[__traits(classInstanceSize, Self)] s_storage;

    static Self instance;

    void set(wl_proxy* reg, uint name_id, uint vers) nothrow
    {
        m_proxy = cast(T*)wl_proxy_marshal_flags(reg,
			 WL_REGISTRY_BIND, wliface, vers, 0, name_id, name(), vers, null);
    }

public:
    
    static Global create()
    {
        import std.conv : emplace;

        if (instance is null)
            instance = emplace!(Self)(s_storage[]);

        return get();
    }

    static Self get()
    {
        assert(instance !is null);
        return instance;
    }

    final inout(T)* c_ptr() inout
    {return m_proxy.c_ptr;}

    final bool empty() const nothrow
    {
        return m_proxy.c_ptr is null;
    }

    final override const(char)* name() const nothrow
    {
        return wliface.name; 
    }

    override void bind(wl_proxy* reg, uint name_id, uint vers) nothrow
    {
        set(reg, name_id, vers);
    }

    override void dispose()
    {
        m_proxy = null;
    }
}

mixin template RegistryProtocols(T...)
{
    static void registry(Global[] reg)
    {
        alias CurrentClass = typeof(this);
        
        // 1. Проверка и рекурсивный вызов родителя
        alias BaseTypes = __traits(getUnitaryBaseClasses, CurrentClass);
        static if (BaseTypes.length > 0)
        {
            alias Parent = BaseTypes[0];
            static if (__traits(hasMember, Parent, "registry"))
            {
                Parent.registry(reg);
            }
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
                    static assert(0, "Type " ~ Type.stringof ~ ".create() должен возвращать Global");
                }
            }
            else
            {
                static assert(0, "Type " ~ Type.stringof ~ " должен иметь статическую функцию create()");
            }
        }
    }
}