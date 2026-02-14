module easel.skia.sdk;

extern (C++){

struct StateCanvas;
struct StateSurface;
struct PathBuilder;

struct SkPath
{
    // Конструктор копирования (современный D)
    this(ref return scope inout typeof(this) src) inout @nogc
    {
        sk_path_copy(cast(SkPath*)&this, cast(const SkPath*)&src);
    }

    ~this() @nogc nothrow;

    bool includes(float x, float y) const @nogc nothrow;
    void reset() @nogc nothrow;

private:
    void* data;
    ubyte fFillType;
    bool  fIsVolatile;
} 

private @nogc nothrow {
    void sk_path_copy(SkPath* dst, const(SkPath)* src);
    void sk_path_destruct(SkPath* path);
}

struct SkRect
{
    float left = 0; //!< smaller x-axis bounds
    float top  = 0; //!< smaller y-axis bounds
    float right  = 0; //!< larger x-axis bounds
    float bottom = 0; //!< larger y-axis bounds
}

struct SkPoint
{
    float x = 0, y = 0;
}

enum SkAlphaType : int {
    unknown,
    opaque,
    premul,
    unpremul
}

struct SkRGBA4f(SkAlphaType AT) 
{    
    float red   = 0.0f;
    float green = 0.0f;
    float blue  = 0.0f;
    float alpha = 0.0f;
}

}

alias CanvasImpl  = StateCanvas*;
alias SurfaceImpl = StateSurface*;
alias PathBuilderImpl = PathBuilder*;
alias Path = SkPath; 
alias Rect = SkRect;
alias Point = SkPoint;
alias ColorImpl = SkRGBA4f!(SkAlphaType.unpremul);
