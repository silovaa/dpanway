module wayland.core;

import core.stdc.string : strcmp;

immutable class WlInterface
{
    private wl_interface* m_native;

    this(immutable wl_interface* native)
    {
        m_native = native;
    }

    @property immutable(wl_interface)* native() nothrow
    {
        return m_native;
    }

    @property string name() nothrow
    {
        import std.string : fromStringz;
        return fromStringz(m_native.name);
    }

    bool isSame(const(char*) str) nothrow
    {
        return strcmp(m_native.name, str) == 0;
    }
}

bool wlIfaceEquals(immutable(WlInterface) a, immutable(WlInterface) b)
{
    return a is b || strcmp(a.m_native.name, b.m_native.name) == 0;
}

struct Proxy (T, int Destroy_code) 
{
    this(T* p) {m_ptr = p;}

    @disable this(this);

    ~this()
    {
        if (m_ptr)
            cast(void) wl_proxy_marshal_flags(cast(wl_proxy*)m_ptr, Destroy_code, NULL, 
                                   vers(), WL_MARSHAL_FLAG_DESTROY);
    }

    uint vers() const nothrow
    {
        return m_ptr ? wl_proxy_get_version(cast(wl_proxy*)m_ptr) : 0;
    }

    void opAssign(T* ptr) 
    {
        if (m_ptr != ptr) {
            if (m_ptr)
                cast(void) wl_proxy_marshal_flags(cast(wl_proxy*)m_ptr, Destroy_code, NULL, 
                                    vers(), WL_MARSHAL_FLAG_DESTROY);
            m_ptr = ptr;
        }
    }

    T* c_ptr() const 
    {return m_ptr;}

private:
    T* m_ptr;
}

interface Global
{
    const(char)* name() const nothrow;
    void bind(wl_registry *reg, uint name, uint vers) nothrow;
    void dispose();
} 

import std.conv : emplace;

class GlobalCustomProxy(Self, T, alias wliface, int Destroy_code): Global
    if (is(typeof(wliface) : wl_interface*))
{
private: 
    Proxy!(T, Destroy_code) m_proxy;
    
    static ubyte[__traits(classInstanceSize, Self)] s_storage;

public:
    static Self instance;

    static Global create()
    {
        if (instance is null)
            instance = emplace!(Self)(s_storage[]);

        return instance;
    }

    @disable this();

    T* c_ptr() const 
    {return m_proxy.c_ptr;}

    const(char)* name() const nothrow
    {
        return wliface.name; 
    }

    void bind(wl_registry* reg, uint name, uint vers) nothrow
    {
        m_proxy = cast(T*)wl_registry_bind(reg, name, &wliface, vers);
    }

    void dispose()
    {
        m_proxy = null;
    }
}

final class GlobalProxy( T, alias wliface, int Destroy_code) 
    : GlobalCustomProxy!(GlobalProxy!(T, wliface, Destroy_code), T, wliface, Destroy_code)
{}

alias surface_interface = wl_surface_interface;
alias seat_interface = wl_seat_interface;

extern (C) nothrow {

    struct wl_proxy;
    struct wl_registry;
    alias Callback = extern (C) void function();

    struct wl_message {
        /** Message name */
        const char *name;
        /** Message signature */
        const char *signature;
        /** Object argument interfaces */
        const wl_interface **types; 
    }

    struct wl_interface{
        /** Interface name */
        const(char)* name;
        /** Interface version */
        int _version;
        /** Number of methods (requests) */
        int method_count;
        /** Method (request) signatures */
        const(wl_message)* methods;
        /** Number of events */
        int event_count;
        /** Event signatures */
        const(wl_message)* events;
    }

    void wl_proxy_destroy(wl_proxy*);
    int wl_proxy_add_listener(wl_proxy*, Callback*, void* /*data*/);
    wl_proxy* wl_proxy_marshal_constructor(wl_proxy*, uint opcode,
                                           const wl_interface* iface, ...);
    wl_proxy* wl_proxy_marshal_flags(wl_proxy*, uint opcode,
                                    const wl_interface* iface,
                                    uint ver, uint flags, ...);
    uint wl_proxy_get_version(wl_proxy*);

    enum uint WL_MARSHAL_FLAG_DESTROY = 1 << 0;

    enum uint WL_COMPOSITOR_CREATE_SURFACE = 0;
    enum uint WL_COMPOSITOR_CREATE_REGION = 1;

    enum uint  WL_SURFACE_DESTROY = 0;
    enum uint  WL_SURFACE_ATTACH = 1;
    enum uint  WL_SURFACE_DAMAGE = 2;
    enum uint  WL_SURFACE_FRAME = 3;
    enum uint  WL_SURFACE_SET_OPAQUE_REGION = 4;
    enum uint  WL_SURFACE_SET_INPUT_REGION = 5;
    enum uint  WL_SURFACE_COMMIT = 6;
    enum uint  WL_SURFACE_SET_BUFFER_TRANSFORM = 7;
    enum uint  WL_SURFACE_SET_BUFFER_SCALE = 8;
    enum uint  WL_SURFACE_DAMAGE_BUFFER = 9;
    enum uint  WL_SURFACE_OFFSET = 10;

    extern __gshared wl_interface wl_callback_interface;
    extern __gshared wl_interface wl_surface_interface;
    //extern const wl_interface xdg_popup_interface;
    extern __gshared wl_interface wl_output_interface;
    extern __gshared wl_interface wl_seat_interface;
    

    struct Wl_callback_listener {
        /**
        * done event
        *
        * Notify the client when the related request is done.
        * @param callback_data request-specific data for the callback
        */
        void function(void* data, wl_proxy*, uint callback_data) done;
    }
}