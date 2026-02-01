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


    mixin CanvasApi!CanvasImpl;

    private PathBuilderInternal m_builder;
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

struct ColorStop
{
    float   offset;
    Color   color;
}

struct Gradient
{
    float[] offset;
    Color[] color;
}

      struct linear_gradient : gradient
      {
         linear_gradient(float startx, float starty, float endx, float endy)
          : start{startx, starty}
          , end{endx, endy}
         {}

         linear_gradient(point start, point end)
          : start{start}
          , end{end}
         {}

         point start = {};
         point end = {};
      };

      struct radial_gradient : gradient
      {
         radial_gradient(
            float c1x, float c1y, float c1r,
            float c2x, float c2y, float c2r
         )
          : c1{c1x, c1y}
          , c1_radius{c1r}
          , c2{c2x, c2y}
          , c2_radius{c2r}
         {}

         radial_gradient(
            point c1, float c1r,
            point c2, float c2r
         )
          : c1{c1}
          , c1_radius{c1r}
          , c2{c2}
          , c2_radius{c2r}
         {}

         point c1 = {};
         float c1_radius = {};
         point c2 = c1;
         float c2_radius = c1_radius;
      };

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

    ///////////////////////////////////////////////////////////////////////////////////
    // Styles

    mixin Set!("fill_style", Color);
    mixin Set!("fill_style", Gradient);
    mixin Set!("stroke_style", Color);
    mixin Set!("stroke_style", Gradient);

    mixin Set!("line_width", float);
    mixin Set!("line_cap", Cap);
    mixin Set!("line_join", Join);
    mixin Set!("miter_limit", float);
    mixin Set!("composite_op", Composite_op);
}