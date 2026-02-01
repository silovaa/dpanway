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

// import std.traits : Parameters;

// mixin template VoidMethod(string name, Args...) {
//     enum code = () {
//         import std.format;
//         import std.array : join;

//         string[] params;
//         string[] args;

//         // static foreach корректно работает внутри анонимных функций для CTFE
//         static foreach (i, T; Args) {
//             // Используем .stringof для получения имени типа (float, Point и т.д.)
//             params ~= format("%s v%d", T.stringof, i);
//             args   ~= format("v%d", i);
//         }

//         // Собираем строки через join — это чище, чем ручное удаление запятых
//         string paramsStr = params.join(", ");
//         string argsStr   = args.join(", ");

//         return format(q{
//             // Объявление внешней C++ функции. 
//             // CanvasImpl должен быть доступен в месте миксина.
//             private extern(C++) static void %1$s(CanvasImpl h, %2$s) @nogc;

//             // Высокоуровневый метод в D
//             void %1$s(%2$s) @nogc {
//                 %1$s(this.impl, %3$s);
//             } 
//         }, name, paramsStr, argsStr);
//     }();

//     // Отладка: выводит сгенерированный код при компиляции
//     // pragma(msg, "--- Generated code for ", name, " ---\n", code, "-----------------------");

//     mixin(code);
// }

// mixin template BoolMethod(string name, Args...) {
//     mixin(() {
//         import std.format;

//         // Формируем строку типов для сигнатуры: "T1 v1, T2 v2, ..."
//         string params;
//         string args;
//         static foreach (i, T; Args) {
//             params ~= format("%s v%d, ", T.stringof, i);
//             args   ~= format("v%d, ", i);
//         }
//         // Убираем лишнюю запятую в конце
//         if (params.length > 2) params = params[0 .. $-2];
//         if (args.length > 2)   args   = args[0 .. $-2];

//         return format(q{
//             private extern(C++) static bool %1$s(CanvasImpl h, %2$s) @nogc;

//             bool %1$s(%2$s) @nogc {
//                 return %1$s(this.impl, %3$s);
//             }
//         }, name, params, args);
//     }());
// }

import std.format;
import std.array;
import std.traits : isAggregateType;

mixin template ApiMethod(ImplType, RetType, string name, Args...) {
    mixin(() {
        string[] params;
        string[] args;
        static foreach (i, T; Args) {
            params ~= format("%s v%d", T.stringof, i);
            args   ~= format("v%d", i);
        }

        // Определяем, нужно ли слово return
        string returnStmt = (RetType.stringof != "void") ? "return " : "";

        return format(q{
            // Объявление внешней C++ функции с префиксом cpp_
            private extern(C++) static %2$s cpp_%1$s(%5$s h, %3$s) @nogc;

            // Публичный метод в D
            %2$s %1$s(%3$s) @nogc {
                %4$s cpp_%1$s(this.impl, %6$s);
            } 
        }, 
        name,               // %1
        RetType.stringof,    // %2
        params.join(", "),  // %3
        returnStmt,         // %4
        ImplType.stringof,   // %5
        args.join(", ")     // %6
        );
    }());
}

mixin template ApiSetter(ImplType, string name, T) {
    mixin(() {
        enum isRef = isAggregateType!T;
        string attr = isRef ? "const ref " : "";
        string typeName = is(T == enum) ? "int" : T.stringof;

        // Мы используем T.stringof для типа параметра
        return format(q{
            // Внешняя C++ функция
            private extern(C++) static void cpp_set_%1$s(%3$s h, %4$s%5$s value) @nogc;

            // D-свойство (Setter)
            @property void %1$s(%4$s%2$s value) @nogc {
                cpp_set_%1$s(this.impl, cast(%5$s) value);
            }
        }, name, T.stringof, ImplType.stringof, attr, typeName);
    }());
}

mixin template ApiProperty(ImplType, string name, T) {
    mixin(() {
        import std.traits : isAggregateType;
        import std.format : format;

        enum isEnum = is(T == enum);
        enum isStruct = isAggregateType!T;

        string cppType = isEnum ? "int" : T.stringof;
        
        // В D 'const ref' соответствует 'const T&' в C++
        string dAttr = isStruct ? "const ref " : "";
        
        string callValue = isEnum ? format("cast(%s) value", cppType) : "value";

        return format(q{
            // --- C++ Declarations (через призму D-синтаксиса) ---
            private extern(C++) static %2$s cpp_get_%1$s(%3$s h) @nogc;
            private extern(C++) static void cpp_set_%1$s(%3$s h, %4$s%2$s value) @nogc;

            // --- D Property Interface ---
            @property %5$s %1$s() @nogc {
                return cast(%5$s) cpp_get_%1$s(this.impl);
            }

            @property void %1$s(%6$s%5$s value) @nogc {
                cpp_set_%1$s(this.impl, %7$s);
            }
        }, 
        name,               // %1
        cppType,            // %2
        ImplType.stringof,  // %3
        dAttr,              // %4 - здесь будет "const ref " для структур
        T.stringof,         // %5
        isStruct ? "const ref " : "", // %6
        callValue           // %7
        );
    }());
}

mixin template ImplAccessor(ImplType) {
    private ImplType m_impl;

    // Геттер с проверкой
    @property @nogc
    private ImplType impl() {
        assert(m_impl !is null, "Canvas implementation (m_impl) is null");
        return m_impl;
    }

    @property @nogc
    private void impl(ImplType h) {
        m_impl = h;
    }
}