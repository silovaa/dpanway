module core;

extern (C) {

    struct Wl_display;
    struct Wl_proxy;
    alias Callback = extern (C) void function();
    struct Wl_interface;

    void wl_proxy_destroy(Wl_proxy*);
    int wl_proxy_add_listener(Wl_proxy*, Callback*, void* /*data*/);
    Wl_proxy* wl_proxy_marshal_constructor(Wl_proxy*, uint opcode,
                                           const(Wl_interface*) iface, ...);
    Wl_proxy* wl_proxy_marshal_flags(Wl_proxy*, uint opcode,
                                    const(Wl_interface*) iface,
                                    uint ver, uint flags, ...);
    uint wl_proxy_get_version(Wl_proxy*);
}