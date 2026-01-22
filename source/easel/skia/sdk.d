module easel.skia.sdk;

alias CanvasImpl = StateCanvas*;

extern(C){
    struct StateCanvas;
    void translate(CanvasImpl, float x, float y);
    void rotate(CanvasImpl, float rad);
    void scale(CanvasImpl, float x, float y);
    void skew(CanvasImpl, double sx, double sy);

    struct AffineTransform {
        double a, b, c, d, tx, ty;
    }
    AffineTransform transform(CanvasImpl);
    void transform(CanvasImpl, const ref AffineTransform); 
    void save(CanvasImpl);
    void restore(CanvasImpl);
    void begin_path(CanvasImpl);
    void close_path(CanvasImpl);
    void fill_preserve(StateCanvas *cnv);
    void stroke_preserve(StateCanvas *cnv);
    void clip(StateCanvas *cnv);

    struct Rect  {float l, t, r, b;}
    struct Point {float x, y;}
    Rect clip_extent(StateCanvas *cnv);
    bool point_in_path(StateCanvas *cnv, Point p);
    void move_to(StateCanvas *cnv, Point p);
    void line_to(StateCanvas *cnv, Point p);
    void arc_to(StateCanvas *cnv, Point p1, Point p2, float radius);
    void arc(StateCanvas*, Point, float, float, float, bool);
    void add_rect(StateCanvas *cnv, const ref Rect r);
    struct Circle {float cx, cy, cr;}
    void add_circle(StateCanvas *cnv, const ref Circle);
    void clear_rect(StateCanvas *cnv, const ref Rect r);
    void quadratic_curve_to(StateCanvas *cnv, Point cp, Point end);
    void bezier_curve_to(StateCanvas *cnv, point cp1, point cp2, point end);
    struct Color {float r, g, b, a;}
    void fill_style(StateCanvas *cnv, Color c);

}