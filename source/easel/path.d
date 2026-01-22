module easel.skia.path;

struct Path
{
    bool    is_empty() const;
    bool    includes(point p) const;
    bool    includes(float x, float y) const;
    rect    bounds() const;

    void    close();

    void    add_rect(rect const& r);
    void    add_round_rect(rect const& r, float radius);
    void    add_circle(circle const& c);

    void    add_rect(float x, float y, float width, float height);
    void    add_round_rect(
                float x, float y,
                float width, float height,
                float radius
            );
    void    add_circle(float cx, float cy, float radius);

    void    move_to(point p);
    void    line_to(point p);
    void    arc_to(point p1, point p2, float radius);
    void    arc(point p, float radius,
                float start_angle, float end_angle,
                bool ccw = false
            );

    void    quadratic_curve_to(point cp, point end);
    void    bezier_curve_to(point cp1, point cp2, point end);

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

    enum fill_rule
    {
        winding,
        odd_even
    };

    void    fill_rule(fill_rule rule);

private:
    SkPath m_path;
}
