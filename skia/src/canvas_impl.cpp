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

      SkPathBuilder        _path;
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
   StateCanvas m_state;
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

StateCanvas* get_canvas(StateSurface *self)
{
   return &(self->m_state);
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

   // SkPath& canvas::canvas_state::path()
   // {
   //    return current()->_path;
   // }

   // SkPaint& canvas::canvas_state::fill_paint()
   // {
   //    return current()->_fill_paint;
   // }

   // SkPaint& canvas::canvas_state::stroke_paint()
   // {
   //    return current()->_stroke_paint;
   // }

   // class font& canvas::canvas_state::font()
   // {
   //    return current()->_font;
   // }

   // int& canvas::canvas_state::text_align()
   // {
   //    return current()->_text_align;
   // }

   // SkPaint& canvas::canvas_state::clear_paint()
   // {
   //    return _clear_paint;
   // }

   // void canvas::canvas_state::save()
   // {
   //    _stack.push(std::make_unique<state_info>(*current()));
   // }

   // void canvas::canvas_state::restore()
   // {
   //    if (_stack.size())
   //       _stack.pop();
   // }

   // SkPaint& canvas::canvas_state::get_fill_paint(canvas const& cnv)
   // {
   //    return cnv._state->fill_paint();
   // }

   // affine_transform canvas::canvas_state::get_inv_affine() const
   // {
   //    return _inv_affine;
   // }

   // void canvas::canvas_state::set_inv_affine(affine_transform xf)
   // {
   //    _inv_affine = xf;
   // }

//    canvas::canvas(canvas_impl* context_)
//     : _canvas{context_}
//     , _state{std::make_unique<canvas_state>()}
//    {
//       _state->set_inv_affine(transform().invert());
//    }

//    canvas::~canvas()
//    {
//    }


void translate(StateCanvas *cnv, float x, float y){ cnv->_canvas->translate(x, y);}
void rotate(StateCanvas *cnv, float rad){cnv->_canvas->rotate(rad * (180.0/std::numbers::pi));}
void scale(StateCanvas *cnv, float x, float y){ cnv->_canvas->scale(x, y);}
void skew(StateCanvas *cnv, double sx, double sy){cnv->_canvas->skew(sx, sy);}

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

void transform(StateCanvas *cnv, AffineTransform& m) 
{
   auto mat = cnv->_canvas->getLocalToDeviceAs3x3();
   SkScalar sc[6];
   (void) mat.asAffine(sc);
   m.a = sc[0]; m.b = sc[1]; m.c = sc[2]; 
   m.d = sc[3]; m.tx = sc[4]; m.ty = sc[5];
}

void transform(StateCanvas *cnv, AffineTransform const& mat)
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

// void canvas::transform(double a, double b, double c, double d, double tx, double ty)
// {
//    SkMatrix mat;
//    SkScalar sc[9] = {float(a), float(b), float(c), float(d), float(tx), float(ty)};
//    mat.setAffine(sc);
//    _canvas->setMatrix(mat);
// }

void save(StateCanvas *cnv)
{
   cnv->_canvas->save();
   cnv->_stack.push(std::make_unique<StateCanvas::state_info>(*(cnv->current())));
}

void restore(StateCanvas *cnv)
{
   cnv->_canvas->restore();
   if (cnv->_stack.size())
      cnv->_stack.pop();
}

void begin_path(StateCanvas *cnv){cnv->current()->_path.reset();}
void close_path(StateCanvas *cnv){cnv->current()->_path.close();}

void fill(StateCanvas *cnv, SkPathBuilder *pb)
{
   cnv->_canvas->drawPath(pb->detach(), cnv->current()->_fill_paint);
}

void stroke(StateCanvas *cnv, SkPathBuilder *pb)
{
   cnv->_canvas->drawPath(pb->detach(), cnv->current()->_stroke_paint);
}

void fill_preserve(StateCanvas *cnv, const SkPathBuilder *pb)
{
   cnv->_canvas->drawPath(pb->snapshot(), cnv->current()->_fill_paint);
}

void stroke_preserve(StateCanvas *cnv, const SkPathBuilder *pb)
{
   cnv->_canvas->drawPath(pb->snapshot(), cnv->current()->_stroke_paint);
}

void clip(StateCanvas *cnv, SkPathBuilder *pb)
{
   cnv->_canvas->clipPath(pb->detach(), true);
}

struct Rect  {float l, t, r, b;};
//struct Point {float x, y;};

Rect clip_extent(StateCanvas *cnv)
{
   SkRect r;
   cnv->_canvas->getLocalClipBounds(&r);
   return {r.left(), r.top(), r.right(), r.bottom()};
}

bool point_in_path(StateCanvas *cnv, float x, float y)
{
   return cnv->current()->_path.contains({x, y});
}

void move_to(StateCanvas *cnv, Point p)
{
   cnv->current()->_path.moveTo(p.x, p.y);
}

void line_to(StateCanvas *cnv, Point p)
{
   cnv->current()->_path.lineTo(p.x, p.y);
}

void arc_to(StateCanvas *cnv, Point p1, Point p2, float radius)
{
   cnv->current()->_path.arcTo(p1.x, p1.y, p2.x, p2.y, radius);
}

void arc(StateCanvas *cnv,
   Point p, float radius,
   float start_angle, float end_angle,
   bool ccw
)
{
   auto start = start_angle * 180 / std::numbers::pi;
   auto sweep = (end_angle - start_angle) * 180 / std::numbers::pi;
   sweep = std::abs(sweep) * (ccw? -1 : 1);

   cnv->current()->_path.addArc(
      {p.x-radius, p.y-radius, p.x+radius, p.y+radius},
      start, sweep
   );
}

void add_rect(StateCanvas *cnv, float left, float top, float right, float bottom)
{
   cnv->current()->_path.addRect(left, top, right, bottom);
}

void add_circle(StateCanvas *cnv, float cx, float cy, float r)
{
   cnv->current()->_path.addCircle(cx, cy, r);
}

// void canvas::add_path(path const& p)
// {
//    _state->path() = *p.impl();
// }

void clear_rect(StateCanvas *cnv, float left, float top, float right, float bottom)
{
   cnv->_canvas->drawRect({left, top, right, bottom}, cnv->_state->_clear_paint);
}
 
void quadratic_curve_to(StateCanvas *cnv, float x, float y, float endx, float endy)
{
   cnv->current()->_path.quadTo(x, y, endx, endy);
}

void bezier_curve_to(StateCanvas *cnv, float x1, float y1, float x2, float y2, float endx, float endy)
{
   cnv->current()->_path.cubicTo(x1, y1, x2, y2, endx, endy);
}

// struct Color {float r, g, b, a};

void fill_style(StateCanvas *cnv, float r, float g, float b, float a)
{
   cnv->current()->_fill_paint.setColor4f({r, g, b, a}, nullptr);
   cnv->current()->_fill_paint.setShader(nullptr);
}

void stroke_style(StateCanvas *cnv, Color c)
{
   cnv->current()->_stroke_paint.setColor4f({c.r, c.g, c.b, c.a}, nullptr);
   cnv->current()->_stroke_paint.setShader(nullptr);
}

void line_width(StateCanvas *cnv, float w)
{ 
   cnv->current()->_stroke_paint.setStrokeWidth(w);
}

// void line_cap(StateCanvas *cnv, LineCap cap_)
// {
//    SkPaint::Cap cap = SkPaint::kButt_Cap;
//    switch (cap_)
//    {
//       case line_cap_enum::butt:     cap = SkPaint::kButt_Cap; break;
//       case line_cap_enum::round:    cap = SkPaint::kRound_Cap; break;
//       case line_cap_enum::square:   cap = SkPaint::kSquare_Cap; break;
//    }
//    _state->stroke_paint().setStrokeCap(cap);
// }

// void canvas::line_join(join_enum join_)
// {
//    SkPaint::Join join = SkPaint::kMiter_Join;
//    switch (join_)
//    {
//       case join_enum::bevel_join:   join = SkPaint::kBevel_Join; break;
//       case join_enum::round_join:   join = SkPaint::kRound_Join; break;
//       case join_enum::miter_join:   join = SkPaint::kMiter_Join; break;
//    }
//    _state->stroke_paint().setStrokeJoin(join);
// }

// void canvas::miter_limit(float limit)
// {
//    _state->stroke_paint().setStrokeMiter(limit);
// }

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

// void canvas::global_composite_operation(composite_op_enum mode)
// {
//    SkBlendMode mode_ = SkBlendMode::kSrcOver;
//    switch (mode)
//    {
//       case source_over:       mode_ = SkBlendMode::kSrcOver;      break;
//       case source_atop:       mode_ = SkBlendMode::kSrcATop;      break;
//       case source_in:         mode_ = SkBlendMode::kSrcIn;        break;
//       case source_out:        mode_ = SkBlendMode::kSrcOut;       break;

//       case destination_over:  mode_ = SkBlendMode::kDstOver;      break;
//       case destination_atop:  mode_ = SkBlendMode::kDstATop;      break;
//       case destination_in:    mode_ = SkBlendMode::kDstIn;        break;
//       case destination_out:   mode_ = SkBlendMode::kDstOut;       break;

//       case lighter:           mode_ = SkBlendMode::kLighten;      break;
//       case darker:            mode_ = SkBlendMode::kDarken;       break;
//       case copy:              mode_ = SkBlendMode::kSrc;          break;
//       case xor_:              mode_ = SkBlendMode::kXor;          break;

//       case difference:        mode_ = SkBlendMode::kDifference;   break;
//       case exclusion:         mode_ = SkBlendMode::kExclusion;    break;
//       case multiply:          mode_ = SkBlendMode::kMultiply;     break;
//       case screen:            mode_ = SkBlendMode::kScreen;       break;

//       case color_dodge:       mode_ = SkBlendMode::kColorDodge;   break;
//       case color_burn:        mode_ = SkBlendMode::kColorBurn;    break;
//       case soft_light:        mode_ = SkBlendMode::kSoftLight;    break;
//       case hard_light:        mode_ = SkBlendMode::kHardLight;    break;

//       case hue:               mode_ = SkBlendMode::kHue;          break;
//       case saturation:        mode_ = SkBlendMode::kSaturation;   break;
//       case color_op:          mode_ = SkBlendMode::kColor;        break;
//       case luminosity:        mode_ = SkBlendMode::kLuminosity;   break;
//    };
//    _state->stroke_paint().setBlendMode(mode_);
//    _state->fill_paint().setBlendMode(mode_);
// }

// namespace
// {
//    void convert_gradient(
//       canvas::gradient const& gr
//     , std::vector<SkColor4f>& colors_
//     , std::vector<SkScalar>& pos
//    )
//    {
//       // comp is color compensation to match quartz-2d
//       constexpr auto comp = 1.3f;

//       for (auto const& ccs : gr.color_space)
//       {
//          colors_.push_back(
//             SkColor4f{
//                std::min(ccs.color.red * comp, 1.0f)
//              , std::min(ccs.color.green * comp, 1.0f)
//              , std::min(ccs.color.blue * comp, 1.0f)
//              , ccs.color.alpha
//             }
//          );
//          pos.push_back(ccs.offset);
//       }
//    }

//    void set_linear(canvas::linear_gradient const& gr, SkPaint& paint)
//    {
//       paint.setColor(SkColorSetRGB(0, 0, 0));
//       SkPoint points[2] = {
//          {gr.start.x, gr.start.y},
//          {gr.end.x, gr.end.y}
//       };
//       std::vector<SkColor4f> colors_;
//       std::vector<SkScalar> pos;
//       convert_gradient(gr, colors_, pos);
//       paint.setShader(
//          SkGradientShader::MakeLinear(
//             points, colors_.data()
//           , SkColorSpace::MakeSRGB()->makeLinearGamma()
//           , pos.data(), colors_.size()
//           , SkTileMode::kClamp
//           , SkGradientShader::Flags::kInterpolateColorsInPremul_Flag
//           , nullptr
//          ));
//    }

//    void set_radial(canvas::radial_gradient const& gr, SkPaint& paint)
//    {
//       paint.setColor(SkColorSetRGB(0, 0, 0));
//       std::vector<SkColor4f> colors_;
//       std::vector<SkScalar> pos;
//       convert_gradient(gr, colors_, pos);
//       paint.setShader(
//          SkGradientShader::MakeTwoPointConical(
//             {gr.c1.x, gr.c1.y}, gr.c1_radius
//           , {gr.c2.x, gr.c2.y}, gr.c2_radius
//           , colors_.data()
//           , SkColorSpace::MakeSRGB()->makeLinearGamma()
//           , pos.data(), colors_.size()
//           , SkTileMode::kClamp
//           , SkGradientShader::Flags::kInterpolateColorsInPremul_Flag
//           , nullptr
//          ));
//    }
// }

// void canvas::fill_style(linear_gradient const& gr)
// {
//    set_linear(gr, _state->fill_paint());
// }

// void canvas::fill_style(radial_gradient const& gr)
// {
//    set_radial(gr, _state->fill_paint());
// }

// void canvas::stroke_style(linear_gradient const& gr)
// {
//    set_linear(gr, _state->stroke_paint());
// }

// void canvas::stroke_style(radial_gradient const& gr)
// {
//    set_radial(gr, _state->stroke_paint());
// }

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

// void canvas::add_round_rect_impl(rect const& r, float radius)
// {
//    _state->path().addRoundRect({r.left, r.top, r.right, r.bottom}, radius, radius);
// }
