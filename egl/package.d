module egl;

public import egl_import;

import std.exception;
import std.typecons: Tuple, tuple;

struct DisplayExt(string tag)
{
    static Tuple!(int, int) initialize(EGLenum platform, 
                                void* native_display, 
                                const(EGLint)* attrib_list = null)
    {
        assert(m_display == EGL_NO_DISPLAY, "m_display is already initialized");

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

    static void terminate() nothrow @nogc
    {
        if (EGL_NO_DISPLAY != m_Display) 
            eglTerminate(m_Display);
    }

private:
    static EGLDisplay m_display = EGL_NO_DISPLAY;

    //static Display s_inst;
}

alias Display = DisplayExt!null;

struct Context
{
    this(string tag)(const(uint)[] configAttribs, const(uint)[] contextAttribs)
    {
        config(DisplayExt!tag.m_display, configAttribs, contextAttribs);    
    }

    this(const(uint)[] configAttribs, const(uint)[] contextAttribs)
    {
        config(Display.m_display, configAttribs, contextAttribs);
    }

    @disable this(this);

    ~this()
    {
        
    }

private:
    EGLContext m_context;
    EGLSurface m_surface;

    void config(EGLDisplay dpy, const(uint)[] configAttribs, const(uint)[] contextAttribs)
    {

    }
}

struct Config
{
    this(string tag)(const(uint)[] configAttribs)
    {
        construct(DisplayExt!tag.m_display, configAttribs);    
    }

    this(const(uint)[] configAttribs)
    {
        construct(Display.m_display, configAttribs);
    }

private:
    EGLConfig m_config;

    void construct(EGLDisplay dpy, const(uint)[] configAttribs)
    {
        EGLint numConfigs;
        enforce(eglChooseConfig(dpy, configAttribs.ptr, &m_config, 1, &numConfigs) == 0,
                "Could not create choose config!");
    }
}