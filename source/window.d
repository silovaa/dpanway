module window;

import wayland.layer_shell;
import egl;

class Window: LayerSurface
{
    override void prepare(Wl_display* display)
    {
        return egl.create(display);
    }

    override void configure(uint w, uint h) nothrow
    {
         m_width = w; m_height = h;

        if (m_egl_window) 
            wl_egl_window_resize(m_egl_window, w, h, 0, 0);
        else {
            m_egl_window = wl_egl_window_create(m_surface, w, h);
            m_egl_surface = egl.createSurface(m_egl_window);
        }
    }

    override void draw() nothrow
    {
        egl.makeCurrent(m_egl_surface);

        glViewport(0, 0, m_width, m_height);
        glClearColor(0.18, 0.21, 0.81, 1);
	    glClear(GL_COLOR_BUFFER_BIT);

        egl.swapBuffers(m_egl_surface);
    }
  
	override void destroy() nothrow
    {
        egl.destroySurface(m_egl_surface);
	    wl_egl_window_destroy(m_egl_window);
    }

private:
    EglState egl;
    wl_egl_window* m_egl_window;
    wlr_egl_surface* m_egl_surface;
}