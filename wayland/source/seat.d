module wayland.seat;

import wayland.internal.core;
import wayland.display;
import wayland.logger;
import wayland.internal.keymapper;

import wayland.surface;
import wayland.sensitive_layer;

final class Seat: GlobalProxy!(Seat, wl_seat, wl_seat_interface, WL_SEAT_RELEASE)
{
package(wayland):
    mixin RegistryProtocols!Seat;

protected:
    override void bind(wl_registry* reg, uint name_id, uint vers) 
    {
        super.bind(reg, name_id, vers); 

        if (wl_seat_add_listener(c_ptr(), &seat_listener, cast(void*)this) < 0)
            Logger.error("failed to add seat listener");
    }

    override void dispose() 
    {
        m_keyboard = Keyboard();
        m_pointer  = null;
        super.dispose();
    }

    Keyboard m_keyboard;
    Surface m_current_surf;
    
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

private:

__gshared wl_seat_listener seat_listener = {
    capabilities: &cb_capabilities,
    name:         &cb_name
};

__gshared wl_keyboard_listener keyboard_listener = {
    keymap: &cb_kbkeymap,
    enter : &cb_kbenter,
    leave : &cb_kbleave,
    key   : &cb_kbkey,
    modifiers  : &cb_kbmodifiers,
    repeat_info: &cb_kbrepeat_info
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

// wl_pointer* wl_seat_get_pointer(wl_seat*) @nogc;
// int wl_pointer_add_listener(wl_pointer*, wl_pointer_listener*, void*) @nogc;
// wl_keyboard* wl_seat_get_keyboard(wl_seat*) @nogc;
// int wl_keyboard_add_listener(wl_keyboard*, wl_keyboard_listener*, void*) @nogc;

void cb_capabilities(void* data, wl_seat* wlseat, uint flags)
{
    auto seat = cast(Seat) data;

//To do проверить добавление второй мыши и клавиатуры
    //try{
        if ((flags & WL_SEAT_CAPABILITY_POINTER) != 0) {
            auto pointer = cast(wl_pointer*)wl_proxy_marshal_flags(wlseat, WL_SEAT_GET_POINTER, 
                            &wl_pointer_interface, wl_proxy_get_version(cast(wl_proxy*) wl_seat), 0, NULL);
            seat.m_pointer = pointer;
            if (wl_pointer_add_listener(pointer, &pointer_listener, data) wl_proxy_add_listener(cast(wl_proxy*) wl_pointer,
				     (void (**)(void)) &pointer_listener, data);< 0)
                Logger.error("failed to add pointer listener");
        }
        else {
            //seat.m_hovered_surf = null;
            seat.m_pointer = null;
        }

        if ((flags &  WL_SEAT_CAPABILITY_KEYBOARD) != 0){
            wl_keyboard* kb = wl_seat_get_keyboard(wlseat);
            if (wl_keyboard_add_listener(kb, &keyboard_listener, data) < 0)
                Logger.error("failed to add keyboard listener");
        }
        else {
            //seat.m_focused_surf = null;
            seat.m_keyboard.reset();
        }
    //}
    //catch(Exception e)
    //    Logger.error("Callback seat capabilities failed: %s", e.msg);
}

void cb_name(void*, wl_seat*, const(char)* name)
{
    Logger.info("Seat connected, name: %s", name);
} 

// keyboard_listener ///////////////////////////////////////////////////////////////////

void cb_kbkeymap (void *data, wl_keyboard* wlkb,
                uint kbformat, int fd, uint size)
{
    auto seat = cast(Seat) data;

    if (kbformat == WL_KEYBOARD_KEYMAP_FORMAT_XKB_V1){

        try {
            seat.m_keyboard = Keyboard(wlkb, new XkbMapper(fd, size));
        }
        catch(Exception e){
            Logger.error("KEYMAP_FORMAT failed: %s", e.msg);
        }
    }
    else
        //To Do WL_KEYBOARD_KEYMAP_FORMAT_NO_KEYMAP
        Logger.error("KEYMAP_FORMAT not supported, format code: %d",kbformat);

    close(fd);
}

void cb_kbenter(void *data, wl_keyboard*, uint serial,
            wl_surface *surface, wl_array *keys)
{            
    try{
        auto seat = cast(Seat)data;
        auto surf = cast(Surface)
            wl_surface_get_user_data(surface);

        if(seat.m_current_surf != surf && surf){
            seat.m_keyboard.m_focused_surf = surf.inputHandler;

            if (seat.m_keyboard.m_focused_surf is null) {

                Logger.error("SensetiveLayer not set");
                seat.m_current_surf = null;
                return;
            }

            seat.m_current_surf = surf;
        }

        seat.m_keyboard.emit_focus(true);
    }
    catch(Exception e)
        Logger.error("Callback keyboerd enter failed: %s", e.msg);
}

void cb_kbleave(void *data, wl_keyboard *wl_kd, uint, wl_surface*)
{
    auto seat = cast(Seat)data;

    try{
        if (seat.m_current_surf !is null){

            seat.m_keyboard.emit_focus(false);
            seat.m_current_surf = null;

            itimerspec timer;
            Display.instance.kb_repeat.set_time(timer);
        }
    }
    catch(Exception e)
        Logger.error("Callback keyboerd leave failed: %s", e.msg);
}

void cb_kbkey(void* data, wl_keyboard* wl_kd, uint /*serial*/,
              uint time, uint key, uint state)
{
    auto seat = cast(Seat)data;
    auto mapper = seat.m_keyboard.m_mapper;

    try {
        if (seat.m_current_surf !is null){

            itimerspec spec;

            if (state == WL_KEYBOARD_KEY_STATE_PRESSED) {

                if (mapper.mayRepeats(key)){
                    spec.it_value.tv_sec = seat.delay_sec;
                    spec.it_value.tv_nsec = seat.delay_nsec;

                    spec.it_interval.tv_sec = seat.rate_sec;
                    spec.it_interval.tv_nsec = seat.rate_nsec;
                }

                seat.m_keyboard.emit_key(key);
            }

            Display.instance.kb_repeat.set_time(spec);
        }
    }
    catch(Exception e)
        Logger.error("Callback keyboerd key failed: %s", e.msg);
}

void cb_kbmodifiers(void *data, wl_keyboard *, uint /*serial*/,
                        uint mods_depressed, //which key
                        uint mods_latched,
                        uint mods_locked,
                        uint group)
{
    auto mapper = (cast(Seat)data).m_keyboard.m_mapper;

    try{
        mapper.updateMask(mods_depressed, mods_latched, mods_locked, group);
    }
    catch(Exception e)
        Logger.error("Callback keyboerd modifiers failed: %s", e.msg);
}

void cb_kbrepeat_info(void *data, wl_keyboard *wl_kd,
                          int rate, int delay)
{
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

    Logger.info("repeat_info delay %i ms, rate %i per second", delay, rate);
}

// pointer_listener ////////////////////////////////////////////////////////////////////

void cb_pointer_enter(void *data, wl_pointer *pointer,
                uint serial, wl_surface *surface,
                wl_fixed_t sx, wl_fixed_t sy)
{
    // Happens in the case we just destroyed the surface.
    if (surface is null) return;

    try{
        auto seat = cast(Seat)data;
        auto surf = cast(Surface) wl_surface_get_user_data(surface);

        seat.m_hovered_surf = surf.inputHandler;

        if (seat.m_hovered_surf !is null)
            seat.m_hovered_surf.point(PointerState.enter, seat.m_pointer.set(sx, sy));
    }
    catch(Exception e)
        Logger.error("Callback pointer enter failed: %s", e.msg);
}

void cb_pointer_leave(void *data, wl_pointer *pointer,
                uint serial, wl_surface *surface)
{
    auto seat = cast(Seat)data;

    try{
        if (seat.m_hovered_surf) {

            seat.m_hovered_surf.point(PointerState.leave, seat.m_pointer);
            seat.m_hovered_surf = null;
        }
    }
    catch(Exception e)
        Logger.error("Callback pointer leave failed: %s", e.msg);
}

void cb_pointer_motion (void *data, wl_pointer *pointer,
                uint time, wl_fixed_t sx, wl_fixed_t sy)
{
    auto seat = cast(Seat)data;

    try{
        if (seat.m_hovered_surf)
            seat.m_hovered_surf.point_motion(time, seat.m_pointer.set(sx, sy));
    }
    catch(Exception e)
        Logger.error("Callback pointer motion failed: %s", e.msg);
}

void cb_pointer_button(void *data, wl_pointer *pointer,
            uint serial, uint time, uint button,
            uint state)
{
    auto seat = cast(Seat)data;

    if (seat.m_hovered_surf) {

        try{
            import core.sys.posix.time : posix_time = timespec;
            /* count click */
            posix_time now;
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
        catch(Exception e)
            Logger.error("Callback pointer button failed: %s", e.msg);
    }
}

void cb_pointer_axis(void *data, wl_pointer *pointer,
               uint time, uint axis, wl_fixed_t value)
{
    auto seat = cast(Seat)data;

    try{
        if (seat.m_hovered_surf)
            seat.m_hovered_surf.scroll(time, axis, wl_fixed_to_double(value));
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
