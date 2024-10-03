module window;

import wayland.core;
import wayland.layer_shell;
import egl;
import opengl; // заменить на drelict

class Window: LayerSurface
{
    override void prepare(Wl_display* display)
    {
        return m_egl.create(display);
    }

    override void configure(uint w, uint h) nothrow
    {
         m_width = w; m_height = h;

        if (m_egl_window) 
            wl_egl_window_resize(m_egl_window, w, h, 0, 0);
        else {
            m_egl_window = wl_egl_window_create(m_surface, w, h);
            m_egl.createSurface(m_egl_window);
        }
    }

    override void draw() nothrow
    {
        m_egl.makeCurrent();

        glViewport(0, 0, m_width, m_height);
        glClearColor(0.18, 0.21, 0.81, 1);
	    glClear(GL_COLOR_BUFFER_BIT);

        m_egl.swapBuffers();
    }
  
	override void destroy() nothrow
    {
        m_egl.destroySurface(m_egl_surface);
	    wl_egl_window_destroy(m_egl_window);

        m_egl_window = null;
    }

    ~this ()
    {
        if (m_egl_window)
            wl_egl_window_destroy(m_egl_window);
    }

private:
    EglWaylandClient m_egl;
    Wl_egl_window* m_egl_window;
}

extern (C) {

    struct Wl_egl_window 
    {
        const(size_t) ver;

        int width;
        int height;
        int dx;
        int dy;

        int attached_width;
        int attached_height;

        void* driver_private;
        void function (Wl_egl_window *, void *) resize_callback;
        void function (void *) destroy_window_callback;

        Wl_proxy* surface;
    }

    Wl_egl_window* wl_egl_window_create(Wl_proxy*, int width, int height);

    void wl_egl_window_destroy(Wl_egl_window*);
    void wl_egl_window_resize(Wl_egl_window*,
		                    int width, int height,
		                    int dx, int dy);
    void wl_egl_window_get_attached_size(Wl_egl_window*,
				                        int *width, int *height);
}