module easel.canvas;

import easel.rect;
import easel.affine;
import easel.color;

import easel.skia.sdk;

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

    private extern(C++) static CanvasImpl get_canvas(SurfaceImpl);
    Canvas canvas(){return Canvas(get_canvas(impl));}

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
    this(CanvasImpl cpp_canvas){m_impl = cpp_canvas;}
    
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
    // mixin VoidMethod!("begin_path");
    // mixin VoidMethod!("close_path");
    //mixin VoidMethod!("fill_preserve");
    //mixin VoidMethod!("stroke_preserve");
    //mixin VoidMethod!("clip");

    private extern(C++) static void clip(StateCanvas*, SkPathBuilder*);
    void clip(ref Path p){clip(impl, p.impl);}

    private extern(C++) static Rect clip_extent(StateCanvas*); 
    Rect clip_extent(){return clip_extent(impl);}

    private extern(C++) static void fill(StateCanvas*, SkPathBuilder*);
    void fill(ref Path p){fill(impl, p.impl);}

    private extern(C++) static void fill_preserve(StateCanvas*, SkPathBuilder*);
    void fill_preserve(const ref Path p){fill_preserve(impl, p.impl);}

    private extern(C++) static void stroke(StateCanvas*, SkPathBuilder*);
    void stroke(ref Path p){stroke(impl, p.impl);}

    private extern(C++) static void stroke_preserve(StateCanvas*, SkPathBuilder*);
    void stroke_preserve(const ref Path p){stroke_preserve(impl, p.impl);}

    private CanvasImpl impl() @nogc
    {
        assert(m_impl !is null, "Canvas is null");
        return m_impl;
    }
    private CanvasImpl m_impl;
}
