
import wayland.core;

extern const Wl_interface xdg_popup_interface;
//extern const Wl_interface zwlr_layer_surface_v1_interface;

struct LayerShellProtocol
{
    @property static const(Wl_interface*) zwlr_interface() 
    {
        return &get_inst().wl_iface;
    }

    @property static const(Wl_interface*) zwlr_surfce_interface() 
    {
        return &get_inst().zwlr_layer_surface_v1_interface;
    }

    //bool isSameInterface(const(char)* iface) const
    //{

    //}

    //Wl_proxy* registryGlobal(Wl_proxy* reg, uint name)
    //{

    //}

    //Wl_proxy* makeSurface(Wl_proxy* )

	static auto ref get_inst()
    {
        static LayerShellProtocol self();
        static Helper helper(self);

        return self;
    }

private:
    const(Wl_interface*)[] wlr_types = [
		null,
		null,
		null,
		null,
        null, //&zwlr_layer_surface_v1_interface,
		&wl_surface_interface,
		&wl_output_interface,
		null,
		null,
		&xdg_popup_interface
	];

	const(Wl_message)[] zwlr_layer_shell_v1_requests = [
        {"get_layer_surface", "no?ous", wlr_layer_shell_unstable_v1_types.ptr + 4},
		{"destroy", "3", wlr_layer_shell_unstable_v1_types.ptr}
    ]

	const(Wl_message)[] zwlr_layer_surface_v1_requests = [
        {"set_size", "uu", wlr_layer_shell_unstable_v1_types.ptr},
		{"set_anchor", "u", wlr_layer_shell_unstable_v1_types.ptr},
		{"set_exclusive_zone", "i", wlr_layer_shell_unstable_v1_types.ptr},
		{"set_margin", "iiii", wlr_layer_shell_unstable_v1_types.ptr},
		{"set_keyboard_interactivity", "u", wlr_layer_shell_unstable_v1_types.ptr},
		{"get_popup", "o", wlr_layer_shell_unstable_v1_types.ptr + 9},
		{"ack_configure", "u", wlr_layer_shell_unstable_v1_types.ptr},
		{"destroy", "", wlr_layer_shell_unstable_v1_types.ptr},
		{"set_layer", "2u", wlr_layer_shell_unstable_v1_types.ptr},
		{"set_exclusive_edge", "5u", wlr_layer_shell_unstable_v1_types.ptr}
    ]

	const(Wl_message)[] zwlr_layer_surface_v1_events = [
        {"configure", "uuu", wlr_layer_shell_unstable_v1_types.ptr},
		{"closed", "", wlr_layer_shell_unstable_v1_types.ptr}
    ]

	const(Wl_interface) zwlr_layer_surface_v1_interface = {
        "zwlr_layer_surface_v1", 5,
		10, zwlr_layer_surface_v1_requests.ptr,
		2, zwlr_layer_surface_v1_events.ptr
    };

    const(Wl_interface) wl_iface = {
        "zwlr_layer_shell_v1", 5,
		2, zwlr_layer_shell_v1_requests.ptr,
		0, null
    }

    struct Helper
    {
        this(ref LayerShellProtocol inst)
        {
            inst.wlr_types[4] = &inst.zwlr_layer_surface_v1_interface;
        }
    }
}

//---------------------------------------------------------------
//const(Wl_interface) xdg_popup_interface = {
	// 	"xdg_popup", 1,
	// 	1, xdg_popup_requests.ptr,
	// 	1, xdg_popup_events.ptr
	// };

	// const Wl_message[] xdg_popup_requests = [
	// 	{ "destroy", "", types.ptr + 0 }
	// ];
	// const Wl_message[] xdg_popup_events = [
	// 	{ "popup_done", "", types.ptr + 0 }
	// ];
	// const(Wl_interface*)[] types = [
	// 	null,
	// 	null,
	// 	null,
	// 	null,
	// 	&xdg_surface_interface,
	// 	&wl_surface_interface,
	// 	&xdg_popup_interface,
	// 	&wl_surface_interface,
	// 	&wl_surface_interface,
	// 	&wl_seat_interface,
	// 	null,
	// 	null,
	// 	null,
	// 	&xdg_surface_interface,
	// 	&wl_seat_interface,
	// 	null,
	// 	null,
	// 	null,
	// 	&wl_seat_interface,
	// 	null,
	// 	&wl_seat_interface,
	// 	null,
	// 	null,
	// 	&wl_output_interface
	// ];

	// const Wl_message[] xdg_surface_requests = [
	// 	{ "destroy", "", types.ptr + 0 },
	// 	{ "set_parent", "?o", types.ptr + 13 },
	// 	{ "set_title", "s", types.ptr + 0 },
	// 	{ "set_app_id", "s", types.ptr + 0 },
	// 	{ "show_window_menu", "ouii", types.ptr + 14 },
	// 	{ "move", "ou", types.ptr + 18 },
	// 	{ "resize", "ouu", types.ptr + 20 },
	// 	{ "ack_configure", "u", types.ptr + 0 },
	// 	{ "set_window_geometry", "iiii", types.ptr + 0 },
	// 	{ "set_maximized", "", types.ptr + 0 },
	// 	{ "unset_maximized", "", types.ptr + 0 },
	// 	{ "set_fullscreen", "?o", types.ptr + 23 },
	// 	{ "unset_fullscreen", "", types.ptr + 0 },
	// 	{ "set_minimized", "", types.ptr + 0 }
	// ];
	// const Wl_message[] xdg_surface_events = [
	// 	{ "configure", "iiau", types.ptr + 0 },
	// 	{ "close", "", types.ptr + 0 }
	// ];
	// const Wl_interface xdg_surface_interface = {
	// 	"xdg_surface", 1,
	// 	14, xdg_surface_requests.ptr,
	// 	2, xdg_surface_events.ptr
	// };
