module wayland.wlr_layer_shell;

import wayland.core;
import wayland.compositor;
import wayland.output;
import wayland.xdg_shell_protocol;

enum Layer {
	BACKGROUND,
	BOTTOM,
	TOP,
	OVERLAY
}

enum Anchor {
	/**
	 * the top edge of the anchor rectangle
	 */
	TOP = 1,
	/**
	 * the bottom edge of the anchor rectangle
	 */
	BOTTOM = 2,
	/**
	 * the left edge of the anchor rectangle
	 */
	LEFT = 4,
	/**
	 * the right edge of the anchor rectangle
	 */
    RIGHT = 8,
}

struct WlrLayerShell
{
	enum uint GET_LAYER_SURFACE = 0;
	enum uint DESTROY = 1;

    mixin GlobalProxy!(wl_ifaces[0], DESTROY);
}

class WlrLayerSufaceListener: WlListener!WlrLayerSurface
{
    alias ConfigureCb = void delegate (ref WlrLayerSurface, uint width, uint height) nothrow;
    alias ClosedCb    = void delegate (ref WlrLayerSurface) nothrow;

    this(ConfigureCb configure, ClosedCb closed)
    {
		super([
			&config_cb, &close_cb,
		]);

		this.configure = configure;
		this.closed = closed;
    }

	ConfigureCb configure;
	ClosedCb closed;

    private extern(C) {
        static void config_cb(void *data, Wl_proxy* layer_surface,
			  		uint serial, uint width, uint height)
        {
            auto self = cast(WlSurface) data;
			if (self.m_listener.configure)
            	self.m_listener.configure(width, height);

            wl_proxy_marshal_flags(layer_surface, WlrLayerSurface.ACK_CONFIGURE, 
                                null, wl_proxy_get_version(layer_surface), 
                                0, serial);
        }

		void close_cb(void *data, Wl_proxy* layer_surface)
    	{
			auto self = cast(WlSurface) data;
			if (self.m_listener.closed)
            	self.m_listener.closed();
		}
    
    }
}
struct WlrLayerSurface
{
	enum uint SET_SIZE = 0;
	enum uint SET_ANCHOR = 1;
	enum uint SET_EXCLUSIVE_ZONE = 2;
	enum uint SET_MARGIN = 3;
	enum uint SET_KEYBOARD_INTERACTIVITY = 4;
	enum uint GET_POPUP = 5;
	enum uint ACK_CONFIGURE = 6;
	enum uint DESTROY = 7;
	enum uint SET_LAYER = 8;
	enum uint SET_EXCLUSIVE_EDGE = 9;

	this(in WlrLayerShell layer_shell, 
		in WlSurface 	surface, 
		in WlOutput 	output, 
		in Layer 		layer = Layer.TOP)
	{
		native = wl_proxy_marshal_flags(layer_shell.native, WlrLayerShell.GET_LAYER_SURFACE, 
                                    wl_ifaces[1], 
                                    wl_proxy_get_version(layer_shell.native), 0, null, 
                                    surface.native, 
                                    output.native, 
                                    layer, cast(const(char)*)"LayerSurface");
	}

	~this()
	{
		if (native)
			wl_proxy_marshal_flags(native, ZWLR_LAYER_SURFACE_V1_DESTROY, 
		 					null, wl_proxy_get_version(native), 
							WL_MARSHAL_FLAG_DESTROY);	
	}

	package Wl_proxy* native;

	mixin ListenerProxy!WlrLayerSufaceListener;

	void setSize(uint w, uint h) nothrow
	{
		wl_proxy_marshal_flags(native, SET_SIZE, null, 
                            wl_proxy_get_version(native), 0, w, h);
	}

	void setAnchor(Anchor a) nothrow
	{
		wl_proxy_marshal_flags(native, SET_ANCHOR, null, 
                               wl_proxy_get_version(native), 0, a);
	}
}


//immutable WlInterface LayerShellInterface;
//immutable WlInterface LayerShellSurfaceInterface;

private:
immutable Wl_interface[] wl_ifaces;

shared static this() {
    auto ifaces = new Wl_interface[2];

    auto wlr_types = [
		null,
		null,
		null,
		null,
        &ifaces[1],//&zwlr_layer_surface_v1_interface,
		&wl_surface_interface,
		&wl_output_interface,
		null,
		null,
		XdgPopupInterface.native
	];

    auto zwlr_layer_shell_v1_requests = [
        Wl_message("get_layer_surface", "no?ous", &wlr_types[4]),
		Wl_message("destroy", "3", &wlr_types[0])
    ];

    ifaces[0].name = "zwlr_layer_shell_v1";
	ifaces[0]._version = 5;
	ifaces[0].method_count = 2;
	ifaces[0].methods = zwlr_layer_shell_v1_requests.ptr;
	ifaces[0].event_count =	0;
	ifaces[0].events = null;

	auto zwlr_layer_surface_v1_requests = [
        Wl_message("set_size", "uu", &wlr_types[0]),
		Wl_message("set_anchor", "u", &wlr_types[0]),
		Wl_message("set_exclusive_zone", "i", &wlr_types[0]),
		Wl_message("set_margin", "iiii", &wlr_types[0]),
		Wl_message("set_keyboard_interactivity", "u", &wlr_types[0]),
		Wl_message("get_popup", "o", &wlr_types[9]),
		Wl_message("ack_configure", "u", &wlr_types[0]),
		Wl_message("destroy", "", &wlr_types[0]),
		Wl_message("set_layer", "2u", &wlr_types[0]),
		Wl_message("set_exclusive_edge", "5u", &wlr_types[0])
    ];

	auto zwlr_layer_surface_v1_events = [
        Wl_message("configure", "uuu", &wlr_types[0]),
		Wl_message("closed", "", &wlr_types[0])
    ];

    ifaces[1] = Wl_interface(
        "zwlr_layer_surface_v1", 5,
		10, zwlr_layer_surface_v1_requests.ptr,
		2, zwlr_layer_surface_v1_events.ptr
    );

    import std.exception : assumeUnique;
    wl_ifaces = assumeUnique(ifaces);

    //LayerShellInterface = new immutable WlInterface(&wl_ifaces[0]);
    //LayerShellSurfaceInterface = new immutable WlInterface(&wl_ifaces[1]);
}

// class LayerSurface
// {
//     abstract void prepare(Wl_display*);
//     abstract void configure(uint w, uint h) nothrow;
//     abstract void draw() nothrow;
//    // abstract void flush() nothrow;
// 	abstract void destroy() nothrow;

//     //@property size() const;

//     //import std.typecons;
//     //@property void anchor(BitFlags!Anchor);

// protected:
// 	final void queryDraw() 
// 	{
// 		uint ver = wl_proxy_get_version(m_surface);
//         m_frame = wl_proxy_marshal_flags(m_surface, WL_SURFACE_FRAME, 
//                                         &wl_callback_interface, ver,
// 										0, null);

// 		wl_proxy_add_listener(m_frame,
// 				     cast(Callback*) &m_frame_listener, cast(void*)this);

// 		// wl_proxy_marshal_flags(m_surface, WL_SURFACE_COMMIT, 
// 		// 					null, ver, 
// 		// 					0);
// 	}

// 	Wl_proxy* m_surface;
// 	uint m_width, m_height;

// private:
//     Layer m_layer = Layer.TOP;
//     Anchor m_anchor = Anchor.TOP;
    
//     //WlSurface m_surface;
//     Wl_proxy* m_layer_surface;
//     immutable Layer_surface_listener m_listener = {
//         &config_cb, &close_cb
//     };
//     Wl_proxy* m_frame;
// 	immutable Wl_callback_listener m_frame_listener = {
// 		&frame_cb
// 	};

// package:
// 	final bool make_surface(Wl_proxy* compositor, 
//                             Wl_proxy* layer_shell, 
//                             Wl_proxy* output) nothrow
// 	{
// 		import wayland.wlr_layer_shell_protocol;

// 		m_surface = wl_proxy_marshal_flags(compositor, WL_COMPOSITOR_CREATE_SURFACE,
//                                             &wl_surface_interface, 
//                                             wl_proxy_get_version(compositor), 0, null);
											
//         m_layer_surface = wl_proxy_marshal_flags(layer_shell, ZWLR_LAYER_SHELL_V1_GET_LAYER_SURFACE, 
//                                     LayerShellSurfaceInterface.native, 
//                                     wl_proxy_get_version(layer_shell), 0, null, 
//                                     m_surface, 
//                                     output, 
//                                     m_layer, cast(const(char)*)"LayerSurface");
//         if (!m_layer_surface || 
// 			wl_proxy_add_listener(m_layer_surface,
// 				                cast(Callback*) &m_listener, cast(void*) this) < 0)
//             return false;

// 		uint ver = wl_proxy_get_version(m_layer_surface);
//         wl_proxy_marshal_flags(m_layer_surface, ZWLR_LAYER_SURFACE_V1_SET_SIZE, null, 
//                             ver, 0, m_width, m_height);
//         wl_proxy_marshal_flags(m_layer_surface, ZWLR_LAYER_SURFACE_V1_SET_ANCHOR, null, 
//                             ver, 0, m_anchor);
//         //To do margin, exlusive zone
//         // wl_proxy_marshal_flags(m_layer_surface, ZWLR_LAYER_SURFACE_V1_SET_MARGIN, null, 
//         //                     ver, 0, top, right, bottom, left);

//         wl_proxy_marshal_flags(m_surface, WL_SURFACE_COMMIT, null, 
//                             wl_proxy_get_version(m_surface), 0);

//         return true;
// 	}
// }

// private:
// //enum uint ZWLR_LAYER_SHELL_V1_GET_LAYER_SURFACE = 0;
// //enum uint ZWLR_LAYER_SHELL_V1_DESTROY = 1;



// extern (C) {
// struct Layer_surface_listener {
// 	/**
// 	 * suggest a surface change
// 	 *
// 	 * The configure event asks the client to resize its surface.
// 	 *
// 	 * Clients should arrange their surface for the new states, and
// 	 * then send an ack_configure request with the serial sent in this
// 	 * configure event at some point before committing the new surface.
// 	 *
// 	 * The client is free to dismiss all but the last configure event
// 	 * it received.
// 	 *
// 	 * The width and height arguments specify the size of the window in
// 	 * surface-local coordinates.
// 	 *
// 	 * The size is a hint, in the sense that the client is free to
// 	 * ignore it if it doesn't resize, pick a smaller size (to satisfy
// 	 * aspect ratio or resize in steps of NxM pixels). If the client
// 	 * picks a smaller size and is anchored to two opposite anchors
// 	 * (e.g. 'top' and 'bottom'), the surface will be centered on this
// 	 * axis.
// 	 *
// 	 * If the width or height arguments are zero, it means the client
// 	 * should decide its own window dimension.
// 	 */
// 	void function (void *data, Wl_proxy*,
// 			  uint serial, uint width, uint height) configure;
// 	/**
// 	 * surface should be closed
// 	 *
// 	 * The closed event is sent by the compositor when the surface
// 	 * will no longer be shown. The output may have been destroyed or
// 	 * the user may have asked for it to be removed. Further changes to
// 	 * the surface will be ignored. The client should destroy the
// 	 * resource after receiving this event, and create a new surface if
// 	 * they so choose.
// 	 */
// 	void function(void *data, Wl_proxy*) closed;
// }

// 	void config_cb(void *data, Wl_proxy* layer_surface,
// 			  				uint serial, uint width, uint height)
//     {
//         auto self = cast(LayerSurface) data;
//         self.configure(width, height);

//         wl_proxy_marshal_flags(layer_surface, ZWLR_LAYER_SURFACE_V1_ACK_CONFIGURE, 
// 							null, wl_proxy_get_version(layer_surface), 
// 							0, serial);
// import std.stdio;							

//         self.draw(); // --???
// writeln("enter config ",width, " ", height);
// 		self.queryDraw();
//     }

//     void close_cb(void *data, Wl_proxy* layer_surface)
//     {
// 		auto self = cast(LayerSurface) data;
// 		self.destroy();

// 		wl_proxy_marshal_flags(layer_surface, ZWLR_LAYER_SURFACE_V1_DESTROY, 
// 		 					null, wl_proxy_get_version(layer_surface), 
// 							WL_MARSHAL_FLAG_DESTROY);
// 		if (self.m_frame) {
// 			wl_proxy_destroy(self.m_frame);

// 		}

// 		uint ver = wl_proxy_get_version(self.m_surface);
// 		wl_proxy_marshal_flags(self.m_surface, WL_SURFACE_DESTROY, 
// 							null, ver, 
// 							WL_MARSHAL_FLAG_DESTROY);

// 		wl_proxy_marshal_flags(self.m_surface, WL_SURFACE_COMMIT, 
// 							null, ver, 
// 							0);
// 		self.m_surface = null;
//     }

// 	void frame_cb(void* data,
//                 Wl_proxy* wl_callback, uint callback_data)
// 	{
// 		wl_proxy_destroy(wl_callback);

// 		auto self = cast(LayerSurface) data;
// 		self.draw();

// 		// wl_proxy_marshal_flags(self.m_surface, WL_SURFACE_COMMIT, 
// 		// 					null, wl_proxy_get_version(self.m_surface), 
// 		// 					0);
// 	}
// }