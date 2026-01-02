module wayland.seat;

import wayland.internal.core;
import wayland.display;
import wayland_import;
import wayland.logger;
import wayland.internal.keymapper;

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
        if (m_mapper && m_mapper.utf8(utf8buf) > 0)
            return utf8buf;
        
        return "";
    }

private:
    Proxy!(wl_keyboard, WL_KEYBOARD_RELEASE) m_native;
    KeyMapper m_mapper;

    char[16] utf8buf;

    this(wl_keyboard* ptr, KeyMapper key_map)
    {
        m_native = ptr;
        m_mapper = key_map;

        Display.instance.kb_repeat = Timer((){
            auto seat = Seat.get();
            seat.m_focused_surf.key(seat.m_keyboard);
        })
    }

    ~this()
    {
        Display.instance.kb_repeat = Timer;
    }
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

private:
    Proxy!(wl_pointer, WL_POINTER_RELEASE) m_native;
    wl_fixed_t x, y;

    ref const(Pointer) set(wl_fixed_t new_x, wl_fixed_t new_y)
    {x = new_x; y = new_y; return *this;}

    void opAssign(wl_pointer* ptr){m_native = ptr;}
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

enum PointerState { enter, leave, motion }

interface SensitiveLayer
{
    static void registry(Global[] list);

    void keyFocused(bool);
    void key(uint symbolcode, ref const Keyboard);
    void point(PointerState, uint32_t /*serial*/, ref const Pointer);

    void click(PointerButton /*button*/ ,
                bool         /*pressed*/,
                int          /*count*/,
                unsigned     /*key_mod*/,
                ref const Pointer);
    void scroll(int time, int axis, double value);
}

private:

final class Seat: Global
{
    mixin GlobalProxy!(Seat, wl_seat_interface, wl_seat, WL_SEAT_RELEASE);

    override void bind(wl_proxy* reg, uint name_id, uint vers) nothrow
    {
        set(reg, name_id, 4); //To do перейти на актуальную версию

        static immutable WlSeatListener seat_listener;
        if (wl_seat_add_listener(c_ptr(), 
                                cast(Callback*) &seat_listener, 
                                this) < 0)
            Logger.log(Logger.error, "failed to add seat listener");
    }

    override void dispose() 
    {
        m_keyboard = Keyboard;
        m_pointer  = null;
        m_proxy = null;
    }

    Keyboard m_keyboard;
    SensitiveLayer m_focused_surf;
    
    // default delay = 250ms rate = 2 characters per second
    uint  delay_sec;
    ulong delay_nsec = 250_000_000;
    uint  rate_sec;
    ulong rate_nsec = 500_000_000;

    Pointer  m_pointer;
    SensitiveLayer m_hovered_surf;

    //double click handling
    uint m_last_time;
    time_t m_stamp;
    uint m_last_released_button;
    int m_count_click;
}

immutable WlKeyboardListener keyboard_listener;
immutable WlPointerListener  pointer_listener;

extern(C) nothrow {

struct WlSeatListener 
{
    auto capabilities = (void* data, wl_seat* wlseat, uint flags){

        auto seat = cast(Seat) data;

//To do проверить добавление второй мыши и клавиатуры

        if ((flags & WL_SEAT_CAPABILITY_POINTER) != 0) {
            auto pointer = wl_seat_get_pointer(wlseat);
            seat.m_pointer = pointer;
            if (wl_pointer_add_listener(pointer, &pointer_listener, data) < 0)
                Logger.log(LogLevel.error, "failed to add pointer listener");
        }   
        else {
            seat.m_hovered_surf = null;
            seat.m_pointer = null;
        }

        if ((flags &  WL_SEAT_CAPABILITY_KEYBOARD) != 0){
            auto kb = wl_seat_get_keyboard(wlseat);
            if (wl_keyboard_add_listener(kb, &keyboard_listener, data) < 0)
                Logger.log(LogLevel.error, "failed to add keyboard listener");
        }
        else {
            seat.m_focused_surf = null;
            seat.m_keyboard = Keyboard;
        }
    };

    auto name = (void*, wl_seat*, const (char)* name){
        Logger.log(LogLevel.info, "Seat connected, name: %s", name);
    };
}

struct WlKeyboardListener
{
    auto keymap = (void *data, wl_keyboard* wlkb,
                   uint format, int fd, uint size){

        auto seat = cast(Seat) data;

        if (format == WL_KEYBOARD_KEYMAP_FORMAT_XKB_V1){

            try {
                seat.m_keyboard = Keyboard(wlkb, new XkbMapper(fd, size));
            }
            catch(Exception e){
                Logger.log(LogLevel.error, "KEYMAP_FORMAT failed: %s", e.msg);
            }
        }
        else
            //To Do WL_KEYBOARD_KEYMAP_FORMAT_NO_KEYMAP
            Logger.log(LogLevel.info, "KEYMAP_FORMAT not supported, format code: %d", format);

        close(fd);
    };
    auto enter = (void *data, wl_keyboard*, uint serial,
                  wl_surface *surface, wl_array *keys){
            
        auto seat = cast(Seat)data;
        auto surf = cast(Surface)
            wl_surface_get_user_data(surface);

        seat.m_focused_surf = surf.inputHandler;
        if (seat.m_focused_surf !is null)
            seat.m_focused_surf.keyFocused(true);
    };
    auto leave = (void *data, wl_keyboard *wl_kd, uint,
                wl_surface*){
            
        auto seat = cast(Seat)data;

        if (seat.m_focused_surf !is null){

            seat.m_focused_surf.keyFocused(false);
            seat.m_focused_surf = null;

            itimerspec timer;
            Display.instance.kb_repeat.set_time(timer);
        }
    };
    auto key = (void* data, wl_keyboard* wl_kd, uint /*serial*/,
              uint time, uint key, uint state){

        auto seat = cast(Seat)data;
        auto mapper = seat.m_keyboard.m_mapper;
            
        if (seat.m_focused_surf !is null){

            itimerspec spec;

            if (state == WL_KEYBOARD_KEY_STATE_PRESSED) {

                if (mapper.mayRepeats(key)){
                    spec.it_value.tv_sec = seat.delay_sec;
                    spec.it_value.tv_nsec = seat.delay_nsec;

                    spec.it_interval.tv_sec = seat.rate_sec;
                    spec.it_interval.tv_nsec = seat.rate_nsec;
                }

                uint sym;
                if (mapper.keySymbol(key, sym))
                    seat.m_focused_surf.key(sym, seat.m_keyboard);
            }

            Display.instance.kb_repeat.set_time(spec);
        }
    };
    auto modifiers = (void *data, wl_keyboard *, uint /*serial*/,
                        uint mods_depressed, //which key
                        uint mods_latched,
                        uint mods_locked,
                        uint group){

        auto mapper = cast(Seat)data.m_keyboard.m_mapper;

        mapper.updateMask(mods_depressed, mods_latched, mods_locked, group);
            
    };
    auto repeat_info = (void *data, wl_keyboard *wl_kd,
                          int rate, int delay){
            
        auto seat = cast(Seat)data;

        /**
        * rate - generation speed (number of characters in sec)
        * delay - number of ms during which you need to hold the key before the repeat starts
        */
        if (delay <= 250){
            seat.delay_sec  = 0;
            seat.delay_nsec = 250_000_000;
        }
        else{
            seat.delay_sec  = delay / 1_000;
            seat.delay_nsec = (msec_delay % 1_000) * 1_000_000;
        }

        if (rate > 1){
            seat.rate_nsec = 1_000_000_000 / rate;
            seat.rate_sec = 0;
        }
        else{
            seat.rate_nsec = 0;
            seat.rate_sec = 1;
        }

        Logger.log(Logger.info, "repeat_info delay %i ms, rate %i per second", delay, rate);
    };
}

struct WlPointerListener {
    auto enter = (void *data, wl_pointer *pointer,
                uint serial, wl_surface *surface,
                wl_fixed_t sx, wl_fixed_t sy)
    {
        // Happens in the case we just destroyed the surface.
        if (surface is null) return;

        auto seat = cast(Seat)data;
        auto surf = cast(Surface) wl_surface_get_user_data(surface);

        seat.m_hovered_surf = surf.inputHandler;

        if (seat.m_hovered_surf !is null)
            seat.m_hovered_surf.point(PointerState.enter, 0, seat.m_pointer.set(sx, sy));
    };
    auto leave = (void *data, wl_pointer *pointer,
                uint serial, wl_surface *surface)
    {
        auto seat = cast(Seat)data;

        if (seat.m_hovered_surf) {

            seat.m_hovered_surf.point(PointerState.leave, 0, seat.m_pointer);
            seat.m_hovered_surf = null;
        }
    };
    auto motion = (void *data, wl_pointer *pointer,
                 uint time, wl_fixed_t sx, wl_fixed_t sy)
    {
        auto seat = cast(Seat)data;

        if (seat.m_hovered_surf)
            seat.m_hovered_surf.point(PointerState.motion, time, seat.m_pointer.set(sx, sy));
    };
    auto button = (void *data, wl_pointer *pointer,
                 uint serial, uint time, uint button,
                 uint state)
    {
        auto seat = cast(Seat)data;

        if (seat.m_hovered_surf) {

            /* count click */
            timespec now;
            clock_gettime(CLOCK_MONOTONIC, &now);

            if (state == WL_POINTER_BUTTON_STATE_PRESSED){

                if (seat.m_last_released_button == button &&
                    now.tv_sec == seat.m_stamp &&
                    time - seat.m_last_time <= 300)
                    seat.m_count_click += 1;
                else
                    seat.m_count_click = 1;

                auto key = seat.m_keyboard.modifiers(Mods.effective);

                seat.m_hovered_surf.click(cast(PointerButton)button, true,
                                            seat.m_count_click, 
                                            key,
                                            seat.m_pointer);
            }
            else {
                seat.m_last_released_button = button;
                seat.m_last_time = time;
                seat.m_stamp = now.tv_sec;
                seat.m_hovered_surf.click(cast(PointerButton)button, 
                                            false, 0, 0, seat.m_pointer);
            }
        }
    };
    auto axis = (void *data, wl_pointer *pointer,
               uint time, uint axis, wl_fixed_t value)
    {
        auto seat = cast(Seat)data;

        if (seat.m_hovered_surf)
            seat.m_hovered_surf.scroll(time, axis, wl_fixed_to_double(value));
    }
}

}