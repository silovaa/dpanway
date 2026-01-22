module easel.canvas;

import easel.rect;

version(skia) import easel.skia.sdk;

struct Canvas
{
    ///////////////////////////////////////////////////////////////////////////////////
    // Transforms
    void translate(point p) {translate(m_impl, p.x, p.y);}
    void rotate(float rad)  {rotate(m_impl, rad);}
    void scale(point p)     {scale(m_impl, p.x, p.y);}
    void scale(float xy)    {scale(m_impl, xy, xy);}
    void skew(double sx, double sy){skew(m_impl, sx, sy);}

    // point             device_to_user(point p);
    // point             user_to_device(point p);

    // void              translate(float x, float y){translate(m_impl, x, y);}
    // void              scale(float xy);
    // void              scale(float x, float y){}
    // point             device_to_user(float x, float y);
    // point             user_to_device(float x, float y);

    AffineTransform   transform() {return transform(m_impl);}
    void              transform(const ref AffineTransform mat) {transform(m_impl, mat);}
    void              transform(double a, double b, double c, double d, double tx, double ty)
                    {transform(AffineTransform(a, b, c, d, tx, ty));}

    ///////////////////////////////////////////////////////////////////////////////////
    // Paths
    void begin_path(){begin_path(m_impl);}
    void close_path(){close_path(m_impl);}
    void fill(){fill_preserve; begin_path;}
    void fill_preserve(){fill_preserve(m_impl);}
    void stroke(){stroke_preserve; begin_path;}
    void stroke_preserve(){stroke_preserve(m_impl);}

    void clip(){clip(m_impl);}
   //void              clip(path const& p);
    Rect clip_extent() {return clip_extent(m_impl);}
    bool              point_in_path(point p) const;
    bool              point_in_path(float x, float y) const;
    rect              fill_extent() const;

    void              move_to(point p);
    void              line_to(point p);
    void              arc_to(point p1, point p2, float radius);
    void              arc(
                        point p, float radius,
                        float start_angle, float end_angle,
                        bool ccw = false
                    );
    void              add_rect(const rect& r);
    void              add_round_rect(const rect& r, float radius);
    void              add_circle(circle const& c);
    void              add_path(path const& p);
    void              clear_rect(rect const& r);

    void              quadratic_curve_to(point cp, point end);
    void              bezier_curve_to(point cp1, point cp2, point end);

    void              move_to(float x, float y);
    void              line_to(float x, float y);
    void              arc_to(
                        float x1, float y1,
                        float x2, float y2,
                        float radius
                    );
    void              arc(
                        float x, float y, float radius,
                        float start_angle, float end_angle,
                        bool ccw = false
                    );
    void              add_rect(float x, float y, float width, float height);
    void              add_round_rect(
                        float x, float y,
                        float width, float height,
                        float radius
                    );
    void              add_circle(float cx, float cy, float radius);
    void              clear_rect(float x, float y, float width, float height);

    void              quadratic_curve_to(float cpx, float cpy, float x, float y);
    void              bezier_curve_to(
                        float cp1x, float cp1y,
                        float cp2x, float cp2y,
                        float x, float y
                    );

    private CanvasImpl m_impl;
}
