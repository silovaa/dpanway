module easel.canvas;

//import easel.rect;
import easel.affine;
import easel.color;
import easel.path;

import easel.cpp_bridge;
import easel.skia.sdk;
 
public import easel.cpp_bridge:Surface;
public import easel.skia.sdk:Rect, Point;

// extern(C++) struct CanvasPtr
// {
//     CanvasImpl      state;
//     PathBuilderImpl path_builder;
// }

// struct Surface
// {
//     private extern(C++) @nogc static SurfaceImpl make_egl_current(SurfaceImpl, int, int, int, int);
//     bool fromFramebuffer(int width, int height, int sample = 4, int stencil = 8) @nogc
//     {
//         m_impl = make_egl_current(m_impl, width, height, sample, stencil);
//         return m_impl !is null;
//     }

//     private extern(C++) @nogc static void destroy_surface(SurfaceImpl);
//     void destroy() @nogc
//     {
//         destroy_surface(impl); 
//         m_impl = null;
//     }

//     private extern(C++) @nogc static CanvasPtr get_canvas(SurfaceImpl);
//     Canvas canvas() @nogc
//     {
//         auto ptr = get_canvas(impl);
//         return Canvas(ptr.state, ptr.path_builder);
//     } 

//     extern(C++) @nogc static void flush_and_submit(SurfaceImpl);
//     void flush() @nogc {flush_and_submit(impl);}

//     private extern(C++) @nogc static int width(SurfaceImpl);
//     int width() @nogc {return width(impl);}
//     private extern(C++) @nogc static int height(SurfaceImpl);
//     int height() @nogc {return height(impl);}

//     private SurfaceImpl impl() @nogc
//     {
//         assert(m_impl !is null, "Surface no configured");
//         return m_impl;
//     } 
//     private SurfaceImpl m_impl;
// }

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

enum Composite_op: int {
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

    this(Point[2] p, Color[] c, float[] o) @nogc
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

    this(Point p, float r, Color[] c, float[] o) @nogc
    {
        center = p;
        radius = r;
        color  = c;
        offset = o;
    }
}

struct Canvas
{
    this(Surface surf) @nogc
    {
        auto ptr = surf.canvas;
        m_canvas_api.impl = ptr.state;
        m_builder = PathBuilderInternal(ptr.path_builder);
    }

    alias m_canvas_api this;

    ///////////////////////////////////////////////////////////////////////////////////
    // State

    void beginPath() @nogc {m_builder.reset();}

    // private extern(C++) @nogc static void cpp_clip(StateCanvas*, const ref Path);
    // void clip(in Path p) @nogc
    // {
    //     cpp_clip(impl, p);
    // }
    void clip() @nogc {m_canvas_api.clip(m_builder.path);}
    
    // private extern(C++) @nogc static void cpp_fill(StateCanvas*, const ref Path);
    // void fill(in Path p) @nogc
    // {
    //     cpp_fill(impl, p);
    // }
    void fill() @nogc {m_canvas_api.fill(m_builder.path);}

    // private extern(C++) @nogc static void cpp_stroke(StateCanvas*, const ref Path);
    // void stroke(in Path p) @nogc
    // {
    //     cpp_stroke(impl, p);
    // }
    void stroke() @nogc {m_canvas_api.stroke(m_builder.path);}

    // private extern(C++) @nogc static Rect cpp_clip_extent(StateCanvas*); 
    // Rect clip_extent() @nogc {return cpp_clip_extent(impl);}

    ///////////////////////////////////////////////////////////////////////////////////
    // Styles

    // private extern(C++) @nogc static void cpp_fill_linear(StateCanvas* h, 
    //                                             const(Point)* pts, 
    //                                             const(Color)* colors, 
    //                                             const(float)* offsets, 
    //                                             size_t count);
    @property void fillStyle(in LinearGradient gr) @nogc
    {
        assert(gr.offset.length == 0 || 
            gr.color.length == gr.offset.length, "Gradient offsets must match colors count");

        // Если offset пуст, .ptr может вернуть мусор, поэтому используем тернарный оператор
        fill_linear(
            gr.pts.ptr, 
            cast(const(ColorImpl)*)gr.color.ptr, 
            gr.offset.length ? gr.offset.ptr : null, 
            gr.color.length
        );
    }

    // private extern(C++) @nogc static void cpp_stroke_linear(StateCanvas* h, 
    //                                             const(Point)* pts, 
    //                                             const(Color)* colors, 
    //                                             const(float)* offsets, 
    //                                             size_t count);
    @property void strokeStyle(in LinearGradient gr) @nogc
    {
        assert(gr.offset.length == 0 || 
            gr.color.length == gr.offset.length, "Gradient offsets must match colors count");

        stroke_linear( 
            gr.pts.ptr, 
            cast(const(ColorImpl)*)gr.color.ptr, 
            gr.offset.length ? gr.offset.ptr : null, 
            gr.color.length
        );
    }

    // private extern(C++) @nogc static void cpp_fill_radial(StateCanvas* h, 
    //                                             const(Point) pts, float radius,
    //                                             const(Color)* colors, 
    //                                             const(float)* offsets, 
    //                                             size_t count);
    @property void fillStyle(in RadialGradient gr) @nogc
    {
        assert(gr.offset.length == 0 || 
            gr.color.length == gr.offset.length, "Gradient offsets must match colors count");

        fill_radial( 
            gr.center, gr.radius,
            cast(const(ColorImpl)*)gr.color.ptr, 
            gr.offset.length ? gr.offset.ptr : null, 
            gr.color.length
        );
    }

    // private extern(C++) @nogc static void cpp_stroke_radial(StateCanvas* h, 
    //                                             const(Point) pts, float radius,
    //                                             const(Color)* colors, 
    //                                             const(float)* offsets, 
    //                                             size_t count);
    @property void strokeStyle(in RadialGradient gr) @nogc
    {
        assert(gr.offset.length == 0 || 
            gr.color.length == gr.offset.length, "Gradient offsets must match colors count");

        stroke_radial( 
            gr.center, gr.radius,
            cast(const(ColorImpl)*)gr.color.ptr, 
            gr.offset.length ? gr.offset.ptr : null, 
            gr.color.length
        );
    }

    @property void fillStyle(in Color c) @nogc
    { fill_style(c); }

    @property void strokeStyle(in Color c) @nogc
    { stroke_style(c);}

    @property void lineWidth(float w) @nogc
    { line_width(w);}

    @property void lineCap(Cap cap) @nogc
    { line_cap(cast(int) cap);}

    @property void lineJoin(Join join) @nogc
    { line_join(cast(int) join);}

    @property void miterLimit(float m) @nogc
    { miter_limit(m); }

    @property void globalCompositeOp(Composite_op op) @nogc
    { global_composite_op(cast(int) op);}
    
    import std.functional : forward;
    auto ref opDispatch(string name, Args...)(auto ref Args args)
    if (__traits(hasMember, PathBuilderInternal, name)) // Переносим проверку в constraint
    {
        import std.functional : forward;
        // Используем mixin или getMember для вызова
        return __traits(getMember, m_builder, name)(forward!args);
    }

private: 
    PathBuilderInternal m_builder;
    CppCanvas m_canvas_api;
}

// private:        

// mixin template CanvasApi(ImplType) {
//     mixin ImplAccessor!ImplType;
//     // Хелпер для void методов (для краткости)
//     mixin template Void(string name, Args...) {
//         mixin ApiMethod!(ImplType, void, name, Args);
//     }

//     // Хелпер для Setter (@property)
//     mixin template Set(string name, T) {
//         mixin ApiSetter!(ImplType, name, T);
//     }

//     mixin template Prop(string name, T) {
//         mixin ApiProperty!(ImplType, name, T);
//     }

//     ///////////////////////////////////////////////////////////////////////////////////
//     // Transforms
//     mixin Void!("translate", float , float); 
//     mixin Void!("rotate", float); 
//     mixin Void!("scale", float , float);
//     mixin Void!("skew", double, double);

//     mixin Prop!("transform", AffineTransform);

//     ///////////////////////////////////////////////////////////////////////////////////
//     // State
//     mixin Void!("save");
//     mixin Void!("restore");
//     mixin Void!("clip", Path);
//     mixin Void!("fill", Path);
//     mixin Void!("stroke", Path);

//     ///////////////////////////////////////////////////////////////////////////////////
//     // Styles
//     mixin Set!("fill_style", Color);
//     mixin Set!("stroke_style", Color);

//     mixin Set!("line_width", float);
//     mixin Set!("line_cap", Cap);
//     mixin Set!("line_join", Join);
//     mixin Set!("miter_limit", float);
//     mixin Set!("global_composite_op", Composite_op);

//     ///////////////////////////////////////////////////////////////////////////////////
//     // Rectangles
//     mixin Void!("fill_rect", Rect) ;
//     mixin Void!("fill_round_rect", Rect, float);
//     mixin Void!("stroke_rect", Rect);
//     mixin Void!("stroke_round_rect", Rect, float);

//     ///////////////////////////////////////////////////////////////////////////////////
//     // Text
// }