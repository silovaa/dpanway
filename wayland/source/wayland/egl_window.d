module wayland.egl_window;

version(WaylandEGL):

import wayland.internal.core;
import wayland.surface;

struct Egl_Window
{
    this(Surface surface, uint width, uint height)
    {
        m_c_ptr = wl_egl_window_create(surface.c_ptr, width, height);
    }

    ~this() 
    {
        wl_egl_window_destroy(m_c_ptr);
    }

    void resize(uint width, uint height)
    {
        wl_egl_window_resize(m_c_ptr, width, height, 0, 0);
    }

    inout(wl_egl_window)* native() inout
    { return m_c_ptr;}

private:
    wl_egl_window* m_c_ptr;
}