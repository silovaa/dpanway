module wayland.egl_window;

version(WaylandEGL):

import wayland.internal.core;
import wayland.logger;
import wayland.surface;
import wayland.display;
import egl;

ref wayland.Display egl_connect(Protocol...)()
{
    auto ref dpy = wayland.Display.connect!(Protocol)();
    auto egl_vers = egl.Display.initialize(EGL_PLATFORM_WAYLAND_EXT, cast(void*)dpy.c_ptr);

    Logger.info("EGL version ", egl_vers[0], ".", egl_vers[1]);

    return dpy;
}

struct EGLWindowContext
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

    inout(wl_egl_window)* c_ptr() inout
    { return m_c_ptr;}

private:
    wl_egl_window* m_c_ptr;
}