module easel.cpp_bridge;

import easel.skia.sdk;

//import easel.rect;
//import easel.color;
import easel.affine; 

extern(C++){
    struct Surface
    {
        mixin Impl!SurfaceImpl;

        int setFromFramebuffer(int width, int height, 
                                int sample = 0, int stencil = 8) @nogc;
        void destroy() @nogc;
        CanvasPtr canvas() @nogc;
        void flush() @nogc;
        int width() @nogc;
        int height() @nogc;
    }

    struct CanvasPtr
    {
        CanvasImpl      state;
        PathBuilderImpl path_builder;
    }

    struct CppCanvas
    {
        mixin Impl!CanvasImpl;

    @nogc:
        ///////////////////////////////////////////////////////////////////////////////////
        // State
        void save();
        void restore();
        void clip(const ref Path);
        void fill(const ref Path);
        void stroke(const ref Path);

        Rect clipExtent();

        ///////////////////////////////////////////////////////////////////////////////////
        // Transforms
        void translate(float , float);
        void rotate(float);
        void scale(float , float);
        void skew(double, double);

        AffineTransform transform();
        void transform(const ref AffineTransform);

        ///////////////////////////////////////////////////////////////////////////////////
        // Rectangles
        void fillRect(const ref Rect);
        void fillRoundRect(const ref Rect, float);
        void strokeRect(const ref Rect);
        void strokeRoundRect(const ref Rect, float);

    package @nogc: struct CppCanvas
        ///////////////////////////////////////////////////////////////////////////////////
        // Styles (property for override)

        void fill_linear(const(Point)* pts, const(ColorImpl)* colors, 
                            const(float)* offsets, size_t count);
        void stroke_linear(const(Point)* pts, const(ColorImpl)* colors, 
                            const(float)* offsets, size_t count);
        void fill_radial(const(Point) pts, float radius,
                            const(ColorImpl)* colors, 
                            const(float)* offsets, 
                            size_t count);
        void stroke_radial(const(Point) pts, float radius,
                        const(ColorImpl)* colors, 
                        const(float)* offsets, 
                        size_t count);
        void fill_style(ref const(ColorImpl));
        void stroke_style(const ref ColorImpl);

        void line_width(float);
        void line_cap(int);
        void line_join(int);
        void miter_limit(float);
        void global_composite_op(int);
    }

    struct CppPathBuilder
    {
        mixin Impl!PathBuilderImpl;

    @nogc nothrow:
        bool isEmpty();
        void close();
        
        void moveTo(Point);
        void lineTo(Point);
        void arcTo(Point, Point, float);
        void quadraticCurveTo(Point, Point);
        void bezierCurveTo(Point, Point, Point);

        void arc(Point, float, float, float, bool);

        void addRect(const ref Rect);
        void addRoundRect(const ref Rect, float);
        void addCircle(Point, float);

    package:
        void fill_type(int);
        Path snapshot();
        Path detach();
        void reset();
    }
}

private:

mixin template Impl(ImplType) {
    private ImplType m_impl;

    // Геттер с проверкой
    @property @nogc nothrow
    package ImplType impl() {
        assert(m_impl !is null, "Canvas implementation (m_impl) is null");
        return m_impl;
    }

    @property @nogc nothrow
    package void impl(ImplType h) {
        m_impl = h;
    }
}