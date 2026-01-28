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
    mixin VoidMethod!("begin_path");
    mixin VoidMethod!("close_path");
    mixin VoidMethod!("fill_preserve");
    mixin VoidMethod!("stroke_preserve");
    mixin VoidMethod!("clip");
 
    void fill(){fill_preserve(); begin_path();}

    private extern(C++) static Rect clip_extent(StateCanvas *cnv);
    Rect clip_extent(){return clip_extent(impl);}

    mixin BoolMethod!("point_in_path", Point);
    mixin VoidMethod!("move_to", Point);
    mixin VoidMethod!("line_to", Point);
    mixin VoidMethod!("arc_to", Point, Point, float);
    mixin VoidMethod!("arc", Point, float, float, float, bool);

   
    mixin VoidMethod!("add_rect", float, float, float, float);
    mixin VoidMethod!("add_circle", float, float, float);
    mixin VoidMethod!("clear_rect", float, float, float, float);
    mixin VoidMethod!("quadratic_curve_to", float, float, float, float);
    mixin VoidMethod!("bezier_curve_to", float, float, float, float, float, float);

    
    mixin VoidMethod!("fill_style", float, float, float, float);
    mixin VoidMethod!("stroke_style", float, float, float, float);
    mixin VoidMethod!("line_width", float); 

    //void add_rect(Rect rec) @nogc {this.add_rect(impl, rec.left, rec.top, rec.right, rec.bottom);}
    //void fill_style(Color c) @nogc {this.fill_style(impl, c.red, c.green, c.blue, c.alpha);}

    private CanvasImpl impl() @nogc
    {
        assert(m_impl !is null, "Canvas is null");
        return m_impl;
    }
    private CanvasImpl m_impl;
}
