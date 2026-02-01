#pragma once

#include <SkPath.h>
#include <SkPathBuilder.h>
#include <include/effects/SkGradient.h>

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
SkPath cpp_builder_snapshot(const SkPathBuilder *pb) const {return pb->snapshot();}
void cpp_builder_reset(SkPathBuilder *pb){pb.reset();}

}