module egl;

public import egl_import;

import std.exception;
import std.typecons: Tuple, tuple;

struct DisplayTag(string tag)
{
    static Tuple!(int, int) initialize(EGLenum platform, 
                                void* native_display, 
                                const(int)[] attrib_list = null)
    {
        assert(m_display is null, "egl display is already initialized");

        auto eglGetPlatformDisplayEXT =
            cast(PFNEGLGETPLATFORMDISPLAYEXTPROC)eglGetProcAddress("eglGetPlatformDisplayEXT");
        enforce(eglGetPlatformDisplayEXT, "eglGetPlatformDisplayEXT not supported");

        m_display = eglGetPlatformDisplayEXT(platform, native_display, attrib_list.ptr);
        enforce(m_display !is null, "Could not create egl display");

        EGLint majorVersion;
        EGLint minorVersion;
        enforce(eglInitialize(m_display, &majorVersion, &minorVersion) != 0, 
                "Could not initialize display");
            
        return tuple(majorVersion, minorVersion);
    }

    static void terminate() 
    {
        if (m_display !is null){ 
            eglTerminate(m_display);
            m_display = null;
        }
    }

    static EGLDisplay c_ptr()
    {
        assert (m_display !is null, "egl display is not initialized");
        return m_display;
    }

    // static ref const(DisplayTag) instance()
    // {
    //     assert (s_inst.m_display !is null, "egl display is not initialized");
    //     return s_inst;
    // }

    static ~this() 
    { 
        if (m_display !is null)
            eglTerminate(m_display);
    }

    // EGLContext createContext(EGLConfig cfg, immutable int[] contextAttribs) const
    // {
    //     return enforce(eglCreateContext(m_display, cfg, null, contextAttribs.ptr),
    //                  "Could not create context!");
    // }

    // EGLSurface createWindowSurface(EGLConfig cfg, void* native_window) const
    // {
    //     return enforce(eglCreateWindowSurface(m_display, cfg, m_native, null), 
    //                 "Could not create surface!");
    // }

private:
    static EGLDisplay m_display;

    //static Display s_inst;
}

alias Display = DisplayTag!null;

// Display halpers ///////////////////////////////////////////////////////////////////////

/** 
 * ES3 context (since it is currently supported by most hardware and graphics libraries), 
 * uses the default display, which is managed separately (initialization, destruction), 
 * and is destroyed in the destructor (the lifetime should not be greater than the display)
 */
struct WindowContextES3
{
    this(void* native_window, uint sampleCount = 4, uint stencilSize = 8)
    {
        auto display = Display.c_ptr;

        immutable(EGLint)[] createConfigAttribs(uint sample, uint stencil) {
            return [
                EGL_RENDERABLE_TYPE,
                EGL_OPENGL_ES3_BIT,
                EGL_RED_SIZE, 8,
                EGL_GREEN_SIZE, 8,
                EGL_BLUE_SIZE, 8,
                EGL_ALPHA_SIZE, 8,
                EGL_STENCIL_SIZE, stencil,
                EGL_SAMPLE_BUFFERS, sample > 1 ? 1 : 0,
                EGL_SAMPLES, sample,
                EGL_NONE
            ];
        }

        auto configAttribs = createConfigAttribs(sampleCount, stencilSize);

        EGLint numConfigs;
        EGLConfig config;
        enforce(eglChooseConfig(display, configAttribs.ptr, &config, 1, &numConfigs) != 0,
                "Could not create choose config!");

        immutable EGLint[] contextAttribs = [
            EGL_CONTEXT_CLIENT_VERSION, 3, EGL_NONE];

        m_context = enforce(eglCreateContext(display, config, null, contextAttribs.ptr),
                            "Could not create context!");
        m_surface = enforce(eglCreateWindowSurface(display, config, native_window, null), 
                            "Could not create surface!");

        enforce(eglMakeCurrent(display, m_surface, m_surface, m_context) != 0, 
                "Could not make context current!");

        scope(failure) terminate();
    }

    @disable this(this);

    ~this()
    { terminate(); }

    void terminate() 
    {
        auto display = Display.c_ptr;
        if (m_context) eglDestroyContext(display, m_context);
        if (m_surface) eglDestroySurface(display, m_surface);
    }

    void swapBuffers() 
    {
        enforce(eglSwapBuffers(Display.c_ptr, m_surface), 
                "Could not complete eglSwapBuffers.");
    }

private:
    EGLContext m_context;
    EGLSurface m_surface;
}