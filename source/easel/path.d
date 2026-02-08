module easel.path;

import easel.rect;
//import easel.circle;

import easel.cpp_bridge;

enum FillRule: ubyte
{
    kWinding,
    kOdd_even,
    kInverseWinding,
    kInverseEvenOdd,

    kDefault = kWinding
}

struct PathBuilder
{
    this(FillRule rule) @nogc
    {
        self = PathBuilderInternal(cpp_make_builder(rule));
    }

    ~this() @nogc {cpp_delete_builder(self.impl);}

    alias self this;
    @disable this(this);

private:
    PathBuilderInternal self;

    this(PathBuilderImpl impl) @nogc
    {
        self = PathBuilderInternal(impl);
    }
}

PathBuilder makePathBuilder() @nogc
{
    return PathBuilder(cpp_make_builder(FillRule.kDefault));
}

private extern(C++) @nogc {
    PathBuilderImpl cpp_make_builder(ubyte);
    void cpp_delete_builder(PathBuilderImpl);
}

package struct PathBuilderInternal
{
    this(PathBuilderImpl impl) @nogc {m_path_builder = impl;}

    bool point_in_path(Point p)
    {return path.includes(p.x, p.y);}
    
    //Rect    bounds() const;

    private extern(C++) @nogc static Path cpp_builder_snapshot(PathBuilderImpl);
    ref Path path() nothrow @nogc
    {
        if (isDirty){ 
            m_path = cpp_builder_snapshot(impl);
            isDirty = false;
        }

        return m_path;
    }

    private extern(C++) @nogc static Path cpp_builder_detach(PathBuilderImpl);
    Path pathDetach() nothrow @nogc
    {
        isDirty = true;

        return cpp_builder_detach(impl);
    }

    private extern(C++) @nogc static void cpp_builder_reset(PathBuilderImpl);
    void reset() @nogc
    {
        cpp_builder_reset(impl);
        m_path.reset();
        isDirty = false;
    }

    mixin PathBuilderApi!PathBuilderImpl;

private:
    PathBuilderImpl m_path_builder;
    Path m_path;
    bool isDirty = false;
}

private:

mixin template PathBuilderApi(ImplType) {
    mixin ImplAccessor!ImplType;
    // Хелпер для void методов (для краткости)
    mixin template Void(string name, Args...) {
        mixin ApiMethod!(ImplType, void, name, Args);
    }
    mixin template Bool(string name, Args...) {
        mixin ApiMethod!(ImplType, bool, name, Args);
    }
    // Хелпер для Setter (@property)
    mixin template Set(string name, T) {
        mixin ApiSetter!(ImplType, name, T);
    }

    // mixin template Prop(string name, T) {
    //     mixin ApiProperty!(ImplType, name, T);
    // }
    
    mixin Bool!("is_empty");
    mixin Void!("close");

    mixin Set!("fill_type", FillRule);

    mixin Void!("move_to", Point);
    mixin Void!("line_to", Point);
    mixin Void!("arc_to", Point, Point, float);
    mixin Void!("quadratic_curve_to", Point, Point);
    mixin Void!("bezier_curve_to", Point, Point, Point);

    mixin Void!("arc", Point, float, float, float, bool);
   
    mixin Void!("add_rect", Rect);
    mixin Void!("add_round_rect", Rect, float);
    mixin Void!("add_circle", Point, float);
    
    //mixin Void!("clear_rect", float, float, float, float);
}
