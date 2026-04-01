module wayland.internal.keymapper;

import xkbmapper;
import core.sys.posix.sys.mman;
import std.exception : enforce;
import std.format : format;
import core.stdc.errno : errno;
import core.stdc.string : strerror;
import std.conv : to;

import wayland.logger;

enum ModSet {locked, effective, consumed}

interface KeyMapper
{
    uint modifiers(ModSet group) const;
    string utf8() const;
    uint symbol() const;

    bool mayRepeats(uint key);
    bool keySymbol(uint key);
    void updateMask(uint mods_depressed, //which key
                    uint mods_latched,
                    uint mods_locked,
                    uint group);
}

final class XkbMapper: KeyMapper
{
    override uint modifiers(ModSet group) const
    {
        switch (group) {
        case ModSet.effective:
            return xkb_state_serialize_mods(
                cast(xkb_state*)kstate, XKB_STATE_MODS_EFFECTIVE);
        case ModSet.consumed:
            return xkb_state_key_get_consumed_mods2(
                cast(xkb_state*)kstate, keycode, XKB_CONSUMED_MODE_XKB);
        case ModSet.locked:
            return xkb_state_serialize_mods(
                cast(xkb_state*)kstate, XKB_STATE_MODS_LOCKED);
        default:
            break;
        }

        return 0;
    }

    string utf8() const
    {
        if (xkb_state_key_get_utf8(cast(xkb_state*)kstate, keycode, 
                                   cast(char*)utf8buf.ptr, utf8buf.length) > 0)

            return utf8buf;
        
        return "";
    }

    uint symbol() const
    {
        return keysymbol;
    }

    override bool mayRepeats(uint key)
    {
        return xkb_keymap_key_repeats(keymap, key + 8) != 0;
    }

    override bool keySymbol(uint key)
    {
        auto raw_key = key + 8;
        auto sym = xkb_state_key_get_one_sym(kstate, raw_key);

        if ((sym >= XKB_KEY_Shift_L && sym <= XKB_KEY_Hyper_R) ||
            (sym >= XKB_KEY_ISO_Lock && sym <= XKB_KEY_ISO_Last_Group_Lock) ||
            sym == XKB_KEY_Mode_switch ||
            sym == XKB_KEY_Num_Lock)
            return false;

        keycode = raw_key;
        keysymbol = sym;
        return true;
    }

    override void updateMask(uint mods_depressed, //which key
                    uint mods_latched, uint mods_locked, uint group)
    {
        xkb_state_update_mask(kstate,
                            mods_depressed, mods_latched, mods_locked,
                            0, 0, group);
    }

package(wayland):

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
        enforce(keymap, "failed xkb keymap");

        kstate = xkb_state_new(keymap);
        enforce(kstate, "failed xkb keymap");
        
        scope(failure) unref();
    }

    ~this(){
        Logger.error("KEYMAP_FORMAT %p", this); 
        unref();
    }

    void unref() nothrow
    {
        try{
            if (kstate) xkb_state_unref(kstate);
            if (keymap) xkb_keymap_unref(keymap);
            if (kcontext) xkb_context_unref(kcontext);
        }
        catch(Exception e)
            Logger.error("fatal error on unref XkbMapper %s", e.msg);
    }

private:
    xkb_context* kcontext;
    xkb_keymap*  keymap;
    xkb_state*   kstate;
    uint keycode;
    uint keysymbol;
    char[16] utf8buf;
}