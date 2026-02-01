module easel.canvas;

import easel.rect;
import easel.affine;
import easel.color;

import easel.skia.sdk;

extern(C++) struct CanvasPtr
{
    CanvasImpl      state;
    PathBuilderImpl path_builder;
}

struct Surface
{
    private extern(C++) static SurfaceImpl make_egl_current (SurfaceImpl, int, int, int, int);
    bool fromFramebuffer(int width, int height, int sample = 4, int stencil = 8)
    {
        m_impl = make_egl_current(m_impl, width, height, sample, stencil);
        return m_impl !is null;
    }

    private extern(C++) static void destroy_surface(SurfaceImpl);
    void destroy()
    {
        destroy_surface(impl); 
        m_impl = null;
    }

    private extern(C++) static CanvasPtr get_canvas(SurfaceImpl);
    Canvas canvas()
    {
        auto ptr = get_canvas(impl);
        return Canvas(ptr.state, ptr.path_builder);
    }

    extern(C++) static void flush_and_submit(SurfaceImpl);
    void flush(){flush_and_submit(impl);}

    private extern(C++) static int width(SurfaceImpl);
    int width()  {return width(impl);}
    private extern(C++) static int height(SurfaceImpl);
    int height() {return height(impl);}

    private SurfaceImpl impl() @nogc
    {
        assert(m_impl !is null, "Surface no configured");
        return m_impl;
    } 
    private SurfaceImpl m_impl;
}

struct Canvas
{
    this(CanvasImpl state, PathBuilderImpl path_builder)
    {
        m_impl = state;
        m_builder = PathBuilderInternal(path_builder);
    }

    alias m_builder this;
    
    ///////////////////////////////////////////////////////////////////////////////////
    // Transforms
    mixin VoidMethod!("translate", float , float); 
    mixin VoidMethod!("rotate", float); 
    mixin VoidMethod!("scale", float , float);
    mixin VoidMethod!("skew", double, double);

    private extern(C++) static void transform(StateCanvas *cnv, ref AffineTransform);
    private extern(C++) static void transform(StateCanvas *cnv, const ref AffineTransform);
    void transform(ref AffineTransform m){transform(impl, m);}
    void transform(const ref AffineTransform m){transform(impl, m);}

    mixin VoidMethod!("save");
    mixin VoidMethod!("restore");

    mixin Setter!("fill_style", Color);
    mixin Setter!("stroke_style", Color);
    mixin Setter!("line_width", float); 

    void beginPath(){m_builder.reset();}

    private extern(C++) static void cpp_clip(StateCanvas*, Path*);
    void clip(ref Path p){cpp_clip(impl, &p);}
    void clip(){clip(m_builder.path);}

    private extern(C++) static Rect cpp_clip_extent(StateCanvas*); 
    Rect clip_extent(){return clip_extent(impl);}

    private extern(C++) static void cpp_fill(StateCanvas*, Path*);
    void fill(ref Path p){fill(impl, &p);}
    void fill(){fill(m_builder.path);}

    private extern(C++) static void cpp_stroke(StateCanvas*, Path*);
    void stroke(ref Path p){stroke(impl, &p);}
    void stroke(){stroke(m_builder.path);}

private: 
    CanvasImpl impl() @nogc
    {
        assert(m_impl !is null, "Canvas is null");
        return m_impl;
    }

    CanvasImpl  m_impl;
    PathBuilderInternal m_builder;
}
