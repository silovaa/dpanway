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
    bool fromFramebuffer(int width, int height, int sample = 4, int stencil = 8) @nogc
    {
        m_impl = make_egl_current(m_impl, width, height, sample, stencil);
        return m_impl !is null;
    }

    private extern(C++) static void destroy_surface(SurfaceImpl);
    void destroy() @nogc
    {
        destroy_surface(impl); 
        m_impl = null;
    }

    private extern(C++) static CanvasPtr get_canvas(SurfaceImpl);
    Canvas canvas() @nogc
    {
        auto ptr = get_canvas(impl);
        return Canvas(ptr.state, ptr.path_builder);
    }

    extern(C++) static void flush_and_submit(SurfaceImpl);
    void flush() @nogc {flush_and_submit(impl);}

    private extern(C++) static int width(SurfaceImpl);
    int width() @nogc {return width(impl);}
    private extern(C++) static int height(SurfaceImpl);
    int height() @nogc {return height(impl);}

    private SurfaceImpl impl() @nogc
    {
        assert(m_impl !is null, "Surface no configured");
        return m_impl;
    } 
    private SurfaceImpl m_impl;
}

enum Cap: int {
    kButt,                  //!< no stroke extension
    kRound,                 //!< adds circle
    kSquare,                //!< adds square
    kLast    = kSquare,     //!< largest Cap value
    kDefault = kButt        //!< equivalent to kButt_Cap
}

enum Join : int {
    kMiter,                 //!< extends to miter limit
    kRound,                 //!< adds circle
    kBevel,                 //!< connects outside edges
    kLast    = kBevel,      //!< equivalent to the largest value for Join
    kDefault = kMiter       //!< equivalent to kMiter_Join
}

enum Composite_op
{
    source_over,
    source_atop,
    source_in,
    source_out,

    destination_over,
    destination_atop,
    destination_in,
    destination_out,

    lighter,
    darker,
    copy,
    xor_,

    difference,
    exclusion,
    multiply,
    screen,

    color_dodge,
    color_burn,
    soft_light,
    hard_light,

    hue,
    saturation,
    color_op,
    luminosity
}

struct Gradient
{
    Color[] color;
    float[] offset;
}

struct LinearGradient
{
    Point[2] pts;
    Gradient gradient;

    alias gradient this;

    this(Point[2] p, Color[] c, float[] o)
    {
        pts = p;
        color = c;
        offset = o;
    }
}

struct RadialGradient
{
    Point center;
    float radius;
    Gradient gradient;

    alias gradient this;

    this(Point p, float r, Color[] c, float[] o)
    {
        pts = p;
        color = c;
        offset = o;
    }
}

struct Canvas
{
    alias m_builder this;

    ///////////////////////////////////////////////////////////////////////////////////
    // State

    void beginPath(){m_builder.reset();}
    void clip(){clip(m_builder.path);}
    void fill(){fill(m_builder.path);}
    void stroke(){stroke(m_builder.path);}

    private extern(C++) static Rect cpp_clip_extent(StateCanvas*); 
    Rect clip_extent(){return clip_extent(impl);}

    ///////////////////////////////////////////////////////////////////////////////////
    // Styles

    private extern(C++) static void cpp_fill_linear(StateCanvas* h, 
                                                const(Point)* pts, 
                                                const(Color)* colors, 
                                                const(float)* offsets, 
                                                size_t count);
    @property void fill_style(in LinearGradient gr)
    {
        assert(gr.offset.length == 0 || 
            gr.color.length == gr.offset.length, "Gradient offsets must match colors count");

        // Если offset пуст, .ptr может вернуть мусор, поэтому используем тернарный оператор
        cpp_fill_linear(
            this.impl, 
            gr.pts.ptr, 
            gr.color.ptr, 
            gr.offset.length ? gr.offset.ptr : null, 
            gr.color.length
        );
    }

    private extern(C++) static void cpp_stroke_linear(StateCanvas* h, 
                                                const(Point)* pts, 
                                                const(Color)* colors, 
                                                const(float)* offsets, 
                                                size_t count);
    @property void stroke_style(in LinearGradient gr)
    {
        assert(gr.offset.length == 0 || 
            gr.color.length == gr.offset.length, "Gradient offsets must match colors count");

        cpp_stroke_linear(
            this.impl, 
            gr.pts.ptr, 
            gr.color.ptr, 
            gr.offset.length ? gr.offset.ptr : null, 
            gr.color.length
        );
    }

    private extern(C++) static void cpp_fill_radial(StateCanvas* h, 
                                                const(Point) pts, float radius,
                                                const(Color)* colors, 
                                                const(float)* offsets, 
                                                size_t count);
    @property void fill_style(in RadialGradient gr)
    {
        assert(gr.offset.length == 0 || 
            gr.color.length == gr.offset.length, "Gradient offsets must match colors count");

        cpp_fill_radial(
            this.impl, 
            gr.pts, gr.radius,
            gr.color.ptr, 
            gr.offset.length ? gr.offset.ptr : null, 
            gr.color.length
        );
    }

    private extern(C++) static void cpp_stroke_radial(StateCanvas* h, 
                                                const(Point) pts, float radius,
                                                const(Color)* colors, 
                                                const(float)* offsets, 
                                                size_t count);
    @property void stroke_style(in RadialGradient gr)
    {
        assert(gr.offset.length == 0 || 
            gr.color.length == gr.offset.length, "Gradient offsets must match colors count");

        cpp_stroke_radial(
            this.impl, 
            gr.pts, gr.radius,
            gr.color.ptr, 
            gr.offset.length ? gr.offset.ptr : null, 
            gr.color.length
        );
    }

    mixin CanvasApi!CanvasImpl;

private: 
    PathBuilderInternal m_builder;

    this(CanvasImpl state, PathBuilderImpl path_builder)
    {
        m_impl = state;
        m_builder = PathBuilderInternal(path_builder);
    }
}

private:

mixin template CanvasApi(ImplType) {
    mixin ImplAccessor!ImplType;
    // Хелпер для void методов (для краткости)
    mixin template Void(string name, Args...) {
        mixin ApiMethod!(ImplType, void, name, Args);
    }

    // Хелпер для Setter (@property)
    mixin template Set(string name, T) {
        mixin ApiSetter!(ImplType, name, T);
    }

    mixin template Prop(string name, T) {
        mixin ApiProperty!(ImplType, name, T);
    }

    ///////////////////////////////////////////////////////////////////////////////////
    // Transforms
    mixin Void!("translate", float , float); 
    mixin Void!("rotate", float); 
    mixin Void!("scale", float , float);
    mixin Void!("skew", double, double);

    mixin Prop!("transform", AffineTransform);

    ///////////////////////////////////////////////////////////////////////////////////
    // State
    mixin Void!("save");
    mixin Void!("restore");
    mixin Void!("clip", Path);
    mixin Void!("fill", Path);
    mixin Void!("stroke", Path);

    ///////////////////////////////////////////////////////////////////////////////////
    // Styles
    mixin Set!("fill_style", Color);
    mixin Set!("stroke_style", Color);

    mixin Set!("line_width", float);
    mixin Set!("line_cap", Cap);
    mixin Set!("line_join", Join);
    mixin Set!("miter_limit", float);
    mixin Set!("global_composite_op", Composite_op);

    ///////////////////////////////////////////////////////////////////////////////////
    // Rectangles
    mixin Void!("fill_rect", Rect) ;
    mixin Void!("fill_round_rect", Rect, float);
    mixin Void!("stroke_rect", Rect);
    mixin Void!("stroke_round_rect", Rect, float);

    ///////////////////////////////////////////////////////////////////////////////////
    // Text
}