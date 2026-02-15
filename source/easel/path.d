module easel.path;

import easel.cpp_bridge;
import easel.skia.sdk;

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
    static PathBuilder create(FillRule rule = FillRule.kDefault) @nogc
    {
        return PathBuilder(cpp_make_builder(rule));
    }

    ~this() @nogc {cpp_delete_builder(cpp_builder.impl);}

    @disable this();
    @disable this(this);

    PathBuilderData builder_data;
    mixin PathBuilderAPI;
    alias builder_data this;

private:

    this(PathBuilderImpl impl) @nogc
    {
        builder_data = PathBuilderData(impl);
    }
}

private extern(C++) @nogc {
    PathBuilderImpl cpp_make_builder(ubyte);
    void cpp_delete_builder(PathBuilderImpl);
}

package:
struct PathBuilderData
{
nothrow @nogc:

    this(PathBuilderImpl pimpl){cpp_builder.impl = pimpl;}
    
    ref Path path() return //@safe
    {
        if (isDirty){ 
            m_path = cpp_builder.snapshot();
            isDirty = false;
        }

        return m_path;
    }

    Path pathDetach()
    {
        isDirty = false;
        m_path.reset();

        return cpp_builder.detach();
    }

    void reset() 
    {
        cpp_builder.reset();
        m_path.reset();
        isDirty = false;
    }

    alias cpp_builder this;

    bool point_in_path(Point p)
    {return path.includes(p.x, p.y);}

package:
    CppPathBuilder cpp_builder;
    bool isDirty = false;

private:
    Path m_path;
}

mixin template PathBuilderAPI()
{

    bool point_in_path(Point p)
    {return builder_data.point_in_path(p);}

    bool isEmpty(){return builder_data.isEmpty;}

    void close()
    {
        if (builder_data.isDirty) builder_data.close();
    }
    
    void moveTo(Point p)
    {
        builder_data.moveTo(p);
        builder_data.isDirty = true;
    }
    void lineTo(Point p)
    {
        builder_data.lineTo(p);
        builder_data.isDirty = true;
    }
    void arcTo(Point p1, Point p2, float r)
    {
        builder_data.arcTo(p1, p2, r);
        builder_data.isDirty = true;
    }
    void quadraticCurveTo(Point p1, Point p2)
    {
        builder_data.quadraticCurveTo(p1, p2);
        builder_data.isDirty = true;
    }
    void bezierCurveTo(Point p1, Point p2, Point p3)
    {
        builder_data.bezierCurveTo(p1, p2, p3);
        builder_data.isDirty = true;
    }

    void arc(Point p, float radius, 
             float start_angle, float end_angle, bool ccw)
    {
        builder_data.arc(p, radius, start_angle, end_angle, ccw );
        builder_data.isDirty = true;
    }

    void addRect(in Rect rec)
    {
        builder_data.addRect(rec);
        builder_data.isDirty = true;
    }
    void addRoundRect(in Rect rec, float radius)
    {
        builder_data.addRoundRect(rec, radius);
        builder_data.isDirty = true;
    }
    void addCircle(Point center, float radius)
    {
        builder_data.addCircle(center, radius);
        builder_data.isDirty = true;
    }
}
