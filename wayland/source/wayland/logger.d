module wayland.logger;

import core.stdc.stdio : fprintf, stderr, vfprintf;
import core.stdc.stdarg : va_start, va_end, va_list;

struct Logger {
    // Прямой вывод без промежуточных строк
    static void info(const char* fmt, ...) nothrow @nogc
    {
        fprintf(stderr, "[INFO]: ");

        va_list args;
        va_start(args, fmt);
        vfprintf(stderr, fmt, args);
        va_end(args);

        fprintf(stderr, "\n");
    }

    static void error(const char* fmt, ...) nothrow @nogc
    {
        fprintf(stderr, "[ERROR]: ");

        va_list args;
        va_start(args, fmt);
        vfprintf(stderr, fmt, args);
        va_end(args);

        fprintf(stderr, "\n");
    }

    static void debugf(const char* fmt, ...) nothrow @nogc
    {
        fprintf(stderr, "[DEBUG]: ");

        va_list args;
        va_start(args, fmt);
        vfprintf(stderr, fmt, args);
        va_end(args);

        fprintf(stderr, "\n");
    }
}
