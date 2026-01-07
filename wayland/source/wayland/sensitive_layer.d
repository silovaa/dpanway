module wayland.sensitive_layer;

import wayland.internal.keymapper: ModSet, KeyMapper;
import wayland.internal.core;
import wayland.display;

alias Mods = ModSet;

struct Keyboard
{
    @disable this(this);
    
    uint modifiers(Mods group) const
    {
        return m_mapper ? m_mapper.modifiers(group) : 0;
    }

    string utf8() const
    {
        if (m_mapper && m_mapper.utf8(cast(char[])utf8buf[]) > 0)
            return utf8buf;
        
        return "";
    }

    uint symbol() const
    {
        return m_symbol;
    }

package(wayland):
    this(wl_keyboard* ptr, KeyMapper key_map)
    {
        m_native = ptr;
        m_mapper = key_map;

        Display.instance.kb_repeat = Timer((){
            m_focused_surf.key(this);
        });
    }

    ~this()
    {
        Display.instance.kb_repeat = Timer();
    }

    void emit_key(uint raw_key)
    {
        assert(m_focused_surf);

        if (m_mapper.keySymbol(raw_key, m_symbol))
            m_focused_surf.key(this);
    }

    void emit_focus(bool focused)
    {
        assert(m_focused_surf);

        m_focused_surf.keyFocused(focused);
    }

    void reset() nothrow @nogc
    {
        Display.instance.kb_repeat = Timer();
        m_mapper = null;
        m_focused_surf = null;
        m_native = null;
    }

    KeyMapper m_mapper;
    SensitiveLayer m_focused_surf;    

private:
    Proxy!(wl_keyboard, WL_KEYBOARD_RELEASE) m_native;

    char[16] utf8buf;
    uint m_symbol;
}

struct Pointer
{
    import std.typecons: Tuple, tuple;

    Tuple!(int, int) toInt() const
    {
        return tuple(wl_fixed_to_int(x),
                     wl_fixed_to_int(y));
    }

    Tuple!(double, double) toDouble() const
    {
        return tuple(wl_fixed_to_double(x),
                     wl_fixed_to_double(y));
    }

    bool inBound(int sx, int sy, int sw, int sh) const
    {
        auto res = toInt();
        return sx > res[0] && sw < res[0] && sy > res[1] && sh < res[1];
    }

package(wayland):
    ref const(Pointer) set(wl_fixed_t new_x, wl_fixed_t new_y)
    {x = new_x; y = new_y; return this;}

    void opAssign(wl_pointer* ptr) nothrow @nogc {m_native = ptr;}

private:
    Proxy!(wl_pointer, WL_POINTER_RELEASE) m_native;
    wl_fixed_t x, y;
}

//from input-event-codes.h
//зависит от платформы, хотя на Linux и FreeBSD одинаковые
enum PointerButton {
    LEFT    =   0x110,
    RIGHT   =   0x111,
    MIDDLE	=   0x112,
    SIDE    =	0x113,
    EXTRA	=	0x114,
    FORWARD	=	0x115,
    BACK    =	0x116,
    ASK		=   0x117
}

enum PointerState { enter, leave}

interface SensitiveLayer
{
    void keyFocused(bool);
    void key(ref const(Keyboard));
    void point(PointerState, ref const(Pointer));
    void point_motion(uint, ref const(Pointer));

    void click(PointerButton /*button*/ ,
                bool         /*pressed*/,
                int          /*count*/,
                uint         /*key_mod*/,
                ref const(Pointer));
    void scroll(int time, int axis, double value);
}

