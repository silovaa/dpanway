module layer_shell;

import wayland.core;

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

class LayerSurface
{
    abstract void prepare(Wl_display*);
    abstract bool configure(uint w, uint h) nothrow;

    @property size() const;

    import std.typecons;
    @property void anchor(BitFlags!Anchor);

private:
    Layer m_layer = Layer.TOP;
    Anchor m_anchor = Anchor.TOP;
    uint width, height;
    
    //WlSurface m_surface;
    Wl_proxy* m_surface;
    Wl_proxy* m_layer_surface;

package:
	final bool make_surface(Wl_proxy* compositor, Wl_proxy* layer_shell, Wl_proxy* output) nothrow
	{
		m_surface = wl_proxy_marshal_flags(compositor, WL_COMPOSITOR_CREATE_SURFACE,
                                            &wl_surface_interface, 
                                            wl_proxy_get_version(compositor), 0, null);
											
        m_layer_surface = wl_proxy_marshal_flags(layer_shell, ZWLR_LAYER_SHELL_V1_GET_LAYER_SURFACE, 
                                    &zwlr_layer_surface_v1_interface, 
                                    wl_proxy_get_version(layer_shell), 0, null, 
                                    m_primary_surface, 
                                    output, 
                                    m_layer, "LayerSurface");
        if (!m_layer_surface || 
			wl_proxy_add_listener(m_layer_surface,
				                cast(Callback*) &m_listener, this) < 0)
            return false;

		uint ver = wl_proxy_get_version(m_layer_surface);

        wl_proxy_marshal_flags(m_layer_surface, ZWLR_LAYER_SURFACE_V1_SET_SIZE, NULL, 
                            ver, 0, m_width, m_height);
        wl_proxy_marshal_flags(m_layer_surface, ZWLR_LAYER_SURFACE_V1_SET_ANCHOR, NULL, 
                            ver, 0, m_anchor);
        //To do margin, exlusive zone
        // wl_proxy_marshal_flags(m_layer_surface, ZWLR_LAYER_SURFACE_V1_SET_MARGIN, NULL, 
        //                     ver, 0, top, right, bottom, left);

        wl_proxy_marshal_flags(m_primary_surface, WL_SURFACE_COMMIT, NULL, 
                            wl_proxy_get_version(layer_win.m_surface), 0);

        return true;
	}
}

enum uint ZWLR_LAYER_SHELL_V1_GET_LAYER_SURFACE = 0;
enum uint ZWLR_LAYER_SURFACE_V1_SET_ANCHOR = 1;
enum uint ZWLR_LAYER_SURFACE_V1_SET_MARGIN = 2;


// package:

//     struct WlSurface {
//         Wl_proxy* primary;
//         Wl_proxy* layer;
//     }