module wayland.compositor;

import wayland.core;

struct WlCompositor
{
    enum uint CREATE_SURFACE = 0;

    private static extern immutable Wl_interface wl_compositor_interface;
    mixin GlobalProxy!(wl_compositor_interface);
}

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

    this(in ref WlCompositor parent)
    {
        
        native = wl_proxy_marshal_flags(parent.native, WlCompositor.CREATE_SURFACE, 
                                        &wl_surface_interface, 
                                        wl_proxy_get_version(parent.native), 0, null);
    }

    mixin GlobalProxyExt!(wl_surface_interface, DESTROY);
    //mixin ListenerProxy!WlSufaceListener;

    void commit() nothrow 
    {
        wl_proxy_marshal_flags(native, COMMIT, null, 
                             wl_proxy_get_version(native), 0);
    }
        
}

extern(C) {
    extern immutable Wl_interface wl_surface_interface;
}

struct WlCallback
{
    this(in ref WlSurface surface, Listener lst) 
    {
        native = wl_proxy_marshal_flags(surface.native, WlSurface.FRAME, 
                                        &wl_callback_interface,
                                        wl_proxy_get_version(surface.native),
										0, null);

		listener = lst;
    }

    ~this()
    {if (native) wl_proxy_destroy(native);}

    package Wl_proxy* native;
    @disable this(this);

    interface Listener
    {
        void onCallbackDone(uint data) nothrow;
    }

    mixin ListenerProxyExt!(Listener, StructCallbacs);

    private extern(C) {
		struct StructCallbacs
        {
			auto cb1 = &frame_cb;
		}
        static void frame_cb(void* data,
                Wl_proxy* wl_callback, uint callback_data)
        {
            auto self = cast(Listener*) data;
            self.onCallbackDone(callback_data);

        }
    }
    
}

extern(C) {
    extern immutable Wl_interface wl_callback_interface;
}