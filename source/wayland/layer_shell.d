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
    Anchor m_anchor = Anchor.TOP;
    uint width, height;
    
    //WlSurface m_surface;
    Wl_proxy* m_primary_surface;
    Wl_proxy* m_surface;
}

enum uint ZWLR_LAYER_SHELL_V1_GET_LAYER_SURFACE = 0;

// package:

//     struct WlSurface {
//         Wl_proxy* primary;
//         Wl_proxy* layer;
//     }