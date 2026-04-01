module wayland;

public import wayland.display;
public import wayland.input_layer;
public import wayland.logger;

//wayland protocols
public import wayland.surface: ScaleFactor;
public import wayland.seat;
public import wayland.xdg_shell;

version(WaylandEGL):
public import wayland.egl_window;

struct Protocols(T...) 
{
    private T data; 

    static foreach (size_t i, Type; T) {
        // Вклеиваем методы, передавая им ссылку на конкретное поле из кортежа data
        // Каждый протокол должен иметь template Iface(alias ctx) {набор методов}
        mixin Type.Iface!(data[i]);
    }

    private void setup(Surface surf)
    {
        static foreach (i, Type; T) {
            data[i].setup(this, surf);
        }
    }

    private void dispose()
    {
        static foreach_reverse (i, Type; T) {
            data[i].dispose();
        }
    }
}

//концепт для рендера
template isRender(T) {
    enum isRender = __traits(compiles, (T t) {
        void* p; t.setup(p);
        t.resize();
        t.render();
    });
}

// import std.meta : staticIndexOf;

// template TopLayerProtocols(T...) 
//     if (staticIndexOf!(Surfce, T) == -1 && 
//         staticIndexOf!(XDGToplayer, T) == -1) 
// {
//     alias TopLayerProtocols = Protocols!(Surfce, XDGToplayer, T);
// }

alias AllWindowProtocols = Protocols!(ScaleFactor, 
                                    XDGDecorated);

/++ 
 * Окно верхнего уровня, использует все реализованные протоколы
 * ?? зачем может понадобиться менять состав протоколов?
 * ?? возможно нужно будет сделать базовый класс для разных типов окон
 *  Surface создает поверхность и добавляет себя в цикл как LoopTask
 +/
class TopWindow(Render): XDGToplayer!(Render, AllWindowProtocols), Seat
    if (
        isRender!Render //&& 
        // is(Proto : Protocols!(Surfce, XDGToplayer, Args), Args...) && 
        // (staticIndexOf!(Surfce, Args) == -1) && 
        // (staticIndexOf!(XDGToplayer, Args) == -1)
    )
{
    // Protocols!AllWindowProtocols protocols;
    // alias protocols this;

    // private Render render_buf;

    this(uint w, uint h)
    {
        // protocols.setup(this);
        // render_bufer.setup(this, w, h);

        // protocols.get!XDGToplayer.bind(this);
        // protocols.get!Seat.bind(this);
        onScaleChanged = scaleChanged;
    }

protected:
    override void configure(uint w, uint h, uint state)
    {

    }

    override void closed()
    {

    }

private:
    void scaleChanged(float factor)
    {
        scale = factor;
        refresh();
    }

    float scale;
}

//может лучше RenderBuffer создавать динамически и использовать через интерфейс??
alias EGLSinglWindow = TopWindow!(SinglWM, 
                                EGLRenderBuffer, 
                                AllWindowProtocols);

alias EGLMultiWindow = TopWindow!(MultiWM, 
                                EGLRenderBuffer, 
                                AllWindowProtocols);

//To do EGLSinglWindow

