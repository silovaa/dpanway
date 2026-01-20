module easel.color;

import std.algorithm : min;
import std.stdint;

struct Color {
    float red   = 0.0f;
    float green = 0.0f;
    float blue  = 0.0f;
    float alpha = 0.0f;

    @safe pure nothrow @nogc:

    // Конструктор (alpha по умолчанию 1.0)
    this(float r, float g, float b, float a = 1.0f) {
        red = r; green = g; blue = b; alpha = a;
    }

    // Изменение прозрачности
    Color opacity(float a) const {
        return Color(red, green, blue, a);
    }

    // Изменение яркости
    Color level(float amount) const {
        return Color(red * amount, green * amount, blue * amount, alpha);
    }

    // Сравнение
    bool opEquals(const Color o) const {
        return red == o.red && green == o.green && blue == o.blue && alpha == o.alpha;
    }

    // Математические операторы (D идиоматика: opBinary)
    Color opBinary(string op)(const Color o) const if (op == "+" || op == "-") {
        // Формула смешивания из вашего C++ кода
        float newAlpha = alpha + o.alpha * (1.0f - alpha);
        mixin("return Color(red " ~ op ~ " o.red, green " ~ op ~ " o.green, blue " ~ op ~ " o.blue, newAlpha);");
    }

    // Умножение на скаляр
    Color opBinary(string op)(float s) const if (op == "*") {
        return Color(red * s, green * s, blue * s, alpha);
    }

    // Умножение скаляра на цвет (правостороннее)
    Color opBinaryRight(string op)(float s) const if (op == "*") {
        return Color(red * s, green * s, blue * s, alpha);
    }
}

// Фабричные функции (Helper Functions)
@safe pure nothrow @nogc:

Color rgb(uint32_t val) {
    return Color(((val >> 16) & 0xff) / 255.0f, ((val >> 8) & 0xff) / 255.0f, (val & 0xff) / 255.0f);
}

Color rgba(uint32_t val) {
    return Color(((val >> 24) & 0xff) / 255.0f, ((val >> 16) & 0xff) / 255.0f, 
                 ((val >> 8) & 0xff) / 255.0f, (val & 0xff) / 255.0f);
}

Color rgb(uint8_t r, uint8_t g, uint8_t b) {
    return Color(r / 255.0f, g / 255.0f, b / 255.0f);
}

Color rgba(uint8_t r, uint8_t g, uint8_t b, uint8_t a) {
    return Color(r / 255.0f, g / 255.0f, b / 255.0f, a / 255.0f);
}

Color hsl(float h, float s, float l) {
    h = min(h, 359.99f);
    float r = l, g = l, b = l;
    float v = (l <= 0.5f) ? (l * (1.0f + s)) : (l + s - l * s);
    if (v > 0) {
        float m = l + l - v;
        float sv = (v - m) / v;
        h *= 6.0f / 360.0f;
        int sextant = cast(int)h;
        float fract = h - sextant;
        float vsf = v * sv * fract;
        float mid1 = m + vsf;
        float mid2 = v - vsf;

        switch (sextant) {
            case 0: r = v; g = mid1; b = m; break;
            case 1: r = mid2; g = v; b = m; break;
            case 2: r = m; g = v; b = mid1; break;
            case 3: r = m; g = mid2; b = v; break;
            case 4: r = mid1; g = m; b = v; break;
            case 5: r = v; g = m; b = mid2; break;
            default: break;
        }
    }
    return Color(r, g, b, 1.0f);
}

// Предопределенные цвета в отдельном пространстве имен (модуле или структуре)
struct Colors {
    @safe pure nothrow @nogc static:
    Color alice_blue             = rgb(240, 248, 255);
    Color antique_white          = rgb(250, 235, 215);
    Color aquamarine             = rgb(50, 191, 193);
    Color azure                  = rgb(240, 255, 255);
    Color beige                  = rgb(245, 245, 220);
    Color black                  = rgb(0, 0, 0);
    Color blue                   = rgb(0, 0, 255);
    Color brown                  = rgb(165, 42, 42);
    Color cyan                   = rgb(0, 255, 255);
    Color gold                   = rgb(218, 170, 0);
    Color green                  = rgb(0, 255, 0);
    Color red                    = rgb(255, 0, 0);
    Color white                  = rgb(255, 255, 255);
    Color white_smoke  = rgb(245, 245, 245);
    Color yellow       = rgb(255, 255, 0);
    Color yellow_green = rgb(50, 216, 56);
}

    /**
     * Массив градаций серого.
     * В D 2026 использование статического массива через [ ... ] 
     * вычисляется во время компиляции (CTFE).
     */
    immutable Color[101] gray = [
        rgb(0, 0, 0),       rgb(3, 3, 3),       rgb(5, 5, 5),       rgb(8, 8, 8),
        rgb(10, 10, 10),    rgb(13, 13, 13),    rgb(15, 15, 15),    rgb(18, 18, 18),
        rgb(20, 20, 20),    rgb(23, 23, 23),    rgb(26, 26, 26),    rgb(28, 28, 28),
        rgb(31, 31, 31),    rgb(33, 33, 33),    rgb(36, 36, 36),    rgb(38, 38, 38),
        rgb(41, 41, 41),    rgb(43, 43, 43),    rgb(46, 46, 46),    rgb(48, 48, 48),
        rgb(51, 51, 51),    rgb(54, 54, 54),    rgb(56, 56, 56),    rgb(59, 59, 59),
        rgb(61, 61, 61),    rgb(64, 64, 64),    rgb(66, 66, 66),    rgb(69, 69, 69),
        rgb(71, 71, 71),    rgb(74, 74, 74),    rgb(77, 77, 77),    rgb(79, 79, 79),
        rgb(82, 82, 82),    rgb(84, 84, 84),    rgb(87, 87, 87),    rgb(89, 89, 89),
        rgb(92, 92, 92),    rgb(94, 94, 94),    rgb(97, 97, 97),    rgb(99, 99, 99),
        rgb(102, 102, 102), rgb(105, 105, 105), rgb(107, 107, 107), rgb(110, 110, 110),
        rgb(112, 112, 112), rgb(115, 115, 115), rgb(117, 117, 117), rgb(120, 120, 120),
        rgb(122, 122, 122), rgb(125, 125, 125), rgb(127, 127, 127), rgb(130, 130, 130),
        rgb(133, 133, 133), rgb(135, 135, 135), rgb(138, 138, 138), rgb(140, 140, 140),
        rgb(143, 143, 143), rgb(145, 145, 145), rgb(148, 148, 148), rgb(150, 150, 150),
        rgb(153, 153, 153), rgb(156, 156, 156), rgb(158, 158, 158), rgb(161, 161, 161),
        rgb(163, 163, 163), rgb(166, 166, 166), rgb(168, 168, 168), rgb(171, 171, 171),
        rgb(173, 173, 173), rgb(176, 176, 176), rgb(179, 179, 179), rgb(181, 181, 181),
        rgb(184, 184, 184), rgb(186, 186, 186), rgb(189, 189, 189), rgb(191, 191, 191),
        rgb(194, 194, 194), rgb(196, 196, 196), rgb(199, 199, 199), rgb(201, 201, 201),
        rgb(204, 204, 204), rgb(207, 207, 207), rgb(209, 209, 209), rgb(212, 212, 212),
        rgb(214, 214, 214), rgb(217, 217, 217), rgb(219, 219, 219), rgb(222, 222, 222),
        rgb(224, 224, 224), rgb(227, 227, 227), rgb(229, 229, 229), rgb(232, 232, 232),
        rgb(235, 235, 235), rgb(237, 237, 237), rgb(240, 240, 240), rgb(242, 242, 242),
        rgb(245, 245, 245), rgb(247, 247, 247), rgb(250, 250, 250), rgb(252, 252, 252),
        rgb(255, 255, 255)
    ];

    // Синоним через alias
    alias grey = gray;