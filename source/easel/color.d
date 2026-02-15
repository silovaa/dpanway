module easel.color;

import std.algorithm : min;
import std.stdint;

import easel.skia.sdk: ColorImpl;

struct Color {
    
    ColorImpl impl;
    alias impl this;

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
    Color bisque                 = rgb(255, 228, 196);
    Color black                  = rgb(0, 0, 0);
    Color blanched_almond        = rgb(255, 235, 205);
    Color blue                   = rgb(0, 0, 255);
    Color blue_violet            = rgb(138, 43, 226);
    Color brown                  = rgb(165, 42, 42);
    Color burly_wood             = rgb(222, 184, 135);
    Color cadet_blue             = rgb(95, 146, 158);
    Color chartreuse             = rgb(127, 255, 0);
    Color chocolate              = rgb(210, 105, 30);
    Color coral                  = rgb(255, 114, 86);
    Color cornflower_blue        = rgb(34, 34, 152);
    Color corn_silk              = rgb(255, 248, 220);
    Color cyan                   = rgb(0, 255, 255);
    Color dark_goldenrod         = rgb(184, 134, 11);
    Color dark_green             = rgb(0, 86, 45);
    Color dark_khaki             = rgb(189, 183, 107);
    Color dark_olive_green       = rgb(85, 86, 47);
    Color dark_orange            = rgb(255, 140, 0);
    Color dark_orchid            = rgb(139, 32, 139);
    Color dark_salmon            = rgb(233, 150, 122);
    Color dark_sea_green         = rgb(143, 188, 143);
    Color dark_slate_blue        = rgb(56, 75, 102);
    Color dark_slate_gray        = rgb(47, 79, 79);
    Color dark_turquoise         = rgb(0, 166, 166);
    Color dark_violet            = rgb(148, 0, 211);
    Color deep_pink              = rgb(255, 20, 147);
    Color deep_sky_blue          = rgb(0, 191, 255);
    Color dim_gray               = rgb(84, 84, 84);
    Color dodger_blue            = rgb(30, 144, 255);
    Color firebrick              = rgb(142, 35, 35);
    Color floral_white           = rgb(255, 250, 240);
    Color forest_green           = rgb(80, 159, 105);
    Color gains_boro             = rgb(220, 220, 220);
    Color ghost_white            = rgb(248, 248, 255);
    Color gold                   = rgb(218, 170, 0);
    Color goldenrod              = rgb(239, 223, 132);
    Color green                  = rgb(0, 255, 0);
    Color green_yellow           = rgb(173, 255, 47);
    Color honeydew               = rgb(240, 255, 240);
    Color hot_pink               = rgb(255, 105, 180);
    Color indian_red             = rgb(107, 57, 57);
    Color ivory                  = rgb(255, 255, 240);
    Color khaki                  = rgb(179, 179, 126);
    Color lavender               = rgb(230, 230, 250);
    Color lavender_blush         = rgb(255, 240, 245);
    Color lawn_green             = rgb(124, 252, 0);
    Color lemon_chiffon          = rgb(255, 250, 205);
    Color light_blue             = rgb(176, 226, 255);
    Color light_coral            = rgb(240, 128, 128);
    Color light_cyan             = rgb(224, 255, 255);
    Color light_goldenrod        = rgb(238, 221, 130);
    Color light_goldenrod_yellow = rgb(250, 250, 210);
    Color light_gray             = rgb(168, 168, 168);
    Color light_pink             = rgb(255, 182, 193);
    Color light_salmon           = rgb(255, 160, 122);
    Color light_sea_green        = rgb(32, 178, 170);
    Color light_sky_blue         = rgb(135, 206, 250);
    Color light_slate_blue       = rgb(132, 112, 255);
    Color light_slate_gray       = rgb(119, 136, 153);
    Color light_steel_blue       = rgb(124, 152, 211);
    Color light_yellow           = rgb(255, 255, 224);
    Color lime_green             = rgb(0, 175, 20);
    Color linen                  = rgb(250, 240, 230);
    Color magenta                = rgb(255, 0, 255);
    Color maroon                 = rgb(143, 0, 82);
    Color medium_aquamarine      = rgb(0, 147, 143);
    Color medium_blue            = rgb(50, 50, 204);
    Color medium_forest_green    = rgb(50, 129, 75);
    Color medium_goldenrod       = rgb(209, 193, 102);
    Color medium_orchid          = rgb(189, 82, 189);
    Color medium_purple          = rgb(147, 112, 219);
    Color medium_sea_green       = rgb(52, 119, 102);
    Color medium_slate_blue      = rgb(106, 106, 141);
    Color medium_spring_green    = rgb(35, 142, 35);
    Color medium_turquoise       = rgb(0, 210, 210);
    Color medium_violet_red      = rgb(213, 32, 121);
    Color midnight_blue          = rgb(47, 47, 100);
    Color mint_cream             = rgb(245, 255, 250);
    Color misty_rose             = rgb(255, 228, 225);
    Color moccasin               = rgb(255, 228, 181);
    Color navajo_white           = rgb(255, 222, 173);
    Color navy                   = rgb(35, 35, 117);
    Color navy_blue              = rgb(35, 35, 117);
    Color old_lace               = rgb(253, 245, 230);
    Color olive_drab             = rgb(107, 142, 35);
    Color orange                 = rgb(255, 135, 0);
    Color orange_red             = rgb(255, 69, 0);
    Color orchid                 = rgb(239, 132, 239);
    Color pale_goldenrod         = rgb(238, 232, 170);
    Color pale_green             = rgb(115, 222, 120);
    Color pale_turquoise         = rgb(175, 238, 238);
    Color pale_violet_red        = rgb(219, 112, 147);
    Color papaya_whip            = rgb(255, 239, 213);
    Color peach_puff             = rgb(255, 218, 185);
    Color peru                   = rgb(205, 133, 63);
    Color pink                   = rgb(255, 181, 197);
    Color plum                   = rgb(197, 72, 155);
    Color powder_blue            = rgb(176, 224, 230);
    Color purple                 = rgb(160, 32, 240);
    Color red                    = rgb(255, 0, 0);
    Color rosy_brown             = rgb(188, 143, 143);
    Color royal_blue             = rgb(65, 105, 225);
    Color saddle_brown           = rgb(139, 69, 19);
    Color salmon                 = rgb(233, 150, 122);
    Color sandy_brown            = rgb(244, 164, 96);
    Color sea_green              = rgb(82, 149, 132);
    Color sea_shell              = rgb(255, 245, 238);
    Color sienna                 = rgb(150, 82, 45);
    Color sky_blue               = rgb(114, 159, 255);
    Color slate_blue             = rgb(126, 136, 171);
    Color slate_gray             = rgb(112, 128, 144);
    Color snow                   = rgb(255, 250, 250);
    Color spring_green           = rgb(65, 172, 65);
    Color steel_blue             = rgb(84, 112, 170);
    Color tan                    = rgb(222, 184, 135);
    Color thistle                = rgb(216, 191, 216);
    Color tomato                 = rgb(255, 99, 71);
    Color turquoise              = rgb(25, 204, 223);
    Color violet                 = rgb(156, 62, 206);
    Color violet_red             = rgb(243, 62, 150);
    Color wheat                  = rgb(245, 222, 179);
    Color white                  = rgb(255, 255, 255);
    Color white_smoke            = rgb(245, 245, 245);
    Color yellow                 = rgb(255, 255, 0);
    Color yellow_green           = rgb(50, 216, 56);
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