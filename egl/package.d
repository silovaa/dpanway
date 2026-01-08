module egl;

public import egl_import;

import std.exception;
import std.typecons: Tuple, tuple;

struct Context
{
    Tuple!(int, int) initialize(EGLenum platform, 
                                void* native_display, 
                                const(EGLint)* attrib_list = null)
    {
        auto eglGetPlatformDisplayEXT =
            cast(PFNEGLGETPLATFORMDISPLAYEXTPROC)eglGetProcAddress("eglGetPlatformDisplayEXT");
        enforce(eglGetPlatformDisplayEXT, "eglGetPlatformDisplayEXT not supported");

        m_Display = eglGetPlatformDisplayEXT(platform, native_display, attrib_list);
        enforce(m_Display != EGL_NO_DISPLAY, "Could not create egl display");

        EGLint majorVersion;
        EGLint minorVersion;
        enforce(eglInitialize(m_Display, &majorVersion, &minorVersion) == 0, 
                "Could not initialize display");
            
        return tuple(majorVersion, minorVersion);
    }

    @disable this(this);

    ~this()
    {
        
        if (EGL_NO_DISPLAY != m_Display) 
            eglTerminate(m_Display);
    }

private:
    EGLDisplay m_display;
    EGLContext m_context;
    EGLSurface m_surface;
}