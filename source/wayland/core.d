module wayland.core;

import core.stdc.string : strcmp;

immutable class WlInterface
{
    private Wl_interface* m_native;

    this(immutable Wl_interface* native)
    {
        m_native = native;
    }

    @property immutable(Wl_interface)* native() 
    {
        return m_native;
    }

    @property string name() 
    {
        import std.string : fromStringz;
        return fromStringz(m_native.name);
    }

    bool isSame(const(char*) str)
    {
        return strcmp(a._native.name, b._native.name) == 0;
    }
}

bool wlIfaceEquals(immutable(WlInterface) a, immutable(WlInterface) b)
{
    return a is b || strcmp(a._native.name, b._native.name) == 0;
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
        const char *name;
        /** Interface version */
        int _version;
        /** Number of methods (requests) */
        int method_count;
        /** Method (request) signatures */
        const Wl_message *methods;
        /** Number of events */
        int event_count;
        /** Event signatures */
        const Wl_message *events;
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