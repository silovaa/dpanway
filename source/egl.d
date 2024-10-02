module egl;

import wayland;

struct EglState
{
    void create(wl_display* display)
    {
        import core.stdc.string: strstr;

        auto client_exts_str =
		    eglQueryString(EGL_NO_DISPLAY, EGL_EXTENSIONS);
            
	    if (client_exts_str == null) {
		    if (eglGetError() == EGL_BAD_DISPLAY) 
			    throw new Exception("EGL_EXT_client_extensions not supported");
		    else 
			    throw new Exception("Failed to query EGL client extensions");  
	    }

        if (!strstr(client_exts_str, "EGL_EXT_platform_base")) 
            throw new Exception("EGL_EXT_platform_base not supported");

        if (!strstr(client_exts_str, "EGL_EXT_platform_wayland")) 
            throw new Exception("EGL_EXT_platform_wayland not supported");

        eglGetPlatformDisplayEXT =
                        enforce(eglGetProcAddress("eglGetPlatformDisplayEXT"),
                            "Failed to get eglGetPlatformDisplayEXT\n");

        eglCreatePlatformWindowSurfaceEXT = 
                        enforce(eglGetProcAddress("eglCreatePlatformWindowSurfaceEXT"),
                            "Failed to get eglCreatePlatformWindowSurfaceEXT\n");

        scope(failure) {
            eglMakeCurrent(EGL_NO_DISPLAY, EGL_NO_SURFACE,
                        EGL_NO_SURFACE, EGL_NO_CONTEXT);
            if (m_egl_display) {
                eglTerminate(m_egl_display);
            }
            eglReleaseThread();
        }
        
        m_egl_display = enforce(
            eglGetPlatformDisplayEXT(EGL_PLATFORM_WAYLAND_EXT, display, null) != EGL_NO_DISPLAY,
            "Failed to create EGL display\n");

        enforce(eglInitialize(m_egl_display, null, null) != EGL_FALSE,
                "Failed to initialize EGL");
 
        EGLint matched = 0;
        enforce(eglChooseConfig(m_egl_display, m_config_attribs,
                                &m_egl_config, 1, &matched), 
                "eglChooseConfig failed");
     
        enforce(matched, 
                "Failed to match an EGL config");

        m_egl_context =
            enforce(eglCreateContext(m_egl_display, m_egl_config,
                                    EGL_NO_CONTEXT, m_context_attribs) != EGL_NO_CONTEXT,
                    "Failed to create EGL context\n");
    }

    Wl_proxy* createSurface(void* egl_window)
    {
        auto res = eglCreatePlatformWindowSurfaceEXT(
		                m_egl_display, m_egl_config, egl_window, null);

	    assert(res != EGL_NO_SURFACE);//--???

        return res;
    }

    void destroySurface(Wl_proxy* surface)
    {
        eglDestroySurface(m_egl_display, surface);
    }

    void makeCurrent(Wl_proxy* surface)
    {
        eglMakeCurrent(m_egl_display, surface, surface, m_egl_context);
    }

    void swapBuffers(Wl_proxy* surface)
    {
        eglSwapBuffers(m_egl_display, surface);
    }

    ~this()
    {
        eglMakeCurrent(egl_display, EGL_NO_SURFACE,
		            EGL_NO_SURFACE, EGL_NO_CONTEXT);
	    eglDestroyContext(egl_display, egl_context);
	    eglTerminate(egl_display);
	    eglReleaseThread();
    }

private:
    EGLDisplay m_egl_display;
    EGLConfig  m_egl_config;
    EGLContext m_egl_context;

    PFNEGLGETPLATFORMDISPLAYEXTPROC eglGetPlatformDisplayEXT;
    PFNEGLCREATEPLATFORMWINDOWSURFACEEXTPROC eglCreatePlatformWindowSurfaceEXT;

    const EGLint m_config_attribs[] = {
        EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
        EGL_RED_SIZE, 1,
        EGL_GREEN_SIZE, 1,
        EGL_BLUE_SIZE, 1,
        EGL_ALPHA_SIZE, 1,
        EGL_RENDERABLE_TYPE, EGL_OPENGL_ES2_BIT,
        EGL_NONE,
    };

    const EGLint m_context_attribs[] = {
        EGL_CONTEXT_CLIENT_VERSION, 2,
        EGL_NONE,
    };
}

extern(C) {

}