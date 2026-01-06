module window;

import std.stdio;

//import wayland.core;
import wayland.xdg_shell_protocol;
import wayland.logger;
// import egl;
// import opengl.gl3; 

class Window: XDGTopLevel
{
    this (uint wigth, uint height)
    {
        super(wigth, height);
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

    override void configure(uint w, uint h, uint s)
    {
        //  m_width = w; m_height = h;

        // if (m_egl_window) 
        //     wl_egl_window_resize(m_egl_window, w, h, 0, 0);
        // else {
        //     m_egl_window = wl_egl_window_create(m_surface, w, h);
        //     m_egl.createSurface(m_egl_window);
        // }

        writeln("Window configure ", w, " ", h, " ", s);
    }

    void delegate() onClosed;

    override void closed()
    {
        if (onClosed) onClosed();
        writeln("Window closed");
    }

    override void on_scale_changed(float factor)
    {
//Logger.info("Window on_scale_changed %f", factor);
writeln("scale ", factor);
    }

    // override void draw() nothrow
    // {
    //     m_egl.makeCurrent();
        
    //     glViewport(0, 0, m_width, m_height);

    //     try
    //         writeln("enter draw");
    //     catch(Exception e) return;
    //     glClearColor(0.18, 0.21, 0.81, 1);
	//     glClear(GL_COLOR_BUFFER_BIT);

    //     m_egl.swapBuffers();
    // }
  
	// override void destroy() nothrow
    // {
    //     m_egl.destroySurface();
	//     wl_egl_window_destroy(m_egl_window);

    //     m_egl_window = null;
    // }

// private:
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
