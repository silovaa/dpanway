module easel.canvas;

import easel.rect;
import easel.affine;

import easel.skia.sdk;

struct Canvas
{
    private extern(C++) static CanvasImpl make_canvas(int, int, int, int);
    void configure(int width, int height, int sample = 4, int stencil = 8) 
    {
        m_impl = make_canvas(width, height, sample, stencil);
        ensure(m_impl, "Internal backend error");
    }
    
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

    private inout CanvasImpl impl() inout
    {
        assert(m_impl !is null, "Canvas no configured");
        return m_impl;
    }
    private CanvasImpl m_impl;
}
