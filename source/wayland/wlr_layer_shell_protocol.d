module wayland.wlr_layer_shell_protocol;

import wayland.core;

extern const Wl_interface xdg_popup_interface;

immutable WlInterface LayerShellInterface;
immutable WlInterface LayerShellSurfaceInterface;

private:
immutable Wl_interface[] wl_ifaces;

static this() {
    auto ifaces = new Wl_interface[2];
    // Wl_interface zwlr_layer_surface_v1_interface;
    // Wl_interface wl_iface;

    auto wlr_types = [
		null,
		null,
		null,
		null,
        &ifaces[1]//&zwlr_layer_surface_v1_interface,
		&wl_surface_interface,
		&wl_output_interface,
		null,
		null,
		&xdg_popup_interface
	];

    auto zwlr_layer_shell_v1_requests = [
        Wl_message("get_layer_surface", "no?ous", &wlr_types[4]),
		Wl_message("destroy", "3", &wlr_types[0])
    ];

    ifaces[0] = Wl_interface(
        "zwlr_layer_shell_v1", 5,
		2, zwlr_layer_shell_v1_requests.ptr,
		0, null
    );

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

    LayerShellInterface = new immutable WlInterface(&wl_ifaces[0]);
    LayerShellSurfaceInterface = new immutable WlInterface(&wl_ifaces[1]);
}