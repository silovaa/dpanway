module wayland.logger;

import core.stdc.stdio : fprintf, stderr, vfprintf;

enum LogLevel { info, error, debug_ }

struct Logger {
    
static @safe nothrow @nogc:
    void log(LogLevel level, string fmt, ...) 
    {
        // Используем printf-подобные функции, так как они не кидают исключений
        const char* prefix;
        final switch (level) {
            case LogLevel.info:   prefix = "INFO"; break;
            case LogLevel.error:  prefix = "ERROR"; break;
            case LogLevel.debug_: prefix = "DEBUG"; break;
        }

        import core.stdc.stdarg : va_start, va_end, va_list;

        va_list args;
        va_start(args, fmt);
        
        fprintf(stderr, "[%s] %.*s\n", prefix);
        vfprintf(stderr, fmt.ptr, args); // fmt должен быть C-строкой (null-terminated)
        fprintf(stderr, "\n");
        
        va_end(args);
    }
}
