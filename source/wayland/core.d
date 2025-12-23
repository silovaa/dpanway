module wayland.core;

import core.stdc.string : strcmp;

immutable class WlInterface
{
    private Wl_interface* m_native;

    this(immutable Wl_interface* native)
    {
        m_native = native;
    }

    @property immutable(Wl_interface)* native() nothrow
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
    {return wl_proxy_get_version(cast(wl_proxy*)m_ptr);}

    void reset(T* ptr) 
    {
        if (m_ptr)
            cast(void) wl_proxy_marshal_flags(cast(wl_proxy*)m_ptr, Destroy_code, NULL, 
                                   vers(), WL_MARSHAL_FLAG_DESTROY);
        m_ptr = ptr;
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
    void destroy();
} 

struct Registry 
{
private:
    static shared Global[] s_globals;
    static extern(C) wl_registry* s_registry;

public:
    // Метод для заполнения реестра 
    static void initialize(IService s1, IService s2, IService s3) {
        if (s_registry) return; // Защита от повторной инициализации
        
        _services[0] = cast(shared) s1;
        _services[1] = cast(shared) s2;
        _services[2] = cast(shared) s3;
        
        _isInitialized = true;
    }

    // Доступ к сервису по индексу
    static IService get(size_t index) {
        assert(_isInitialized, "Реестр не инициализирован! Вызовите initialize() в main.");
        return cast(IService) _services[index];
    }
}

struct GlobalProxy
{
    
}

extern (C) nothrow {

    struct Wl_display;
    struct Wl_proxy;
    alias Callback = extern (C) void function();

    struct Wl_message {
        /** Message name */
        const char *name;
        /** Message signature */
        const char *signature;
        /** Object argument interfaces */
        const Wl_interface **types;
    }

    struct Wl_interface{
        /** Interface name */
        const(char)* name;
        /** Interface version */
        int _version;
        /** Number of methods (requests) */
        int method_count;
        /** Method (request) signatures */
        const(Wl_message)* methods;
        /** Number of events */
        int event_count;
        /** Event signatures */
        const(Wl_message)* events;
    }

    void wl_proxy_destroy(Wl_proxy*);
    int wl_proxy_add_listener(Wl_proxy*, Callback*, void* /*data*/);
    Wl_proxy* wl_proxy_marshal_constructor(Wl_proxy*, uint opcode,
                                           const Wl_interface* iface, ...);
    Wl_proxy* wl_proxy_marshal_flags(Wl_proxy*, uint opcode,
                                    const Wl_interface* iface,
                                    uint ver, uint flags, ...);
    uint wl_proxy_get_version(Wl_proxy*);

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

    extern const Wl_interface wl_callback_interface;
    extern const Wl_interface wl_surface_interface;
    //extern const Wl_interface xdg_popup_interface;
    extern const Wl_interface wl_output_interface;
    extern const Wl_interface wl_seat_interface;
    

    struct Wl_callback_listener {
        /**
        * done event
        *
        * Notify the client when the related request is done.
        * @param callback_data request-specific data for the callback
        */
        void function(void* data, Wl_proxy*, uint callback_data) done;
    }
}