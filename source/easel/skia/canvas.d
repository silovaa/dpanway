module easel.skia.canvas;

struct Canvas
{
    ///////////////////////////////////////////////////////////////////////////////////
    // Transforms
    void              translate(point p);
    void              rotate(float rad);
    void              scale(point p);
    void              skew(double sx, double sy);
    point             device_to_user(point p);
    point             user_to_device(point p);

    void              translate(float x, float y);
    void              scale(float xy);
    void              scale(float x, float y);
    point             device_to_user(float x, float y);
    point             user_to_device(float x, float y);

    affine_transform  transform() const;
    void              transform(affine_transform const& mat);
    void              transform(double a, double b, double c, double d, double tx, double ty);

    ///////////////////////////////////////////////////////////////////////////////////
    // Paths
    void              begin_path();
    void              close_path();
    void              fill();
    void              fill_preserve();
    void              stroke();
    void              stroke_preserve();

    void              clip();
    void              clip(path const& p);
    rect              clip_extent() const;
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
}
