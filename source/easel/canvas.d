module easel.canvas;

import easel.affine;
import easel.color;
import easel.path;

import easel.cpp_bridge;
import easel.skia.sdk;
 
public import easel.cpp_bridge:Surface;
public import easel.skia.sdk:Rect, Point;

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
@nogc:
    this(Surface surf) 
    {
        auto ptr = surf.canvas;
        m_canvas_api.impl = ptr.state;
        builder_data = PathBuilderData(ptr.path_builder);
    }

    CppCanvas m_canvas_api;
    alias m_canvas_api this;

    private PathBuilderData builder_data;
    mixin PathBuilderAPI;

    ///////////////////////////////////////////////////////////////////////////////////
    // State

    void beginPath() {builder_data.reset();}
    void clip() {m_canvas_api.clip(builder_data.path);}
    void fill() {m_canvas_api.fill(builder_data.path);}
    void stroke() {m_canvas_api.stroke(builder_data.path);}

    ///////////////////////////////////////////////////////////////////////////////////
    // Styles

    @property void fillStyle(in LinearGradient gr) 
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

    @property void strokeStyle(in LinearGradient gr) 
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

    @property void fillStyle(in RadialGradient gr) 
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

    @property void strokeStyle(in RadialGradient gr) 
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

    @property void fillStyle(in Color c) 
    { fill_style(c); }

    @property void strokeStyle(in Color c)
    { stroke_style(c);}

    @property void lineWidth(float w)
    { line_width(w);}

    @property void lineCap(Cap cap) 
    { line_cap(cast(int) cap);}

    @property void lineJoin(Join join) 
    { line_join(cast(int) join);}

    @property void miterLimit(float m) 
    { miter_limit(m); }

    @property void globalCompositeOp(Composite_op op) 
    { global_composite_op(cast(int) op);}

    ///////////////////////////////////////////////////////////////////////////////////
    // Rectangles
    void fillRect(in Rect rec){fill_rect(rec);}
    void fillRoundRect(in Rect rec, float r){fill_round_rect(rec, r);}
    void strokeRect(in Rect rec){stroke_rect(rec);}
    void strokeRoundRect(in Rect rec, float r){stroke_round_rect(rec, r);}
}