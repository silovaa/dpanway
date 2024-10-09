module wayland.xdg_shell_protocol;

import wayland.core;

immutable WlInterface XdgPopupInterface;
immutable WlInterface XdgPositionerInterface;
immutable WlInterface XdgSurfaceInterface;
immutable WlInterface XdgToplevelInterface;
immutable WlInterface XdgWmBaseInterface;

private:
immutable Wl_interface[] wl_ifaces;

shared static this() {
    auto ifaces = new Wl_interface[5];

    auto xdg_shell_types = [
        null,
        null,
        null,
        null,
        &ifaces[1],
        &ifaces[2],
        &wl_surface_interface,
        &ifaces[3],
        &ifaces[0],
        &ifaces[2],
        &ifaces[1],
        &ifaces[3],
        &wl_seat_interface,
        null,
        null,
        null,
        &wl_seat_interface,
        null,
        &wl_seat_interface,
        null,
        null,
        &wl_output_interface,
        &wl_seat_interface,
        null,
        &ifaces[1],
        null,
    ];

    auto xdg_wm_base_requests = [
        Wl_message("destroy", "", &xdg_shell_types[0]),
        Wl_message("create_positioner", "n", &xdg_shell_types[4]),
        Wl_message("get_xdg_surface", "no", &xdg_shell_types[5]),
        Wl_message("pong", "u", &xdg_shell_types[0]),
    ];

    auto xdg_wm_base_events = [
	    Wl_message("ping", "u", &xdg_shell_types[0]),
    ];

    ifaces[4] = Wl_interface(
        "xdg_wm_base", 6,
	    4, xdg_wm_base_requests.ptr,
	    1, xdg_wm_base_events.ptr,
    );
	
    auto xdg_positioner_requests = [
	    Wl_message("destroy", "", &xdg_shell_types[0]),
        Wl_message("set_size", "ii", &xdg_shell_types[0]),
        Wl_message("set_anchor_rect", "iiii", &xdg_shell_types[0]),
        Wl_message("set_anchor", "u", &xdg_shell_types[0]),
        Wl_message("set_gravity", "u", &xdg_shell_types[0]),
        Wl_message("set_constraint_adjustment", "u", &xdg_shell_types[0]),
        Wl_message("set_offset", "ii", &xdg_shell_types[0]),
        Wl_message("set_reactive", "3", &xdg_shell_types[0]),
        Wl_message("set_parent_size", "3ii", &xdg_shell_types[0]),
        Wl_message("set_parent_configure", "3u", &xdg_shell_types[0]),
    ];

    ifaces[1] = Wl_interface(
        "xdg_positioner", 6,
	    10, xdg_positioner_requests.ptr,
	    0, null,
    );

    auto xdg_surface_requests = [
        Wl_message("destroy", "", &xdg_shell_types[0]),
        Wl_message("get_toplevel", "n", &xdg_shell_types[7]),
        Wl_message("get_popup", "n?oo", &xdg_shell_types[8]),
        Wl_message("set_window_geometry", "iiii", &xdg_shell_types[0]),
        Wl_message("ack_configure", "u", &xdg_shell_types[0]),
    ];

    auto xdg_surface_events = [
	    Wl_message("configure", "u", &xdg_shell_types[0]),
    ];

    ifaces[2] = Wl_interface(
        "xdg_surface", 6,
        5, xdg_surface_requests.ptr,
        1, xdg_surface_events.ptr,
    );

    auto xdg_toplevel_requests = [
        Wl_message("destroy", "", &xdg_shell_types[0]),
        Wl_message("set_parent", "?o", &xdg_shell_types[11]),
        Wl_message("set_title", "s", &xdg_shell_types[0]),
        Wl_message("set_app_id", "s", &xdg_shell_types[0]),
        Wl_message("show_window_menu", "ouii", &xdg_shell_types[12]),
        Wl_message("move", "ou", &xdg_shell_types[16]),
        Wl_message("resize", "ouu", &xdg_shell_types[18]),
        Wl_message("set_max_size", "ii", &xdg_shell_types[0]),
        Wl_message("set_min_size", "ii", &xdg_shell_types[0]),
        Wl_message("set_maximized", "", &xdg_shell_types[0]),
        Wl_message("unset_maximized", "", &xdg_shell_types[0]),
        Wl_message("set_fullscreen", "?o", &xdg_shell_types[21]),
        Wl_message("unset_fullscreen", "", &xdg_shell_types[0]),
        Wl_message("set_minimized", "", &xdg_shell_types[0]),
    ];

    auto xdg_toplevel_events = [
        Wl_message("configure", "iia", &xdg_shell_types[0]),
        Wl_message("close", "", &xdg_shell_types[0]),
        Wl_message("configure_bounds", "4ii", &xdg_shell_types[0]),
        Wl_message("wm_capabilities", "5a", &xdg_shell_types[0]),
    ];

    ifaces[3] = Wl_interface(
        "xdg_toplevel", 6,
        14, xdg_toplevel_requests.ptr,
        4, xdg_toplevel_events.ptr,
    );

    auto xdg_popup_requests = [
        Wl_message("destroy", "", &xdg_shell_types[0]),
        Wl_message("grab", "ou", &xdg_shell_types[22]),
        Wl_message("reposition", "3ou", &xdg_shell_types[24]),
    ];

    auto xdg_popup_events = [
        Wl_message("configure", "iiii", &xdg_shell_types[0]),
        Wl_message("popup_done", "", &xdg_shell_types[0]),
        Wl_message("repositioned", "3u", &xdg_shell_types[0]),
    ];

    ifaces[0] = Wl_interface(
        "xdg_popup", 6,
        3, xdg_popup_requests.ptr,
        3, xdg_popup_events.ptr,
    );

    import std.exception : assumeUnique;
    wl_ifaces = assumeUnique(ifaces);

    XdgPopupInterface = new immutable WlInterface(&wl_ifaces[0]);
    XdgPositionerInterface = new immutable WlInterface(&wl_ifaces[1]);
    XdgSurfaceInterface = new immutable WlInterface(&wl_ifaces[2]);
    XdgToplevelInterface = new immutable WlInterface(&wl_ifaces[3]);
    XdgWmBaseInterface = new immutable WlInterface(&wl_ifaces[4]);
}

