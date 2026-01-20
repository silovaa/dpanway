module wayland.seat;

import wayland.internal.core;
import wayland.display;
import wayland.logger;

import wayland.surface;
import wayland.input_layer;

struct Seat
{
    void bind(T)(ref ProtocolStore!T prot, InputLayer handler)
    {
        if (globalValid()){
            auto ptr = prot.surface.c_ptr;
            if (ptr !is null)
                wl_surface_set_user_data(ptr, cast(void*)handler);
            else
                input = handler;
        }
    }

package(wayland):

    void setup(T)(ref ProtocolStore!T prot)
    {
        if (globalValid()){

            if (input is null) return;

            wl_surface_set_user_data(prot.surface.c_ptr, cast(void*)input);
        }
    }

    mixin GlobalFactory!SeatGlobal;

    InputLayer input;
}

private:

final class SeatGlobal: GlobalProxy!(wl_seat, wl_seat_interface, WL_SEAT_RELEASE)
{
protected:
    override void bind(wl_registry* reg, uint name_id, uint vers) 
    {
        super.bind(reg, name_id, vers); 

        if (wl_seat_add_listener(c_ptr(), &seat_listener, null) < 0)
            debug Logger.error("failed to add seat listener");
    }

    override void dispose() 
    {
        if (m_pointer !is null) 
            wl_pointer_release(m_pointer);
        if (m_keyboard !is null) 
            wl_keyboard_release(m_keyboard);
        super.dispose();
    }

    KeyMapper m_mapper;
    wl_keyboard* m_keyboard;
    
    // default delay = 250ms rate = 2 characters per second
    uint  delay_sec;
    ulong delay_nsec = 250_000_000;
    uint  rate_sec;
    ulong rate_nsec = 500_000_000;

    wl_pointer*  m_pointer;

    //double click handling
    uint m_last_time;
    time_t m_stamp;
    uint m_last_released_button;
    int m_count_click;
}

__gshared wl_seat_listener seat_listener = {
    capabilities: &cb_capabilities,
    name:         &cb_name
};

__gshared wl_keyboard_listener keyboard_listener = {
    &cb_kbkeymap,
    &cb_kbenter,
    &cb_kbleave,
    &cb_kbkey,
    &cb_kbmodifiers,
    &cb_kbrepeat_info
};

__gshared wl_pointer_listener pointer_listener = {
    enter:  &cb_pointer_enter,
    leave:  &cb_pointer_leave,
    motion: &cb_pointer_motion,
    button: &cb_pointer_button,
    axis  : &cb_pointer_axis,
    frame : &cb_pointer_frame,                  //since 5
    axis_source: &cb_axis_source,       //since 5
    axis_stop  : &cb_axis_stop,         //since 5
    axis_discrete: &cb_axis_discrete,   //since 5
    axis_value120: &cb_axis_value120,   //since 8
    axis_relative_direction: &cb_axis_relative_direction    //since 9
};

extern(C) nothrow {

import std.format: format;

void cb_capabilities(void*, wl_seat* wlseat, uint flags) 
{
    auto seat = Seat.get();
    try{
        if ((flags & WL_SEAT_CAPABILITY_POINTER) != 0) {

            //To do может ли возникнуть такая ситуация? Вероятно для 2-3 мыши
            if (seat.m_pointer is null){
                seat.m_pointer = wl_seat_get_pointer(wlseat);
                if (wl_pointer_add_listener(seat.m_pointer, &pointer_listener, null) < 0) 
                    debug Logger.error("failed to add pointer listener");
            }
        }
        else 
            if (seat.m_pointer !is null) {
                wl_pointer_release(seat.m_pointer);
                seat.m_pointer = null;
            }

        if ((flags &  WL_SEAT_CAPABILITY_KEYBOARD) != 0){

            //То же самое что и для мыши
            if (seat.m_keyboard is null){
                seat.m_keyboard = wl_seat_get_keyboard(wlseat);
                if (wl_keyboard_add_listener(seat.m_keyboard, &keyboard_listener, null) < 0)
                    debug Logger.error("failed to add keyboard listener");
            }
        }
        else 
            if (seat.m_keyboard !is null) {
                wl_keyboard_release(seat.m_keyboard);
                seat.m_keyboard = null;
            }
    }
    catch(Exception e){
                Logger.error("Seat failed: %s", e.msg);
    }
}

void cb_name(void*, wl_seat*, const(char)* name) @nogc
{
    debug Logger.info("Seat connected, name: %s", name);
} 

// keyboard_listener ///////////////////////////////////////////////////////////////////

void cb_kbkeymap (void *data, wl_keyboard* wlkb,
                uint kbformat, int fd, uint size)
{
    auto seat = Seat.get();

    if (kbformat == WL_KEYBOARD_KEYMAP_FORMAT_XKB_V1){

        try {
            seat.m_mapper = new XkbMapper(fd, size);
            Display.instance.kb_repeat = Timer(seat.m_mapper);
        }
        catch(Exception e){
            Logger.error("KEYMAP_FORMAT failed: %s", e.msg);
        }
    }
    else
        //To Do WL_KEYBOARD_KEYMAP_FORMAT_NO_KEYMAP
        debug Logger.error("KEYMAP_FORMAT not supported, format code: %d",kbformat);

    close(fd);
}

void cb_kbenter(void *data, wl_keyboard* wlkb, uint serial,
            wl_surface *surface, wl_array* keys)
{            
    try{
        auto input = cast(InputLayer)
            wl_surface_get_user_data(surface);

        if(input !is null){
        
            wl_keyboard_set_user_data(wlkb, cast(void*)input);

            input.keyFocused(true);
            //TO DO развернуть и передать wl_array* keys
        }
    }
    catch(Exception e)
        Logger.error("Callback keyboard enter failed: %s", e.msg);
}

void cb_kbleave(void *data, wl_keyboard* wlkb, uint, wl_surface*)
{
    try{
        auto input = cast(InputLayer)data;

        if (input !is null){

            wl_keyboard_set_user_data(wlkb, null);
            input.keyFocused(false);

            itimerspec timer;
            Display.instance.kb_repeat.set_time(timer, null);
        }
    }
    catch(Exception e)
        Logger.error("Callback keyboard leave failed: %s", e.msg);
}

void cb_kbkey(void* data, wl_keyboard*, uint /*serial*/,
              uint time, uint key, uint state)
{
    try {
        auto input = cast(InputLayer)data;
        
        if (input !is null){

            auto mapper = Seat.get.m_mapper;
            itimerspec spec;

            if (state == WL_KEYBOARD_KEY_STATE_PRESSED) {

                auto seat = Seat.get();

                if (mapper.mayRepeats(key)){
                    spec.it_value.tv_sec = seat.delay_sec;
                    spec.it_value.tv_nsec = seat.delay_nsec;

                    spec.it_interval.tv_sec = seat.rate_sec;
                    spec.it_interval.tv_nsec = seat.rate_nsec;
                }

                if (mapper.keySymbol(key))
                    input.key(mapper);
            }

            Display.instance.kb_repeat.set_time(spec, input);
        }
    }
    catch(Exception e)
        Logger.error("Callback keyboerd key failed: %s", e.msg);
}

void cb_kbmodifiers(void*, wl_keyboard*, uint /*serial*/,
                        uint mods_depressed, //which key
                        uint mods_latched,
                        uint mods_locked,
                        uint group)
{
    try{
        Seat.get.m_mapper.updateMask(mods_depressed, mods_latched, mods_locked, group);
    }
    catch(Exception e)
        Logger.error("Callback keyboerd modifiers failed: %s", e.msg);
}

void cb_kbrepeat_info(void*, wl_keyboard*,
                          int rate, int delay)
{
    auto seat = Seat.get;

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
        seat.delay_nsec = (delay % 1_000) * 1_000_000;
    }

    if (rate > 1){
        seat.rate_nsec = 1_000_000_000 / rate;
        seat.rate_sec = 0;
    }
    else{
        seat.rate_nsec = 0;
        seat.rate_sec = 1;
    }

    debug Logger.info("repeat_info delay %i ms, rate %i per second", delay, rate);
}

// pointer_listener ////////////////////////////////////////////////////////////////////

void cb_pointer_enter(void*, wl_pointer *pointer,
                uint serial, wl_surface *surface,
                wl_fixed_t sx, wl_fixed_t sy)
{
    // Happens in the case we just destroyed the surface.
    if (surface is null) return;

    try{
        auto input = cast(InputLayer) wl_surface_get_user_data(surface);

        if (input !is null){
            wl_pointer_set_user_data(pointer, cast(void*)input);
            input.point(PointerState.enter, Pointer(sx, sy));
        }
    }
    catch(Exception e)
        Logger.error("Callback pointer enter failed: %s", e.msg);
}

void cb_pointer_leave(void *data, wl_pointer *pointer,
                uint serial, wl_surface*)
{
    try{
        auto input = cast(InputLayer)data;
        if (input !is null) {

            input.point(PointerState.leave, Pointer());
            wl_pointer_set_user_data(pointer, null);
        }
    }
    catch(Exception e)
        Logger.error("Callback pointer leave failed: %s", e.msg);
}

void cb_pointer_motion (void *data, wl_pointer*,
                uint time, wl_fixed_t sx, wl_fixed_t sy)
{
    try{
        auto input = cast(InputLayer)data;
        if (input !is null)
            input.point_motion(time, Pointer(sx, sy));
    }
    catch(Exception e)
        Logger.error("Callback pointer motion failed: %s", e.msg);
}

void cb_pointer_button(void *data, wl_pointer*,
            uint serial, uint time, uint button,
            uint state)
{
    try{
        auto input = cast(InputLayer)data;
        if (input !is null){

            import core.sys.posix.time : posix_time = timespec;
            /* count click */
            posix_time now;
            clock_gettime(CLOCK_MONOTONIC, &now);
            auto seat = Seat.get;

            if (state == WL_POINTER_BUTTON_STATE_PRESSED){

                if (seat.m_last_released_button == button &&
                    now.tv_sec == seat.m_stamp &&
                    time - seat.m_last_time <= 300)
                    seat.m_count_click += 1;
                else
                    seat.m_count_click = 1;

                auto key = seat.m_mapper.modifiers(ModSet.effective);

                input.click(cast(PointerButton)button, true,
                                            seat.m_count_click,
                                            key);
            }
            else {
                seat.m_last_released_button = button;
                seat.m_last_time = time;
                seat.m_stamp = now.tv_sec;
                input.click(cast(PointerButton)button, false, 0, 0);
            }
        }
    }
    catch(Exception e)
        Logger.error("Callback pointer button failed: %s", e.msg);
}

void cb_pointer_axis(void* data, wl_pointer*,
               uint time, uint axis, wl_fixed_t value)
{
    try{
        auto input = cast(InputLayer)data;
        if (input !is null){
    
            input.scroll(time, axis, wl_fixed_to_double(value));
        }
    }
    catch(Exception e)
        Logger.error("Callback pointer axis failed: %s", e.msg);
}

void cb_pointer_frame(void* data, wl_pointer* pointer)
{
    // Конец группы событий. Применяйте изменения здесь для плавности.
}

void cb_axis_source(void* data, wl_pointer* pointer, uint source) {}
void cb_axis_stop(void* data, wl_pointer* pointer, uint time, uint axis) {}
void cb_axis_discrete(void* data, wl_pointer* pointer, uint axis, int discrete) {}
void cb_axis_value120(void *data,
                      wl_pointer *wl_pointer,
                    uint axis,
                    int value120){}
void cb_axis_relative_direction(void *data,
                    wl_pointer *wl_pointer,
                    uint32_t axis,
                    uint32_t direction){}
}
