#pragma once

#include <SkPath.h>
#include <SkPathBuilder.h>
#include <include/effects/SkGradient.h>

using PathBuilder = SkPathBuilder;

PathBuilder* make_builder(uint8_t fill_rule)
{
   auto rule = static_cast<SkPathFillType>(fill_rule);
   return new PathBuilder(rule);
}

void destroy_builder(PathBuilder* ptr){delete ptr;}

SkPath detach(SkPathBuilder *pb){return pb->detach();}
SkPath snapshot(const SkPathBuilder *pb) const {return pb->snapshot();}