#include <stack>
//#include "opaque.hpp"

#include <SkBitmap.h>
#include <SkColorSpace.h>
#include <SkData.h>
#include <SkImage.h>
#include <SkPicture.h>
#include <SkSurface.h>
#include <SkCanvas.h>
// #include <SkPath.h>
// #include <SkPathBuilder.h>
// #include <include/effects/SkGradient.h>
#include <SkImageFilter.h>
#include <include/effects/SkImageFilters.h>
#include <SkTextBlob.h>
#include <SkTypeface.h>
#include <SkFont.h>

#include "include/gpu/ganesh/gl/GrGLAssembleInterface.h"
#include "include/gpu/ganesh/GrDirectContext.h"
#include "include/gpu/ganesh/gl/GrGLDirectContext.h"
#include <EGL/egl.h>
#include <GLES3/gl3.h> //for glGetIntegerv

#include "include/gpu/ganesh/gl/GrGLBackendSurface.h"
#include "include/gpu/ganesh/GrBackendSurface.h"
#include "include/gpu/ganesh/SkSurfaceGanesh.h"

#include "path_impl.h"

struct AffineTransform {
   double a, b, c, d, tx, ty;
};

class StateCanvas
{
public:

   //  struct blur_info
   //  {
   //      point    _offset;
   //      float    _blur;
   //      color    _color;
   //  };

   StateCanvas(); 

   SkCanvas* _canvas; 

   struct state_info
   {
      state_info()
      {
      _fill_paint.setAntiAlias(true);
      _fill_paint.setStyle(SkPaint::kFill_Style);
      _stroke_paint.setAntiAlias(true);
      _stroke_paint.setStyle(SkPaint::kStroke_Style);
      }

      SkPaint        _fill_paint;
      SkPaint        _stroke_paint;
      //class font     _font;
      int            _text_align = 0;
   };

   using state_info_ptr = std::unique_ptr<state_info>;
   using state_info_stack = std::stack<state_info_ptr>;

   state_info*       current() { return _stack.top().get(); }
   state_info const* current() const { return _stack.top().get(); }

//private:
   state_info_stack  _stack;
   SkPaint           _clear_paint;
   AffineTransform  _inv_affine;
};

// Функция-загрузчик для EGL
GrGLFuncPtr egl_get_proc(void* ctx, const char name[]) {
    return eglGetProcAddress(name);
}

sk_sp<const GrGLInterface> glInterface;
sk_sp<GrDirectContext> dContext;

GrDirectContext* context()
{
   if (!dContext){
      glInterface = GrGLMakeAssembledInterface(nullptr, egl_get_proc);
      dContext = GrDirectContexts::MakeGL(glInterface);
   }

   return dContext.get();
}

struct StateSurface
{
   sk_sp<SkSurface> m_surface;
   StateCanvas      m_state;
   SkPathBuilder    m_path_builder;
};

StateSurface* make_egl_current(StateSurface *self, int width, int height, 
                              int sample, int stencil)
{
   auto ctx = context();
   if (!ctx) return nullptr;

   if (!self) self = new StateSurface;

   GLint fboId;
   glGetIntegerv(GL_FRAMEBUFFER_BINDING, &fboId); // Получаем ID от EGL

   GrGLFramebufferInfo fbInfo;
   fbInfo.fFBOID = (GrGLuint)fboId;
   fbInfo.fFormat = GL_RGBA8; // Формат должен совпадать с конфигом EGL

   GrBackendRenderTarget backendRT = GrBackendRenderTargets::MakeGL(
      width, height, 
      sample, // sampleCount (MSAA)
      stencil, // stencilBits
      fbInfo
   );

   self->m_surface = SkSurfaces::WrapBackendRenderTarget(
      ctx,
      backendRT,
      kBottomLeft_GrSurfaceOrigin, // Стандарт для OpenGL/EGL
      kRGBA_8888_SkColorType,      // Цветовой тип
      nullptr,                     // ColorSpace (например, SkColorSpace::MakeSRGB())
      nullptr                      // SurfaceProps
   );

   if (self->m_surface){
      self->m_state._canvas = self->m_surface->getCanvas();
      return self;
   }

   delete self;
   return nullptr;
}

void destroy_surface(StateSurface *self)
{
   delete self;
   dContext.reset();
   glInterface.reset();
}

struct Canvas
{
   StateCanvas*     state;
   SkPathBuilder*   path_builder;
}

Canvas get_canvas(StateSurface *self)
{
   return {&(self->m_state), &(self->m_path_builder)};
}

void flush_and_submit(StateSurface *self)
{
   context()->flushAndSubmit(self->m_surface.get());
}

int width(StateSurface *self) 
{
   return self->m_surface->width();
}

int height(StateSurface *self) 
{
   return self->m_surface->height();
}


StateCanvas::StateCanvas():
   _canvas(nullptr)
{
   _stack.push(std::make_unique<state_info>());
   _clear_paint.setAntiAlias(true);
   _clear_paint.setStyle(SkPaint::kFill_Style);
   _clear_paint.setBlendMode(SkBlendMode::kClear);
}

//    canvas::canvas(canvas_impl* context_)
//     : _canvas{context_}
//     , _state{std::make_unique<canvas_state>()}
//    {
//       _state->set_inv_affine(transform().invert());
//    }

///////////////////////////////////////////////////////////////////////////////////
// Transforms

void cpp_translate(StateCanvas *cnv, float x, float y){ cnv->_canvas->translate(x, y);}
void cpp_rotate(StateCanvas *cnv, float rad){cnv->_canvas->rotate(rad * (180.0/std::numbers::pi));}
void cpp_scale(StateCanvas *cnv, float x, float y){ cnv->_canvas->scale(x, y);}
void cpp_skew(StateCanvas *cnv, double sx, double sy){cnv->_canvas->skew(sx, sy);}

// point canvas::device_to_user(point p)
// {
//    // Get the current transform
//    auto af = transform();

//    // Undo the initial transform
//    auto xaf = af * _state->get_inv_affine();

//    // Map the point to the inverted `xaf` transform
//    auto up = xaf.invert().apply(p);

//    return {float(up.x), float(up.y)};
// }

// point canvas::user_to_device(point p)
// {
//    // Get the current transform
//    auto af = transform();

//    // Undo the initial transform
//    auto xaf = af * _state->get_inv_affine();

//    // Map the point to the `xaf` transform
//    auto up = xaf.apply(p);

//    return {float(up.x), float(up.y)};
// }

AffineTransform cpp_get_transform(StateCanvas *cnv) 
{
   auto mat = cnv->_canvas->getLocalToDeviceAs3x3();
   SkScalar sc[6];
   (void) mat.asAffine(sc);
   return {sc[0], sc[1], sc[2], sc[3], sc[4], sc[5]};
}

void cpp_set_transform(StateCanvas *cnv, AffineTransform const& mat)
{
   SkMatrix skMat;

   SkScalar sc[6] = {
      static_cast<SkScalar>(mat.a),
      static_cast<SkScalar>(mat.b),
      static_cast<SkScalar>(mat.c),
      static_cast<SkScalar>(mat.d),
      static_cast<SkScalar>(mat.tx),
      static_cast<SkScalar>(mat.ty)
   };
   skMat.setAffine(sc);
   cnv->_canvas->setMatrix(skMat);
}

///////////////////////////////////////////////////////////////////////////////////
// State

void cpp_save(StateCanvas *cnv)
{
   cnv->_canvas->save();
   cnv->_stack.push(std::make_unique<StateCanvas::state_info>(*(cnv->current())));
}

void cpp_restore(StateCanvas *cnv)
{
   cnv->_canvas->restore();
   if (cnv->_stack.size())
      cnv->_stack.pop();
}

void cpp_fill(StateCanvas *cnv, const SkPath &p)
{
   cnv->_canvas->drawPath(p, cnv->current()->_fill_paint);
}

void cpp_stroke(StateCanvas *cnv, const SkPath &p)
{
   cnv->_canvas->drawPath(p, cnv->current()->_stroke_paint);
}

void clip(StateCanvas *cnv,  const SkPath &p)
{
   cnv->_canvas->clipPath(p, true);
}

struct Rect  {float l, t, r, b;};
//struct Point {float x, y;};

Rect clip_extent(StateCanvas *cnv)
{
   SkRect r;
   cnv->_canvas->getLocalClipBounds(&r);
   return {r.left(), r.top(), r.right(), r.bottom()};
}

///////////////////////////////////////////////////////////////////////////////////
// Styles

void cpp_set_fill_style(StateCanvas *cnv, SkColor4f c)
{
   cnv->current()->_fill_paint.setColor4f(c, nullptr);
   cnv->current()->_fill_paint.setShader(nullptr);
}

void cpp_set_stroke_style(StateCanvas *cnv, SkColor4f c)
{
   cnv->current()->_stroke_paint.setColor4f(c, nullptr);
   cnv->current()->_stroke_paint.setShader(nullptr);
}

void cpp_fill_linear(StateCanvas* cnv,
                        const SkPoint pts[2], 
                        const SkColor4f colors[], 
                        const float offsets[], 
                        size_t count)
{
   SkGradient::Colors colors(
                        {colors, count},
                        offsets ? {offsets, count} : {},
                        SkTileMode::kClamp);

   cnv->current()->_fill_paint.setShader(
      SkShaders::LinearGradient(pts, SkGradient(colors, {}))
   );
}

void cpp_stroke_linear(StateCanvas* cnv,
                        const SkPoint pts[2], 
                        const SkColor4f colors[], 
                        const float offsets[], 
                        size_t count)
{
   SkGradient::Colors colors(
                        {colors, count},
                        offsets ? {offsets, count} : {},
                        SkTileMode::kClamp);

   cnv->current()->_stroke_paint.setShader(
      SkShaders::LinearGradient(pts, SkGradient(colors, {}))
   );
}

void cpp_fill_radial(StateCanvas* cnv,
                        const SkPoint pts, float radius, 
                        const SkColor4f colors[], 
                        const float offsets[], 
                        size_t count)
{
   SkGradient::Colors colors(
                        {colors, count},
                        offsets ? {offsets, count} : {},
                        SkTileMode::kClamp);

   cnv->current()->_fill_paint.setShader(
      SkShaders::RadialGradient(pts, radius, SkGradient(colors, {}))
   );
}

void cpp_stroke_radial(StateCanvas* cnv,
                        const SkPoint pts, float radius, 
                        const SkColor4f colors[], 
                        const float offsets[], 
                        size_t count)
{
   SkGradient::Colors colors(
                        {colors, count},
                        offsets ? {offsets, count} : {},
                        SkTileMode::kClamp);

   cnv->current()->_stroke_paint.setShader(
      SkShaders::RadialGradient(pts, radius, SkGradient(colors, {}))
   );
}

void cpp_set_line_width(StateCanvas *cnv, float w)
{ 
   cnv->current()->_stroke_paint.setStrokeWidth(w);
}

void cpp_set_line_cap(StateCanvas *cnv, int cap)
{
   cnv->current()->_stroke_paint.setStrokeCap(
                        static_cast<SkPaint::Cap>(cap));
}

void cpp_set_line_join(StateCanvas *cnv, int join_)
{
   cnv->current()->_stroke_paint.setStrokeJoin(
                        static_cast<SkPaint::Join>(join));
}

void cpp_set_miter_limit(StateCanvas *cnv, float limit)
{
   cnv->current()->_stroke_paint.setStrokeMiter(limit);
}

// void canvas::shadow_style(point offset, float blur, color c)
// {
//    constexpr auto blur_factor = 1.0f;
//    auto matrix = _canvas->getTotalMatrix();
//    float scx = matrix.getScaleX();
//    float scy = matrix.getScaleY();

//    auto shadow = SkImageFilters::DropShadow(
//       offset.x / scx
//     , offset.y / scy
//     , (blur * blur_factor) / scx
//     , (blur * blur_factor) / scy
//     , SkColor4f{c.red, c.green, c.blue, c.alpha}.toSkColor()
//     , nullptr
//    );

//    _state->stroke_paint().setImageFilter(shadow);
//    _state->fill_paint().setImageFilter(shadow);
// }

void cpp_set_global_composite_op(StateCanvas *cnv, int mode)
{
   auto mode_ = static_cast<SkBlendMode>(mode);
   
   cnv->current()->_stroke_paint.setBlendMode(mode_);
   cnv->current()->_fill_paint.setBlendMode(mode_);
}

///////////////////////////////////////////////////////////////////////////////////
// Rectangles

void cpp_fill_rect(StateCanvas *cnv, const Rect& r)
{
   cnv->_canvas.drawRect(r, cnv->current()->_fill_paint);
}

void cpp_fill_round_rect(StateCanvas *cnv, const Rect& r, float radius)
{
   cnv->_canvas.drawRoundRect(r, radius, radius, cnv->current()->_fill_paint);
}

void cpp_stroke_rect(StateCanvas *cnv, const Rect& r)
{
   cnv->_canvas.drawRect(r, cnv->current()->_stroke_paint);
}

void cpp_stroke_round_rect(StateCanvas *cnv, const Rect&, float radius)
{
   cnv->_canvas.drawRoundRect(r, radius, radius, cnv->current()->_stroke_paint);
}

///////////////////////////////////////////////////////////////////////////////////
// Text

// void canvas::font(class font const& font_)
// {
//    _state->font() = font_;
// }

// void canvas::fill_rule(path::fill_rule_enum rule)
// {
//    _state->path().setFillType(
//       rule == path::fill_winding? SkPathFillType::kWinding : SkPathFillType::kEvenOdd
//    );
// }

// namespace
// {
//    void prepare_text(
//       font const& font
//     , int text_align
//     , point& p, char const* f, char const* l
//    )
//    {
//       auto metrics = font.metrics();
//       auto width = font.measure_text(std::string_view(f, l-f));
//       switch (text_align & 0x1C)
//       {
//          case canvas::top:    p.y += metrics.ascent; break;
//          case canvas::middle: p.y += (metrics.ascent - metrics.descent)/2; break;
//          case canvas::bottom: p.y -= metrics.descent; break;
//          default: break;
//       }

//       switch (text_align & 0x3)
//       {
//          case canvas::center: p.x -= width/2; break;
//          case canvas::right:  p.x -= width; break;
//          default: break;
//       }
//    }
// }

// void canvas::fill_text(std::string_view utf8, point p)
// {
//    auto text_blob = SkTextBlob::MakeFromText(
//       utf8.data(), utf8.size(), *_state->font().impl().get()
//    );
//    prepare_text(_state->font(), _state->text_align(), p, utf8.data(), utf8.data()+utf8.size());
//    _canvas->drawTextBlob(text_blob.get(), p.x, p.y, _state->fill_paint());
// }

// void canvas::stroke_text(std::string_view utf8, point p)
// {
//    auto text_blob = SkTextBlob::MakeFromText(
//       utf8.data(), utf8.size(), *_state->font().impl().get()
//    );
//    prepare_text(_state->font(), _state->text_align(), p, utf8.data(), utf8.data()+ utf8.size());
//    _canvas->drawTextBlob(text_blob.get(), p.x, p.y, _state->stroke_paint());
// }

// canvas::text_metrics canvas::measure_text(std::string_view utf8)
// {
//    auto m = _state->font().metrics();
//    auto width = _state->font().measure_text(utf8);
//    return {
//       m.ascent
//     , m.descent
//     , m.leading
//     , {width, m.ascent + m.descent + m.leading}
//    };
// }

// void canvas::text_align(int align)
// {
//    _state->text_align() = align;
// }

// void canvas::text_align(text_halign align)
// {
//    _state->text_align() |= align;
// }

// void canvas::text_baseline(text_valign align)
// {
//    _state->text_align() |= align;
// }

// void canvas::draw(image const& pic, rect const& src, rect const& dest)
// {
//    auto draw_picture =
//       [&](auto const& that)
//       {
//          using T = std::decay_t<decltype(that)>;
//          if constexpr(std::is_same_v<T, extent>)
//          {
//          }
//          if constexpr(std::is_same_v<T, sk_sp<SkPicture>>)
//          {
//             SkMatrix mat;
//             mat.setScale(dest.width()/src.width(), dest.height()/src.height());
//             mat.setTranslate(dest.left-src.left, dest.top-src.top);
//             _canvas->drawPicture(that, &mat, &_state->fill_paint());
//          }
//          if constexpr(std::is_same_v<T, SkBitmap>)
//          {
//             _canvas->drawImageRect(
//                that.asImage(),
//                SkRect{src.left, src.top, src.right, src.bottom},
//                SkRect{dest.left, dest.top, dest.right, dest.bottom},
//                SkSamplingOptions(),
//                &_state->fill_paint(),
//                SkCanvas::kStrict_SrcRectConstraint
//             );
//          }
//       };

//    return std::visit(draw_picture, pic.impl()->base());
// }
