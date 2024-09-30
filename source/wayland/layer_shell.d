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
    //bool create(Wl_proxy* surface, Wl_proxy* layer_shell) nothrow;
    abstract bool configure(uint w, uint h) nothrow;

    @property size() const;

private:
    Layer m_layer = Layer.TOP;
    Anchor m_anchor = ;
    uint width, height;
    
    //WlSurface m_surface;
    Wl_proxy* primary_surface;
    Wl_proxy* layer_surface;

package:
    bool create(Wl_proxy* surface, Wl_proxy* layer_shell, Wl_proxy* output) final nothrow
    {
        primary_surface = surface;
        layer_surface = wl_proxy_marshal_flags(layer_shell, ZWLR_LAYER_SHELL_V1_GET_LAYER_SURFACE, 
                                    &zwlr_layer_surface_v1_interface, 
                                    wl_proxy_get_version(layer_shell), 0, null, surface, output, m_layer, "LayerSurface");

        if (layer_surface && wl_proxy_add_listener(layer_surface,
				                    cast(Callback*) &m_listener, data) >= 0){
            
            

        }

        return false;
    }
}

// package:

//     struct WlSurface {
//         Wl_proxy* primary;
//         Wl_proxy* layer;
//     }