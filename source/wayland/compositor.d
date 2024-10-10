module wayland.compositor;

import wayland.core;

struct WlCompositor
{
    enum uint CREATE_SURFACE = 0;

    private static extern const Wl_interface wl_compositor_interface;
    mixin GlobalProxy!(wl_compositor_interface);
}

class WlSufaceListener: WlListener!WlSurface
{}
struct WlSurface
{
    enum uint  DESTROY = 0;
    enum uint  ATTACH = 1;
    enum uint  DAMAGE = 2;
    enum uint  FRAME = 3;
    enum uint  SET_OPAQUE_REGION = 4;
    enum uint  SET_INPUT_REGION = 5;
    enum uint  COMMIT = 6;
    enum uint  SET_BUFFER_TRANSFORM = 7;
    enum uint  SET_BUFFER_SCALE = 8;
    enum uint  DAMAGE_BUFFER = 9;
    enum uint  OFFSET = 10;

    private static extern const Wl_interface wl_surface_interface;
    mixin Proxy!(WlCompositor, wl_surface_interface, 
                WlCompositor.CREATE_SURFACE, DESTROY)
    mixin ListenerProxy!WlSufaceListener;

    void commit() nothrow 
    {
        wl_proxy_marshal_flags(native, COMMIT, null, 
                             wl_proxy_get_version(native), 0);
    }
        
}