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

    static EGLDisplay c_ptr()
    {
        assert (m_display != EGL_NO_DISPLAY, "m_display is not initialized");
        return m_display;
    }

    static EGLConfig chooseConfig(const(uint)[] configAttribs)
    {
        EGLint numConfigs;
        EGLConfig config;

        enforce(eglChooseConfig(c_ptr(), configAttribs.ptr, &config, 1, &numConfigs) == 0,
                "Could not create choose config!");

        return config;
    }

    static EGLContext createContext(EGLConfig cfg, const(uint)[] contextAttribs)
    {
        return enforse(eglCreateContext(c_ptr, cfg, null, contextAttribs.ptr),
                     "Could not create context!");
    }

    static EGLSurface createWindowSurface(EGLConfig cfg, void* native_window)
    {

    }

private:
    static EGLDisplay m_display = EGL_NO_DISPLAY;

    //static Display s_inst;
}

struct ContextExt(string tag)
{
    this(EGLConfig cfg, const(uint)[] contextAttribs)
    {
        m_context = eglCreateContext(DisplayExt!tag.get(), cfg, nullptr, contextAttribs.ptr);
        enforse(m_context, "Could not create context!");
    }

    @disable this(this);

    ~this()
    {
        eglDestroyContext(DisplayExt!tag.get(), m_EGLContext);
    }

private:
    EGLContext m_context;
}

alias Display = DisplayExt!null;
alias Context = Context!null;

struct Surface
{

private:
    EGLSurface m_surface;
}