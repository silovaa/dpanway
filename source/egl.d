module egl;

import std.exception;

struct EglWaylandClient
{
    void create(void* display)
    {
        if (m_egl_display) return;

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

        auto getDisplayFunc = cast(PFNEGLGETPLATFORMDISPLAYEXTPROC)
                                eglGetProcAddress("eglGetPlatformDisplayEXT");
        if (!getDisplayFunc) throw new Exception("Failed to get eglGetPlatformDisplayEXT");

        createWindowSurfaceFunc = cast(PFNEGLCREATEPLATFORMWINDOWSURFACEEXTPROC)
                        enforce(eglGetProcAddress("eglCreatePlatformWindowSurfaceEXT"),
                            "Failed to get eglCreatePlatformWindowSurfaceEXT");

        m_egl_display = getDisplayFunc(EGL_PLATFORM_WAYLAND_EXT, display, null);
        if (m_egl_display == EGL_NO_DISPLAY)
            throw new Exception("Failed to create EGL display");

        enforce(eglInitialize(m_egl_display, null, null) != EGL_FALSE,
                "Failed to initialize EGL");
 
        EGLint matched = 0;
        enforce(eglChooseConfig(m_egl_display, m_config_attribs.ptr,
                                &m_egl_config, 1, &matched), 
                "eglChooseConfig failed");
     
        enforce(matched, 
                "Failed to match an EGL config");

        m_egl_context = eglCreateContext(m_egl_display, m_egl_config,
                                    EGL_NO_CONTEXT, m_context_attribs.ptr);
        if (m_egl_context == EGL_NO_CONTEXT) 
            throw new Exception("Failed to create EGL context");
    }

    void createSurface(void* egl_window) nothrow
    {
        assert(m_egl_surface == EGL_NO_SURFACE);//--???

        m_egl_surface = createWindowSurfaceFunc(
		                m_egl_display, m_egl_config, egl_window, null);

	    assert(m_egl_surface != EGL_NO_SURFACE);//--???
    }

    void destroySurface() nothrow
    {
        eglDestroySurface(m_egl_display, m_egl_surface);
        m_egl_surface = EGL_NO_SURFACE;
    }

    void makeCurrent() nothrow
    {
        eglMakeCurrent(m_egl_display, m_egl_surface, m_egl_surface, m_egl_context);
    }

    void swapBuffers() nothrow
    {
        eglSwapBuffers(m_egl_display, m_egl_surface);
    }

    ~this()
    {
        if (m_egl_display) {
            eglMakeCurrent(m_egl_display, EGL_NO_SURFACE,
		                   EGL_NO_SURFACE, EGL_NO_CONTEXT);
            if (m_egl_surface)
                eglDestroySurface(m_egl_display, m_egl_surface);
            if (m_egl_context)
	            eglDestroyContext(m_egl_display, m_egl_context);
	        eglTerminate(m_egl_display); 
        }
        else 
            eglMakeCurrent(EGL_NO_DISPLAY, EGL_NO_SURFACE,
                           EGL_NO_SURFACE, EGL_NO_CONTEXT);
        
	    eglReleaseThread();
    }

private:
    EGLDisplay m_egl_display;
    EGLConfig  m_egl_config;
    EGLContext m_egl_context;
    EGLSurface m_egl_surface;

    const(EGLint[]) m_config_attribs = [
        EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
        EGL_RED_SIZE, 1,
        EGL_GREEN_SIZE, 1,
        EGL_BLUE_SIZE, 1,
        EGL_ALPHA_SIZE, 1,
        EGL_RENDERABLE_TYPE, EGL_OPENGL_ES2_BIT,
        EGL_NONE
    ];

    const(EGLint[]) m_context_attribs = [
        EGL_CONTEXT_CLIENT_VERSION, 2,
        EGL_NONE
    ];

    PFNEGLCREATEPLATFORMWINDOWSURFACEEXTPROC createWindowSurfaceFunc;
}

//EGL_VERSION_1_0
enum EGLDisplay EGL_NO_DISPLAY = null;
enum EGLSurface EGL_NO_SURFACE = null;
enum EGLContext EGL_NO_CONTEXT = null;

enum uint EGL_FALSE = 0;
enum uint EGL_WINDOW_BIT           = 0x0004;
enum uint EGL_BAD_DISPLAY          = 0x3008;
enum uint EGL_ALPHA_SIZE           = 0x3021;
enum uint EGL_BLUE_SIZE            = 0x3022;
enum uint EGL_GREEN_SIZE           = 0x3023;
enum uint EGL_RED_SIZE             = 0x3024;
enum uint EGL_SURFACE_TYPE         = 0x3033;
enum uint EGL_NONE                 = 0x3038;
enum uint EGL_RENDERABLE_TYPE      = 0x3040;
enum uint EGL_EXTENSIONS           = 0x3055;
enum uint EGL_PLATFORM_WAYLAND_EXT = 0x31D8;

//EGL_VERSION_1_3
enum uint EGL_OPENGL_ES2_BIT         = 0x0004;
enum uint EGL_CONTEXT_CLIENT_VERSION = 0x3098;

alias EGLenum = uint;
alias EGLint = uint;
alias EGLBoolean = uint;
alias EGLDisplay = void*;
alias EGLConfig  = void*;
alias EGLContext = void*;
alias EGLSurface = void*;

extern(C) nothrow {

    alias PFNEGLGETPLATFORMDISPLAYEXTPROC = 
        void* function (EGLenum platform, 
                        void* native_display, 
                        const(EGLint*) attrib_list);
    alias PFNEGLCREATEPLATFORMWINDOWSURFACEEXTPROC = 
        void* function (EGLDisplay dpy,
                        EGLConfig config, 
                        void* native_window, 
                        const(EGLint*) attrib_list);

    void* eglGetProcAddress(const(char*));
    const(char*) eglQueryString(EGLDisplay dpy, EGLint name);
    EGLint eglGetError();
    EGLBoolean eglMakeCurrent(EGLDisplay dpy, EGLSurface draw, EGLSurface read, EGLContext ctx);
    EGLBoolean eglTerminate(EGLDisplay dpy);
    EGLBoolean eglReleaseThread();
    EGLBoolean eglInitialize(EGLDisplay dpy, EGLint *major, EGLint *minor);
    EGLBoolean eglChooseConfig(EGLDisplay dpy, const(EGLint*) attrib_list, 
                            EGLConfig* configs, EGLint config_size, 
                            EGLint* num_config);
    EGLContext eglCreateContext(EGLDisplay dpy, EGLConfig config, 
                                EGLContext share_context, const(EGLint*) attrib_list);
    EGLBoolean eglDestroySurface(EGLDisplay dpy, EGLSurface surface);
    EGLBoolean eglSwapBuffers (EGLDisplay dpy, EGLSurface surface);
    EGLBoolean eglDestroyContext (EGLDisplay dpy, EGLContext ctx);
}