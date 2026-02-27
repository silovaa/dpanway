module window;

import std.stdio;
import wayland;

import easel.canvas : EaselSurface = Surface, Canvas, Rect, Point;
import easel.color;
//import easel.rect;

alias WinProtocols = Protocols!(ScaleFactor, 
                                XDGDecorated, 
                                Seat);

class Window: TopSurface!WinProtocols, InputLayer
{
    // ProtocolStore!Protocols wl;
    // alias wl this;

    this (uint wigth, uint height)
    {
        // wl.toplevel.onClosed  = &closed;
        // wl.toplevel.onConfigure = &configure;
        // wl.toplevel.onAskConfigure = &askConfigure;
        //wl.scale.onScaleChanged = &on_scale_changed;
        onScaleChanged = &on_scale_changed;   
 
        setup();
        seat_bind(this);

        ww=wigth; hh = height;
        m_context = EGLWaylandContext(this, wigth, height);
        // m_width = wigth;
        // m_height = height;
        writeln("Window Ctor");
    }

    ~this ()
    {
        // if (m_egl_window)
        //     wl_egl_window_destroy(m_egl_window);
writeln("Window Dtor");
        
    }

    // override void prepare(Wl_display* display)
    // {
    //     return m_egl.create(display);
    // }

    void configure(uint w, uint h, uint s)
    {writeln("Window configure ", w, " ", h, " ", s);
        //  m_width = w; m_height = h;

        // if (m_egl_window) 
        //     wl_egl_window_resize(m_egl_window, w, h, 0, 0);
        // else {
        //     m_egl_window = wl_egl_window_create(m_surface, w, h);
        //     m_egl.createSurface(m_egl_window);
        // }
        
        if ((w != ww || h != hh) && !start){
            m_context.resize(w, h);
            ww = w; hh =h;
            m_context.swapBuffers();
        }

        //writeln("Window configure ", w, " ", h, " ", s);
    }

    void askConfigure()
    {
        writeln("askConfigure ", ww, " ", hh);

        if (start){
            m_context.makeCurrent();
            auto ret = m_surface.setFromFramebuffer(ww, hh);
            
            if (ret == 0){
                auto cnv = Canvas(m_surface);
                draw(cnv);
                m_surface.flush();
                m_context.swapBuffers();
                start = false;
            }
        }
    }

    void delegate() onClosed;

    void closed()
    {
        if (onClosed) onClosed();
        m_context.terminate();
        wl.dispose();
        writeln("Window closed");
    }

    void on_scale_changed(float factor)
    {
        //Logger.info("Window on_scale_changed %f", factor);
        writeln("scale ", factor);
    }

    override void keyFocused(bool f){writeln("keyFocused ", f);}
    override void key(const KeyMapper m){writeln("key ", m.symbol);}
    override void point(PointerState s, Pointer p){writeln("point ", s);}
    override void point_motion(uint u, Pointer p){writeln("point_motion ", u);}

    override void click(PointerButton button ,
                bool         pressed,
                int          count,
                uint         key_mod){writeln("point_click ", button);}
    override void scroll(int time, int axis, double value){}

    void draw(ref Canvas cnv) 
    {
        auto bkd = rgb(0, 4, 145); 
        //auto r = Rect(0, 0, ww, hh);
        //cnv.addRect(Rect(0, 0, ww, hh));
        cnv.fillStyle = bkd;//(bkd.red, bkd.green, bkd.blue, bkd.alpha);
        cnv.fillRect(Rect(0, 0, ww, hh));
        //cnv.fill();
    }
  
	// override void destroy() nothrow
    // {
    //     m_egl.destroySurface();
	//     wl_egl_window_destroy(m_egl_window);

    //     m_egl_window = null;
    // }

private:
    EGLWaylandContext m_context;
    EaselSurface m_surface;
    uint ww, hh;
    bool start = true;
//     EglWaylandClient m_egl;
//     Wl_egl_window* m_egl_window;
}

// extern(C) nothrow {

//     struct Wl_egl_window 
//     {
//         const(size_t) ver;

//         int width;
//         int height;
//         int dx;
//         int dy;

//         int attached_width;
//         int attached_height;

//         void* driver_private;
//         void function (Wl_egl_window *, void *) resize_callback;
//         void function (void *) destroy_window_callback;

//         Wl_proxy* surface;
//     }

//     Wl_egl_window* wl_egl_window_create(Wl_proxy*, int width, int height);

//     void wl_egl_window_destroy(Wl_egl_window*);
//     void wl_egl_window_resize(Wl_egl_window*,
// 		                    int width, int height,
// 		                    int dx, int dy);
//     void wl_egl_window_get_attached_size(Wl_egl_window*,
// 				                        int *width, int *height);
// }
