module easel.color_simd;

import core.simd;

struct Color {
    // Объединяем 4 float в один векторный тип (128 бит)
    // float4 — это встроенный тип в LDC/GDC
    union {
        float4 vector;       // Для быстрых расчетов
        struct { float red, green, blue, alpha; } // Для удобного доступа
    }

    @safe pure nothrow @nogc:

    this(float r, float g, float b, float a = 1.0f) {
        // Инициализация вектора сразу 4 значениями
        vector = [r, g, b, a];
    }

    // Векторное сложение выполняется одной инструкцией CPU (например, ADDPS)
    Color opBinary(string op)(const Color o) const if (op == "+" || op == "-") {
        Color result;
        mixin("result.vector = this.vector " ~ op ~ " o.vector;");
        return result;
    }

    // Векторное умножение на скаляр
    Color opBinary(string op)(float s) const if (op == "*") {
        Color result;
        // Компилятор автоматически размножит s (broadcast) по всем компонентам
        result.vector = this.vector * s;
        return result;
    }
}