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

struct Protocols(T...) 
{
    T data; 

    static foreach (size_t i, Type; T) {
        // Вклеиваем методы, передавая им ссылку на конкретное поле из кортежа data
        // Каждый протокол должен иметь template Iface(alias ctx) {набор методов}
        mixin Type.Iface!(data[i]);
    }
}

//концепт для рендера
template isRender(T) {
    enum isRender = __traits(compiles, (T t) {
        t.attach();
        t.resize();
        t.render();
    });
}

class TopWindow(Render, Proto): TopSurface

{
    Proto protocols;
    alias protocols this;

    private Render render;

    this()
    {

    }
}

