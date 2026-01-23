module easel.rect;

import std.traits : isNumeric;

// Используем простые структуры для point и extent
struct Point { float x, y; }
alias Extent = Point;

struct Rect 
{
    float left = 0, top = 0, right = 0, bottom = 0;

    // Конструкторы в D объявляются через this
    // В 2026 году все функции по умолчанию стремятся к @safe pure nothrow
    @safe pure nothrow @nogc:

    this(float left, float top, float right, float bottom) {
        this.left = left;
        this.top = top;
        this.right = right;
        this.bottom = bottom;
    }

    this(Point origin, float right, float bottom) {
        this(origin.x, origin.y, right, bottom);
    }

    this(Point top_left, Point bottom_right) {
        this(top_left.x, top_left.y, bottom_right.x, bottom_right.y);
    }

    this(float left, float top, Extent size) {
        this(left, top, left + size.x, top + size.y);
    }

    // this(Point origin, Extent size) {
    //     this(origin.x, origin.y, origin.x + size.x, origin.y + size.y);
    // }

    @property {
        float width() const { return right - left; }
        void width(float w) { right = left + w; }

        float height() const { return bottom - top; }
        void height(float h) { bottom = top + h; }

        Extent size() const { return Extent(width, height); }
        void size(Extent s) { width = s.x; height = s.y; }

        Point top_left() const { return Point(left, top); }
        Point bottom_right() const { return Point(right, bottom); }
    }

    // Проверки
    bool is_empty() const { return left == right || top == bottom; }
    bool is_valid() const { return left <= right && top <= bottom; }

    bool includes(Point p) const {
        return (p.x >= left && p.x <= right && p.y >= top && p.y <= bottom);
    }

    // Операции, возвращающие новый Rect
    Rect move(float dx, float dy) const {
        return Rect(left + dx, top + dy, right + dx, bottom + dy);
    }

    Rect move_to(float x, float y) const {
        return move(x - left, y - top);
    }

    Rect inset(float x_inset, float y_inset) const {
        auto r = Rect(left + x_inset, top + y_inset, right - x_inset, bottom - y_inset);
        return r.is_valid ? r : Rect.init; // Rect.init в D — это все нули
    }

    // Операторы перегружаются через opBinary и opEquals
    bool opEquals(const Rect other) const {
        return left == other.left && top == other.top && 
               right == other.right && bottom == other.bottom;
    }
}

// Свободные функции (Free Functions)
@safe pure nothrow @nogc:

bool is_same_size(Rect a, Rect b) {
    return a.width == b.width && a.height == b.height;
}

Point center_point(Rect r) {
    return Point(r.left + r.width / 2.0f, r.top + r.height / 2.0f);
}

float area(Rect r) {
    return r.width * r.height;
}

// Использование шаблонов для работы с осями (замена C++ axis enum)
enum Axis { x, y }

float axis_extent(Rect r, Axis a) {
    return (a == Axis.x) ? r.width : r.height;
}

// В D можно использовать ref return для получения ссылки на поле по оси
ref float axis_min(return ref Rect r, Axis a) {
    return (a == Axis.x) ? r.left : r.top;
}

ref float axis_max(return ref Rect r, Axis a) {
    return (a == Axis.x) ? r.right : r.bottom;
}