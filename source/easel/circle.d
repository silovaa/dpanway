module easel.circle;

import easel.rect; // Предполагаем, что Rect и Point в этом модуле
import std.algorithm : min;

struct Circle {
    float cx = 0.0;
    float cy = 0.0;
    float radius = 0.0;

    // В D 2026 используем эти атрибуты для максимальной производительности и безопасности
    @safe pure nothrow @nogc:

    // Конструкторы
    this(float cx, float cy, float radius) {
        this.cx = cx;
        this.cy = cy;
        this.radius = radius;
    }

    this(Point c, float radius) {
        this(c.x, c.y, radius);
    }

    this(Rect r) {
        auto cp = center_point(r);
        this(cp.x, cp.y, min(r.width, r.height) / 2.0f); 
    }

    // Свойства (Properties)
    @property {
        Rect bounds() const {
            return Rect(cx - radius, cy - radius, cx + radius, cy + radius);
        }

        Point center() const {
            return Point(cx, cy);
        }
    }

    // Операторы
    bool opEquals(const Circle other) const {
        return (cx == other.cx) && (cy == other.cy) && (radius == other.radius);
    }

    // Методы, возвращающие новый экземпляр
    Circle inset(float x) const {
        return Circle(cx, cy, radius - x);
    }

    Circle move(float dx, float dy) const {
        return Circle(cx + dx, cy + dy, radius);
    }

    Circle move_to(float x, float y) const {
        return Circle(x, y, radius);
    }
}