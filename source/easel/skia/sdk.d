module easel.skia.sdk;

struct StateCanvas;
struct StateSurface;
struct PathBuilder;

struct SkPath
{
    // Конструктор копирования (современный D)
    this(ref return scope inout typeof(this) src) inout 
    {
        sk_path_copy(cast(SkPath*)&this, cast(const SkPath*)&src);
    }

    ~this() 
    {
        sk_path_destruct(&this);
    }

    bool includes(float x, float y) const;
    void reset();

private:
    void* data;
    ubyte fFillType;
    bool  fIsVolatile;

    extern(C++) @nogc nothrow {
        static void sk_path_copy(SkPath* dst, const(SkPath)* src);
        static void sk_path_destruct(SkPath* path);
    }
}   

// Проверка на соответствие ABI (64-бит)
static assert(SkPath.sizeof == 16); 

alias CanvasImpl  = StateCanvas*;
alias SurfaceImpl = StateSurface*;
alias PathBuilderImpl = PathBuilder*;
alias Path = SkPath;

import std.traits : Parameters;

mixin template VoidMethod(string name, Args...) {
    enum code = () {
        import std.format;
        import std.array : join;

        string[] params;
        string[] args;

        // static foreach корректно работает внутри анонимных функций для CTFE
        static foreach (i, T; Args) {
            // Используем .stringof для получения имени типа (float, Point и т.д.)
            params ~= format("%s v%d", T.stringof, i);
            args   ~= format("v%d", i);
        }

        // Собираем строки через join — это чище, чем ручное удаление запятых
        string paramsStr = params.join(", ");
        string argsStr   = args.join(", ");

        return format(q{
            // Объявление внешней C++ функции. 
            // CanvasImpl должен быть доступен в месте миксина.
            private extern(C++) static void %1$s(CanvasImpl h, %2$s) @nogc;

            // Высокоуровневый метод в D
            void %1$s(%2$s) @nogc {
                %1$s(this.impl, %3$s);
            } 
        }, name, paramsStr, argsStr);
    }();

    // Отладка: выводит сгенерированный код при компиляции
    // pragma(msg, "--- Generated code for ", name, " ---\n", code, "-----------------------");

    mixin(code);
}

mixin template BoolMethod(string name, Args...) {
    mixin(() {
        import std.format;

        // Формируем строку типов для сигнатуры: "T1 v1, T2 v2, ..."
        string params;
        string args;
        static foreach (i, T; Args) {
            params ~= format("%s v%d, ", T.stringof, i);
            args   ~= format("v%d, ", i);
        }
        // Убираем лишнюю запятую в конце
        if (params.length > 2) params = params[0 .. $-2];
        if (args.length > 2)   args   = args[0 .. $-2];

        return format(q{
            private extern(C++) static bool %1$s(CanvasImpl h, %2$s) @nogc;

            bool %1$s(%2$s) @nogc {
                return %1$s(this.impl, %3$s);
            }
        }, name, params, args);
    }());
}