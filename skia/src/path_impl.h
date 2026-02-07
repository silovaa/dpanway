#pragma once

#include <SkPath.h>
#include <SkPathBuilder.h>
#include <SkPoint.h>
//#include <include/effects/SkGradient.h>

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

SkPath cpp_builder_detach(SkPathBuilder *pb){return pb->detach();}
SkPath cpp_builder_snapshot(const SkPathBuilder *pb){return pb->snapshot();}
void cpp_builder_reset(SkPathBuilder *pb){pb->reset();}

void cpp_set_fill_type(SkPathBuilder *pb, int ft)
{
   pb->setFillType(static_cast<SkPathFillType>(ft));
}

void cpp_close_path(SkPathBuilder *pb){pb->close();}

void cpp_move_to(SkPathBuilder *pb, const SkPoint &p)
{
   pb->moveTo(p);
}

void cpp_line_to(SkPathBuilder *pb, const SkPoint &p)
{
   pb->lineTo(p);
}

void cpp_arc_to(SkPathBuilder *pb, const SkPoint &p1, 
                              const SkPoint &p2, float radius)
{
   pb->arcTo(p1, p2, radius);
}

void cpp_arc(SkPathBuilder *pb,
   const SkPoint &p, float radius,
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
   pb->arcTo(oval, start_deg, sweep, false);
}

void cpp_add_rect(SkPathBuilder *pb, const SkRect &r)
{
   pb->addRect(r);
}

void cpp_add_round_rect(SkPathBuilder *pb, const SkRect &rect, float radius)
{
   pb->addRRect(SkRRect::MakeRectXY(rect, radius, radius));
}

void cpp_add_circle(SkPathBuilder *pb, float cx, float cy, float r)
{
   pb->addCircle(cx, cy, r);
}

// void canvas::add_path(path const& p)
// {
//    _state->path() = *p.impl();
// }

// void clear_rect(StateCanvas *cnv, float left, float top, float right, float bottom)
// {
//    cnv->_canvas->drawRect({left, top, right, bottom}, cnv->_state->_clear_paint);
// }
 
void quadratic_curve_to(SkPathBuilder *pb, const SkPoint& p, const SkPoint& end)
{
   pb->quadTo(p, end);
}

void bezier_curve_to(SkPathBuilder *pb, const SkPoint& p, 
                        const SkPoint& p1, const SkPoint& end)
{
   pb->cubicTo(p, p1, end);
}
}