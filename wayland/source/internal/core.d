module wayland.internal.core;

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
    const(char)* name() const nothrow @nogc;
    // wl_registry_bind no marked as nothrow in wayland_import
    void bind(wl_registry *reg, uint name, uint vers);
    void dispose();
} 

mixin template GlobalProxy(Self, T, alias wliface, int Destroy_code)
{
private: 
    Proxy!(T, Destroy_code) m_proxy;
    
    static struct Storage {
        static ubyte[__traits(classInstanceSize, Self)] data;
    }

    // Статический указатель на экземпляр
    static Self* s_instance;

    void set(wl_registry* reg, uint name_id, uint vers)
    {
        m_proxy = cast(T*)wl_registry_bind(reg, name_id, &wliface, vers);
    }

public:
    import std.stdio;

    static Global create()
    {
        import std.conv : emplace;
        static assert(is(Self == class), "T должен быть классом");

        if (s_instance is null){
            s_instance = cast(Self*)Storage.data.ptr;
            emplace!Self(s_instance);
        }

        return cast(Global)s_instance;
    }

    static Self get()
    {
        if(s_instance is null)
            writeln("instance is null ", Self.stringof, " ", Storage.data.length, " байт, реально ", Self.sizeof, " байт");
        return *s_instance;
    }

    final inout(T)* c_ptr() inout
    {return m_proxy.c_ptr;}

    final bool empty() const nothrow
    {
        return m_proxy.c_ptr is null;
    }

    final override const(char)* name() const nothrow @nogc
    {
        return wliface.name; 
    }

    override void bind(wl_registry* reg, uint name_id, uint vers)
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

        // 1. Проверяем родительский класс (для одиночного наследования)
        static if (__traits(compiles, __traits(parent, CurrentClass)))
        {
            alias Parent = __traits(parent, CurrentClass);
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
