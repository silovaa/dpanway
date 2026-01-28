module easel.skia.path;

import easel.rect;
import easel.circle;

struct Path
{
    enum FillRule: ubyte
    {
        kWinding        = 0,
        kOdd_even       = 1,
        kInverseWinding = 2,
        kInverseEvenOdd = 3,

        kDefault = kWinding
    }

    this(FillRule rule){m_path = make_builder(rule);}
    ~this(){delete_builder(m_path);}

    bool    is_empty() const;
    bool    includes(Point p) const;
    bool    includes(float x, float y) const;
    Rect    bounds() const;

    void    close();

    mixin BoolMethod!("point_in_path", float, float); 
    mixin VoidMethod!("move_to", float, float);
    mixin VoidMethod!("line_to", float, float);
    mixin VoidMethod!("arc_to", float, float, float, float, float);
    mixin VoidMethod!("arc", Point, float, float, float, bool);
   
    mixin VoidMethod!("add_rect", float, float, float, float);
    mixin VoidMethod!("add_circle", float, float, float);
    mixin VoidMethod!("clear_rect", float, float, float, float);
    mixin VoidMethod!("quadratic_curve_to", float, float, float, float);
    mixin VoidMethod!("bezier_curve_to", float, float, float, float, float, float);

    mixin VoidMethod!("fill_style", float, float, float, float);
    mixin VoidMethod!("stroke_style", float, float, float, float);
    mixin VoidMethod!("line_width", float); 

    void    add_rect(ref const Rect r);
    void    add_round_rect(ref const Rect r, float radius);
    void    add_circle(ref const Circle c);

    void    add_rect(float x, float y, float width, float height);
    void    add_round_rect(
                float x, float y,
                float width, float height,
                float radius
            );
    void    add_circle(float cx, float cy, float radius);

    void    move_to(Point p);
    void    line_to(Point p);
    void    arc_to(Point p1, Point p2, float radius);
    void    arc(Point p, float radius,
                float start_angle, float end_angle,
                bool ccw = false
            );

    void    quadratic_curve_to(Point cp, Point end);
    void    bezier_curve_to(Point cp1, Point cp2, Point end);

    void    move_to(float x, float y);
    void    line_to(float x, float y);
    void    arc_to(
                float x1, float y1,
                float x2, float y2,
                float radius
            );
    void    arc(
                float x, float y, float radius,
                float start_angle, float end_angle,
                bool ccw = false
            );

    void    quadratic_curve_to(float cpx, float cpy, float x, float y);
    void    bezier_curve_to(
                float cp1x, float cp1y,
                float cp2x, float cp2y,
                float x, float y
            );

    void    fill_rule(FillRule rule);

    inout(PathBuilder) impl() inout @nogc {return m_path;}

private:
    PathBuilder m_path = make_builder(FillRule.kDefault);
}
