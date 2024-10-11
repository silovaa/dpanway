module wayland.core;

import std.exception;
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

    @property uint p_version() nothrow
    {return m_native._version;}

    bool isSame(const(char*) str) nothrow
    {
        return strcmp(m_native.name, str) == 0;
    }
}

bool wlIfaceEquals(immutable(WlInterface) a, immutable(WlInterface) b)
{
    return a is b || strcmp(a.m_native.name, b.m_native.name) == 0;
}

class WlListener(T, StructFunc)
{
    //private const(Callback)[] m_callbaks;
    private immutable StructFunc m_callbaks;

    // this(const(Callback[]) cbs)
    // {m_callbaks = cbs;}

    package final void create(ref T proxy)
    {
        enforce(wl_proxy_add_listener(proxy.native, 
                                    cast(Callback*) &m_callbaks, 
                                    cast(void*) &proxy) >= 0,
                "add listener failed");
    }
}

mixin template ListenerProxy(ListenerT)
{
    @property void listener(ListenerT lst)
    {
        m_listener = lst;
        m_listener.create(this);
    }

    private ListenerT m_listener;
}

mixin template GlobalProxy(alias i)
{
    static @property immutable(WlInterface) iface()
    {
        static auto s_iface = new immutable WlInterface(&i);
        return s_iface;
    } 

    package Wl_proxy* native;

    ~this()
    {if (native) wl_proxy_destroy(native);}

    @disable this(this);
}

mixin template GlobalProxyExt(alias i, alias op_destroy)
{
     static @property immutable(WlInterface) iface()
    {
        static if(is(typeof(i) == immutable(WlInterface)))
            return i;
        else {
            static auto s_iface = new immutable WlInterface(&i);
            return s_iface;
        }
    } 

    package Wl_proxy* native;

    ~this()
    {
        if (native)
            wl_proxy_marshal_flags(native, op_destroy, null, 
                                wl_proxy_get_version(native), 
							    WL_MARSHAL_FLAG_DESTROY);
    }

    @disable this(this);
}

mixin template Proxy(alias op_destroy)
{
    ~this()
    {
        if (native)
            wl_proxy_marshal_flags(native, op_destroy, null, 
                                wl_proxy_get_version(native), 
							    WL_MARSHAL_FLAG_DESTROY);
    }
    package Wl_proxy* native;
    @disable this(this);
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
    int wl_proxy_add_listener(Wl_proxy*, const(Callback)*, void* /*data*/);
    Wl_proxy* wl_proxy_marshal_constructor(Wl_proxy*, uint opcode,
                                           const Wl_interface* iface, ...);
    Wl_proxy* wl_proxy_marshal_flags(Wl_proxy*, uint opcode,
                                    const Wl_interface* iface,
                                    uint ver, uint flags, ...);
    uint wl_proxy_get_version(Wl_proxy*);

    enum uint WL_MARSHAL_FLAG_DESTROY = 1 << 0;

    enum uint WL_COMPOSITOR_CREATE_REGION = 1;

    extern const Wl_interface wl_callback_interface;
    //extern const Wl_interface wl_surface_interface;
    //extern const Wl_interface xdg_popup_interface;
    //extern const Wl_interface wl_output_interface;
    extern immutable Wl_interface wl_seat_interface;
    

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