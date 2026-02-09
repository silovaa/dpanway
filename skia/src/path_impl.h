#pragma once

#include <SkPath.h>
#include <SkPathBuilder.h>
#include <SkPoint.h>

extern "C++"{
void sk_path_copy(SkPath* dst, const SkPath* src) 
{
   // Используем placement new, чтобы вызвать конструктор копирования C++
   // прямо в памяти, выделенной на стороне D.
   new (dst) SkPath(*src);
}

void sk_path_destruct(SkPath* path) 
{
   path->~SkPath();
}

SkPathBuilder* cpp_make_builder(uint8_t fill_rule)
{
   auto rule = static_cast<SkPathFillType>(fill_rule);
   return new SkPathBuilder(rule);
}

void cpp_destroy_builder(SkPathBuilder* ptr){delete ptr;}

struct CppPathBuilder
{
   SkPathBuilder* impl;

   bool isEmpty() ;
   SkPath detach();
   SkPath snapshot();
   void reset();

   void fill_type(int ft);
   void close();
   void moveTo(SkPoint p);
   void lineTo(SkPoint p);
   void arcTo(SkPoint p1, SkPoint p2, float radius);

   void arc(SkPoint p, float radius,
      float start_angle, float end_angle,
      bool ccw
   );

   void addRect(const SkRect &r);
   void addRoundRect(const SkRect &rect, float radius);
   void addCircle(float cx, float cy, float r);

   // void canvas::add_path(path const& p)
   // {
   //    _state->path() = *p.impl();
   // }

   // void clear_rect(StateCanvas *cnv, float left, float top, float right, float bottom)
   // {
   //    cnv->_canvas->drawRect({left, top, right, bottom}, cnv->_state->_clear_paint);
   // }
   
   void quadraticCurveTo(const SkPoint& p, const SkPoint& end);
   void bezierCurveTo(const SkPoint& p, 
                           const SkPoint& p1, const SkPoint& end);
};

bool CppPathBuilder::isEmpty() {return impl->isEmpty();}
SkPath CppPathBuilder::detach(){return impl->detach();}
SkPath CppPathBuilder::snapshot(){return impl->snapshot();}
void CppPathBuilder::reset(){impl->reset();}

void CppPathBuilder::fill_type(int ft)
{
   impl->setFillType(static_cast<SkPathFillType>(ft));
}

void CppPathBuilder::close(){impl->close();}
void CppPathBuilder::moveTo(SkPoint p){impl->moveTo(p); }
void CppPathBuilder::lineTo(SkPoint p){impl->lineTo(p); }

void CppPathBuilder::arcTo(SkPoint p1, SkPoint p2, float radius)
{
   impl->arcTo(p1, p2, radius);
}

void CppPathBuilder::arc(SkPoint p, float radius,
      float start_angle, float end_angle,
      bool ccw
   )
{
   // 1. Конвертация в градусы
   float start_deg = start_angle * 180.0f / SK_ScalarPI;
   float end_deg = end_angle * 180.0f / SK_ScalarPI;
   
   // 2. Вычисление sweep_angle (пробег дуги)
   float sweep = end_deg - start_deg;

   // Логика Canvas: 
   // Если sweep > 0 и мы идем против часовой (ccw), нужно вычесть 360, 
   // чтобы сделать полный круг "назад".
   if (!ccw) {
      // По часовой (CW)
      while (sweep < 0) sweep += 360.0f;
      while (sweep > 360) sweep -= 360.0f;
   } else {
      // Против часовой (CCW)
      while (sweep > 0) sweep -= 360.0f;
      while (sweep < -360) sweep += 360.0f;
   }

   // 3. Отрисовка
   SkRect oval = SkRect::MakeLTRB(p.x() - radius, p.y() - radius, 
                                 p.x() + radius, p.y() + radius);
   
   // arcTo с параметром forceMoveTo = false (4-й аргумент)
   // Это заставит Skia провести lineTo до начала дуги, как в Canvas.
   impl->arcTo(oval, start_deg, sweep, false);
}

void CppPathBuilder::addRect(const SkRect &r){impl->addRect(r);}

void CppPathBuilder::addRoundRect(const SkRect &rect, float radius)
{
   impl->addRRect(SkRRect::MakeRectXY(rect, radius, radius));
}

void CppPathBuilder::addCircle(float cx, float cy, float r)
{
   impl->addCircle(cx, cy, r);
}

void CppPathBuilder::quadraticCurveTo(const SkPoint& p, const SkPoint& end)
{
   impl->quadTo(p, end);
}

void CppPathBuilder::bezierCurveTo(const SkPoint& p, 
                        const SkPoint& p1, const SkPoint& end)
{
   impl->cubicTo(p, p1, end);
}

}