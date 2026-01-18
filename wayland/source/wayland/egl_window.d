module wayland.egl_window;

version(WaylandEGL):

import wayland.internal.core;
import wayland.logger;
import wayland.surface;
import wayland.display;
import egl;

void egl_connect(Protocol...)()
{
    wayland.Display.connect!Protocol();
    auto egl_vers = egl.Display.initialize(EGL_PLATFORM_WAYLAND_EXT, 
                                           cast(void*)wayland.Display.native);

    Logger.info("EGL version %i.%i", egl_vers[0], egl_vers[1]);
}

void egl_disconnect()
{
    egl.Display.terminate();
    wayland.Display.instance.dispose();
}

struct EGLWindowContext
{
    @disable this(this);

    alias m_context this; 

    this(Surface surface, uint width, uint height)
    {
        m_c_ptr = wl_egl_window_create(surface.c_ptr, width, height);
        m_context = WindowContextES3(cast(void*)m_c_ptr);
        Logger.info("EGL ");
    }

    void resize(uint width, uint height)
    {
        wl_egl_window_resize(m_c_ptr, width, height, 0, 0);
        glClearColor(0.1f, 0.2f, 0.3f, 0.5f);
        glClear(GL_STENCIL_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
        glViewport(0, 0, width, height);
    }

    inout(wl_egl_window)* c_ptr() inout
    { return m_c_ptr;}

    void terminate()
    {
        m_context.terminate();
        if (m_c_ptr)
            wl_egl_window_destroy(m_c_ptr);
    }

    WindowContextES3 m_context;

private:
    wl_egl_window* m_c_ptr;
    
}