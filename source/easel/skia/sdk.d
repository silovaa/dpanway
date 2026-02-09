module easel.skia.sdk;

struct StateCanvas;
struct StateSurface;
struct PathBuilder;

struct SkPath
{
    // Конструктор копирования (современный D)
    this(ref return scope inout typeof(this) src) inout @nogc
    {
        sk_path_copy(cast(SkPath*)&this, cast(const SkPath*)&src);
    }

    ~this() @nogc nothrow
    {
        sk_path_destruct(&this);
    }

    bool includes(float x, float y) const;
    void reset() @nogc;

private:
    void* data;
    ubyte fFillType;
    bool  fIsVolatile;
} 

private extern(C++) @nogc nothrow {
    void sk_path_copy(SkPath* dst, const(SkPath)* src);
    void sk_path_destruct(SkPath* path);
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

mixin template ApiMethod(ImplType, RetT, string name, Args...) {
    mixin(() {
        import std.traits : isAggregateType, fullyQualifiedName;
        import std.format : format;
        import std.range : iota;
        import std.array : join;

        // 1. Формируем типы для C++ декларации (extern)
        string[] cppArgs;
        cppArgs ~= ImplType.stringof ~ " h"; // Первый аргумент — контекст (handle)
        
        foreach(i, T; Args) {
            enum isStruct = isAggregateType!T;
            enum isEnum = is(T == enum);
            
            // Для C++ биндинга энумы передаем как int
            string cppType = isEnum ? "int" : fullyQualifiedName!T;
            string attr = isStruct ? "const ref " : "";
            
            cppArgs ~= format("%s%s arg%d", attr, cppType, i);
        }

        // 2. Параметры для D-метода (обертки)
        string[] dParams;
        string[] callArgs;
        callArgs ~= "this.impl"; // Передаем внутренний указатель в C++

        foreach(i, T; Args) {
            string attr = isAggregateType!T ? "const ref " : "";
            dParams ~= format("%s%s a%d", attr, fullyQualifiedName!T, i);
            
            if (is(T == enum))
                callArgs ~= format("cast(int) a%d", i);
            else
                callArgs ~= format("a%d", i);
        }

        return format(q{
            // Объявление внешней C++ функции (должна быть в canvas_impl.cpp)
            private extern(C++) static %1$s cpp_%2$s(%3$s) @nogc;

            // D-метод
            %4$s %2$s(%5$s) @nogc {
                %6$s cast(%4$s) cpp_%2$s(%7$s);
            }
        },
        is(RetT == enum) ? "int" : fullyQualifiedName!RetT, // 1: C++ Return
        name,                                              // 2: Name
        cppArgs.join(", "),                                // 3: C++ Signature
        fullyQualifiedName!RetT,                           // 4: D Return
        dParams.join(", "),                                // 5: D Signature
        is(RetT == void) ? "" : "return",                  // 6: return keyword
        callArgs.join(", ")                                // 7: Call args
        );
    }());
}

mixin template ApiSetter(ImplType, string name, T) {
    mixin(() {
        import std.traits : isAggregateType, fullyQualifiedName;
        import std.format : format;

        enum isEnum = is(T == enum);
        enum isStruct = isAggregateType!T;

        string cppType = isEnum ? "int" : fullyQualifiedName!T;
        string dAttr = isStruct ? "const ref " : "";
        string callValue = isEnum ? format("cast(%s) value", cppType) : "value";

        return format(q{
            private extern(C++) static void cpp_set_%1$s(%2$s h, %3$s%4$s value) @nogc;

            @property void %1$s(%3$s%5$s value) @nogc {
                cpp_set_%1$s(this.impl, %6$s);
            }
        }, 
        name,               // 1
        ImplType.stringof,  // 2
        dAttr,              // 3
        cppType,            // 4
        fullyQualifiedName!T, // 5
        callValue           // 6
        );
    }());
}

mixin template ApiProperty(ImplType, string name, T) {
    mixin(() {
        import std.traits : isAggregateType, fullyQualifiedName;
        import std.format : format;

        enum isEnum = is(T == enum);
        enum isStruct = isAggregateType!T;

        // Определяем тип для стороны C++
        // Если enum, передаем как int (стандарт для большинства C++ API)
        string cppType = isEnum ? "int" : fullyQualifiedName!T;
        
        // Определяем атрибут передачи (структуры по ссылке, остальное по значению)
        string dAttr = isStruct ? "const ref " : "";
        
        // Логика вызова сеттера:
        // Для структур передаем 'value' напрямую, чтобы работал 'ref'.
        // Для enum выполняем cast в базовый тип.
        string callValue = (isEnum) 
            ? format("cast(%s) value", cppType) 
            : "value";

        return format(q{
            /** C++ Bridge Declarations **/
            private extern(C++) static %2$s cpp_get_%1$s(%3$s h) @nogc;
            private extern(C++) static void cpp_set_%1$s(%3$s h, %4$s%2$s value) @nogc;

            /** D Property Interface **/
            @property %5$s %1$s() @nogc {
                // Вызываем C++ геттер и кастуем результат обратно в тип D (T)
                return cast(%5$s) cpp_get_%1$s(this.impl);
            }

            @property void %1$s(%4$s%5$s value) @nogc {
                // Вызываем C++ сеттер
                cpp_set_%1$s(this.impl, %6$s);
            }
        }, 
        name,               // %1: имя свойства
        cppType,            // %2: тип на стороне C++
        ImplType.stringof,  // %3: тип реализации (handle)
        dAttr,              // %4: "const ref " или пусто
        fullyQualifiedName!T, // %5: полный тип D
        callValue           // %6: выражение для передачи в функцию
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