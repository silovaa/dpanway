module wayland;

import core.sys.posix.poll: poll, pollfd, POLLIN, POLLOUT;
import std.exception;

enum EventT
{
    system,
    wayland,
    count
}

class WlState
{
    this()
    {
        m_display = enforce(wl_display_connect(), 
                            "failed to create display");
       
	    m_registry = wl_proxy_marshal_constructor(
                cast(wl_proxy*) m_display,
                WL_DISPLAY_GET_REGISTRY, wl_registry_interface, null);

        wl_proxy_add_listener(m_registry, cast(Callback*) &m_registry_listener, this);

	    if (wl_display_roundtrip(m_display) < 0) 
		    throw "wl_display_roundtrip() failed";

	    if (m_compositor is null) 
		    throw "compositor doesn't support wl_compositor";
		
	    if (m_shm is null)
		    throw "compositor doesn't support wl_shm";
	
        if (m_layer_shell is null) 
            throw "compositor doesn't support zwlr_layer_shell_v1";

        // Second roundtrip to get output metadata
        if (wl_display_roundtrip(m_display) < 0) 
            throw "wl_display_roundtrip() failed";
            
        // m_cursor.create(24);

        // egl init


        fds[EventT.system].fd = sfd;
		fds[EventT.system].events = POLLIN;

        fds[EventT.wayland].fd = wl_display_get_fd(m_display);
		fds[EventT.wayland].events = POLLIN;

    }

    ~this()
    {
        wl_proxy_destroy(m_layer_shell);
	    wl_proxy_destroy(m_compositor);
	    wl_proxy_destroy(m_shm);
	    wl_proxy_destroy(m_registry);
        wl_proxy_destroy(m_xdg_wm_base);
	    wl_display_disconnect(m_display);
    }

    void run()
    {
        isRuning = true;

        while (isRuning) {
            
            // Wayland requests can be generated while handling non-Wayland events.
            // We need to flush these.
            int ret = 0;
            do {
                ret = wl_display_dispatch_pending(m_display);
                if (wl_display_flush(m_display) < 0) 
                    throw "failed to flush Wayland events";
            } while (ret > 0);
            if (ret < 0) 
                throw "failed to dispatch pending Wayland events";
            
            if (poll(fds, EventT.count, -1) > 0) {

                if (fds[EventT.system].revents & POLLIN) 
			        break;
		    
                if (fds[EventT.wayland].revents & POLLIN) {
                    ret = wl_display_dispatch(m_display);
                    if (ret < 0) 
                        throw "failed to read Wayland events";    
                }
                if (fds[EventT.wayland].revents & POLLOUT) {
                    ret = wl_display_flush(m_display);
                    if (ret < 0) 
                        throw "failed to flush Wayland events";
                }
            }
            else throw "failed to poll(): ";
        }
    }

    Widget createWindow()
    {

    }

private:
    pollfd fds[EventT.count];
    bool isRuning = false;

    wl_display*    m_display;

	wl_proxy*   m_registry;
    wl_registry_listener m_registry_listener;

	wl_proxy* m_compositor;
	wl_proxy* m_shm;
	wl_proxy* m_layer_shell;
    wl_proxy* m_screen;
    wl_proxy* m_xdg_wm_base;

	//xdg_activation_v1 *m_xdg_activation;
	//struct wp_cursor_shape_manager_v1 *cursor_shape_manager;

    //Cursor m_cursor;
}

// struct Cursor
// {
// 	uint32_t size;
// 	uint32_t scale;
// 	wl_cursor_theme *theme;
// 	const wl_cursor_image *image;
// 	wl_surface *surface;

//     void create(uint req_size)
//     {
//         // Set up the cursor. It needs a wl_surface with the cursor loaded into it.
//         // If one of these fail, mako will work fine without the cursor being able to change.
//         const char *cursor_size_env = getenv("XCURSOR_SIZE");
        
//         if (cursor_size_env != NULL) {
//             errno = 0;
//             char *end;
//             int temp_size = (int)strtol(cursor_size_env, &end, 10);
//             if (errno == 0 && cursor_size_env[0] != 0 && end[0] == 0 && temp_size > 0) {
//                 cursor_size = temp_size;
//             } else {
//                 fprintf(stderr, "Error: XCURSOR_SIZE is invalid\n");
//             }
//         }

// 	    size = cursor_size;
//     }	
// }

struct EglState
{
    EGLDisplay egl_display;
    EGLConfig  egl_config;
    EGLContext egl_context;

    bool create(wl_display* display)
    {
        auto client_exts_str =
		    eglQueryString(EGL_NO_DISPLAY, EGL_EXTENSIONS);
            
	    if (client_exts_str == null) {
		    if (eglGetError() == EGL_BAD_DISPLAY) {
			    fprintf(stderr, "EGL_EXT_client_extensions not supported\n");
		    } else {
			    fprintf(stderr, "Failed to query EGL client extensions\n");
		    }

            return false;
	    }

        if (!strstr(client_exts_str, "EGL_EXT_platform_base")) {
            fprintf(stderr, "EGL_EXT_platform_base not supported\n");
            return false;
        }

        if (!strstr(client_exts_str, "EGL_EXT_platform_wayland")) {
            fprintf(stderr, "EGL_EXT_platform_wayland not supported\n");
            return false;
        }

        eglGetPlatformDisplayEXT =
            (void *)eglGetProcAddress("eglGetPlatformDisplayEXT");
        if (eglGetPlatformDisplayEXT == NULL) {
            fprintf(stderr, "Failed to get eglGetPlatformDisplayEXT\n");
            return false;
        }

        eglCreatePlatformWindowSurfaceEXT =
            (void *)eglGetProcAddress("eglCreatePlatformWindowSurfaceEXT");
        if (eglCreatePlatformWindowSurfaceEXT == NULL) {
            fprintf(stderr, "Failed to get eglCreatePlatformWindowSurfaceEXT\n");
            return false;
        }

        egl_display =
            eglGetPlatformDisplayEXT(EGL_PLATFORM_WAYLAND_EXT,
                display, NULL);
        if (egl_display == EGL_NO_DISPLAY) {
            fprintf(stderr, "Failed to create EGL display\n");
            goto error;
        }

        if (eglInitialize(egl_display, NULL, NULL) == EGL_FALSE) {
            fprintf(stderr, "Failed to initialize EGL\n");
            goto error;
        }

        EGLint matched = 0;
        if (!eglChooseConfig(egl_display, config_attribs,
                &egl_config, 1, &matched)) {
            fprintf(stderr, "eglChooseConfig failed\n");
            goto error;
        }
        if (matched == 0) {
            fprintf(stderr, "Failed to match an EGL config\n");
            goto error;
        }

        egl_context =
            eglCreateContext(egl_display, egl_config,
                EGL_NO_CONTEXT, context_attribs);
        if (egl_context == EGL_NO_CONTEXT) {
            fprintf(stderr, "Failed to create EGL context\n");
            goto error;
        }

        return true;

    error:
        eglMakeCurrent(EGL_NO_DISPLAY, EGL_NO_SURFACE,
                    EGL_NO_SURFACE, EGL_NO_CONTEXT);
        if (egl_display) {
            eglTerminate(egl_display);
        }
        eglReleaseThread();
        return false;
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

    PFNEGLGETPLATFORMDISPLAYEXTPROC eglGetPlatformDisplayEXT;
    PFNEGLCREATEPLATFORMWINDOWSURFACEEXTPROC eglCreatePlatformWindowSurfaceEXT;

    const EGLint config_attribs[] = {
        EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
        EGL_RED_SIZE, 1,
        EGL_GREEN_SIZE, 1,
        EGL_BLUE_SIZE, 1,
        EGL_ALPHA_SIZE, 1,
        EGL_RENDERABLE_TYPE, EGL_OPENGL_ES2_BIT,
        EGL_NONE,
    };

    const EGLint context_attribs[] = {
        EGL_CONTEXT_CLIENT_VERSION, 2,
        EGL_NONE,
    };
}

extern (C) {

    struct wl_display;
    // struct wl_registry;
    // struct wl_compositor;
    // struct wl_shm;
    // struct zwlr_layer_shell_v1;
    // struct xdg_activation_v1;

    struct wl_registry_listener
    {
        void function (void* data,
                       wl_registry* wl_registry,
                       uint name,
                       const(char)* iface,
                       uint ver) global = handle_global;
  
        void function (void *data,
                       wl_registry *wl_registry,
                       uint name) global_remove = handle_global_rem;
    }
    
    wl_display* wl_display_connect(const(char)* name = null);
    int wl_display_get_fd(wl_display*);
    int wl_display_dispatch(wl_display*);
    int wl_display_dispatch_pending(wl_display*);
    int wl_display_flush(wl_display*);
    int wl_display_roundtrip(wl_display*);

    enum uint WL_DISPLAY_SYNC = 0;
    enum uint WL_DISPLAY_GET_REGISTRY = 1;
    enum uint WL_REGISTRY_BIND = 0;
    
    struct wl_proxy;
    alias Callback = extern (C) void function();

    void wl_proxy_destroy(wl_proxy*);

    struct wl_interface;
    // struct wl_compositor_interface;
    // struct wl_shm_interface;
    // struct zwlr_layer_shell_v1_interface;
    // struct wl_seat_interface;
    // struct wl_output_interface;
    // struct xdg_activation_v1_interface;
    // struct wp_cursor_shape_manager_v1_interface;

    int wl_proxy_add_listener(wl_proxy*, Callback*, void* /*data*/);
    wl_proxy* wl_proxy_marshal_constructor(wl_proxy*, uint opcode,
                                           const(wl_interface*) iface, ...);


    void handle_global(void* data, wl_proxy* registry,
		               uint name, const(char)* interface, uint version) 
    {

	    auto state = cast(Window) data;

        if (strcmp(interface, wl_compositor_interface.name) == 0) {
            state.m_compositor = wl_proxy_marshal_constructor(registry, 
                                                            WL_REGISTRY_BIND, 
                                                            wl_compositor_interface, name, 
                                                            wl_compositor_interface.name, 
                                                            4, null);
        } else if (strcmp(interface, wl_shm_interface.name) == 0) {
            state.m_shm = wl_proxy_marshal_constructor(registry, 
                                                            WL_REGISTRY_BIND, 
                                                            wl_shm_interface, name, 
                                                            wl_shm_interface.name, 
                                                            1, null);
        } else if (strcmp(interface, zwlr_layer_shell_v1_interface.name) == 0) {
            state.layer_shell = wl_proxy_marshal_constructor(registry, 
                                                            WL_REGISTRY_BIND, 
                                                            zwlr_layer_shell_v1_interface, name, 
                                                            zwlr_layer_shell_v1_interface.name, 
                                                            4, null);
        } else if (strcmp(interface, wl_seat_interface.name) == 0) {
            // wl_seat* seat = wl_proxy_marshal_constructor(registry, 
            //                                                 WL_REGISTRY_BIND, 
            //                                                 wl_seat_interface, name, 
            //                                                 wl_seat_interface.name, 
            //                                                 3, null);
            // create_seat(state, seat);

            writeln("add seat name:", interface);

        } else if (strcmp(interface, wl_output_interface.name) == 0) {
            state.m_screen = wl_proxy_marshal_constructor(registry, 
                                                            WL_REGISTRY_BIND, 
                                                            wl_output_interface, name, 
                                                            wl_output_interface.name, 
                                                            4, null);

            writeln("add output name:", interface);

        } else if (strcmp(interface, xdg_wm_base_interface.name) == 0) {
            state.m_xdg_wm_base = wl_proxy_marshal_constructor(registry, 
                                                            WL_REGISTRY_BIND, 
                                                            xdg_wm_base_interface, name, 
                                                            xdg_wm_base_interface.name, 
                                                            1, null);
             writeln("add xdg_activation name:", interface);
        } else if (strcmp(interface, wp_cursor_shape_manager_v1_interface.name) == 0) {
            // state.cursor_shape_manager = wl_proxy_marshal_constructor(registry, 
            //                                                 WL_REGISTRY_BIND, 
            //                                                 wp_cursor_shape_manager_v1_interface, name, 
            //                                                 wp_cursor_shape_manager_v1_interface.name, 
            //                                                 1, null);
            writeln("add cursor_shape name:", interface);
        }
    }

    void handle_global_rem(void *data, wl_proxy *registry, uint name) 
    {
        writeln("handle_global_rem");
    }
}