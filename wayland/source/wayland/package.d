module wayland;

public import wayland.display;
public import wayland.input_layer;
public import wayland.logger;

//wayland protocols
public import wayland.surface: ProtocolStore, ScaleFactor;
public import wayland.seat;
public import wayland.xdg_shell;

version(WaylandEGL):
public import wayland.egl_window;

struct Protocols 
{
    XDGTopLevel toplevel;
    ScaleFactor scale;
    XDGDecorated decor;
    Seat seat;
}