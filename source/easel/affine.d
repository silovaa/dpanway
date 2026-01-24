module easel.affine;

import std.math;
import easel.rect; 

struct AffineTransform {
    double a  = 1.0;
    double b  = 0.0;
    double c  = 0.0;
    double d  = 1.0;
    double tx = 0.0;
    double ty = 0.0;

    // Все методы по умолчанию максимально оптимизированы для компиляции
    @safe pure nothrow @nogc:

    enum AffineTransform identity = AffineTransform(1, 0, 0, 1, 0, 0);

    bool is_identity() const {
        return this == identity;
    }

    // Оператор умножения (трансформации)
    AffineTransform opBinary(string op)(const AffineTransform t2) const if (op == "*") {
        return AffineTransform(
            t2.a * a + t2.b * c,
            t2.a * b + t2.b * d,
            t2.c * a + t2.d * c,
            t2.c * b + t2.d * d,
            t2.tx * a + t2.ty * c + tx,
            t2.tx * b + t2.ty * d + ty
        );
    }

    // Применение трансформации к точке
    Point apply(Point p) const {
        return Point(
            cast(float)(a * p.x + c * p.y + tx),
            cast(float)(b * p.x + d * p.y + ty)
        );
    }

    Point apply(float x, float y) const {
        return Point(
            cast(float)(a * x + c * y + tx),
            cast(float)(b * x + d * y + ty)
        );
    }

    // Применение к массиву/срезу (D-style)
    void apply(Point[] points) const {
        foreach (ref p; points) {
            p = apply(p);
        }
    }

    // Цепочки трансформаций
    AffineTransform translate(double tx_, double ty_) const {
        return this * make_translation(tx_, ty_);
    }

    AffineTransform scale(double sx, double sy) const {
        return this * make_scale(sx, sy);
    }

    AffineTransform scale(double sc) const {
        return this * make_scale(sc, sc);
    }

    AffineTransform rotate(double rad) const {
        return this * make_rotation(rad);
    }

    AffineTransform skew(double sx, double sy) const {
        return this * make_skew(sx, sy);
    }

    AffineTransform invert() const {
        double det = a * d - c * b;
        if (det == 0) return this;

        return AffineTransform(
            d / det,
            -b / det,
            -c / det,
            a / det,
            (-d * tx + c * ty) / det,
            (b * tx - a * ty) / det
        );
    }
}

// Фабричные функции
@safe pure nothrow @nogc:

AffineTransform make_translation(double tx, double ty) {
    return AffineTransform(1, 0, 0, 1, tx, ty);
}

AffineTransform make_scale(double sx, double sy) {
    return AffineTransform(sx, 0, 0, sy, 0, 0);
}

AffineTransform make_scale(double sc) {
    return AffineTransform(sc, 0, 0, sc, 0, 0);
}

AffineTransform make_rotation(double rad) {
    auto s = sin(rad);
    auto c = cos(rad);
    return AffineTransform(c, s, -s, c, 0, 0);
}

AffineTransform make_skew(double sx, double sy) {
    return AffineTransform(1.0, tan(sx), tan(sy), 1.0, 0, 0);
}