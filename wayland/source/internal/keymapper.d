module wayland.internal.keymapper;

package(wayland):

enum ModSet {locked, effective, consumed}

interface KeyMapper
{
    uint modifiers(ModSet group) const nothrow;
    bool mayRepeats(uint key) const nothrow;
    bool keySymbol(uint key, out uint symbol) nothrow;
    void updateMask(uint mods_depressed, //which key
                    uint mods_latched,
                    uint mods_locked,
                    uint group) nothrow;
    int utf8(char[] buf) const;
}

import core.sys.posix.sys.mman;
import std.exception : enforce;
import std.format : format;
import core.stdc.errno : errno;
import core.stdc.string : strerror;
import std.conv : to;

final class XkbMapper: KeyMapper
{
    this(int fd, uint size)
    {
        kcontext = enforce(xkb_context_new(XKB_CONTEXT_NO_FLAGS),
                        "xkb context failed");

        void* addr = mmap(NULL, size, PROT_READ, MAP_PRIVATE, fd, 0);
        enforce(addr != MAP_FAILED, 
                format("XKBKeyboard mmap failed: %s (errno: %d)", 
                        strerror(errno).to!string, errno));
        scope(exit) munmap(addr, size);

        keymap = xkb_keymap_new_from_string(kcontext, cast(char*)addr,  
                                            XKB_KEYMAP_FORMAT_TEXT_V1,
                                            XKB_KEYMAP_COMPILE_NO_FLAGS);
        enforce(keymap !is null, "failed xkb keymap");

        kstate = xkb_state_new(keymap);
        enforce(kstate !is null, "failed xkb keymap");
        
        scope(failure) unref();
    }

    ~this(){ unref();}

    void unref() nothrow
    {
        if (kstate) xkb_state_unref(kstate);
        if (keymap) xkb_keymap_unref(keymap);
        if (kcontext) xkb_context_unref(kcontext);
    }

    override uint modifiers(ModSet group) const nothrow
    {
        switch (group) {
        case ModSet.effective:
            return xkb_state_serialize_mods(
                mapper.kstate, XKB_STATE_MODS_EFFECTIVE);
        case ModSet.consumed:
            return xkb_state_key_get_consumed_mods2(
                mapper.kstate,  mapper.keycode, XKB_CONSUMED_MODE_XKB);
        case ModSet.locked:
            return xkb_state_serialize_mods(
                mapper.kstate, XKB_STATE_MODS_LOCKED);
        default:
            break;
        }

        return 0;
    }

    override bool mayRepeats(uint key) const nothrow
    {
        return xkb_keymap_key_repeats(keymap, key + 8) != 0;
    }

    override bool keySymbol(uint key, out uint symbol) nothrow
    {
        auto raw_key = key + 8;
        auto sym = xkb_state_key_get_one_sym(kstate, raw_key);

        if ((sym >= XKB_KEY_Shift_L && sym <= XKB_KEY_Hyper_R) ||
            (sym >= XKB_KEY_ISO_Lock && sym <= XKB_KEY_ISO_Last_Group_Lock) ||
            sym == XKB_KEY_Mode_switch ||
            sym == XKB_KEY_Num_Lock)
            return false;

        keycode = raw_key;
        symbol = sym;
        return true;
    }

    override void updateMask(uint mods_depressed, //which key
                    uint mods_latched, uint mods_locked, uint group) nothrow
    {
        xkb_state_update_mask(kstate,
                            mods_depressed, mods_latched, mods_locked,
                            0, 0, group);
            
    }

    int utf8(char[] buf) const
    {
        return xkb_state_key_get_utf8(kstate, keycode, buf.ptr, buf.length);
    }

private:
    xkb_context* kcontext;
    xkb_keymap* keymap;
    xkb_state* kstate;
    uint keycode;
}

private extern(C){

    struct xkb_context;
    struct xkb_keymap;
    struct xkb_state;

    void xkb_state_update_mask();
    int  xkb_state_key_get_one_sym();
    uint xkb_keymap_key_repeats();
    uint xkb_state_serialize_mods();
    uint xkb_state_key_get_consumed_mods2();

    void xkb_state_unref();
    void xkb_keymap_unref();
    void xkb_context_unref();

    xkb_state* xkb_state_new();
    xkb_keymap* xkb_keymap_new_from_string();
    xkb_context* xkb_context_new();
}