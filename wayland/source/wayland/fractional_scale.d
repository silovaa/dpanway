module wayland.fractional_scale;

import wayland.display: Surface;
import wayland.internal.core;
import wayland.logger;

struct ScaleFactor
{
    template Iface(alias ctx) 
    {
        @property void onScaleChanged(void delegate(float /*factor*/) cb)
        {
            ctx.cbScaleChanged = cb;
        }
    }

package(wayland):
    void setup(Surface surface) 
    {
        if (scale_mgr.isValid()) 
        {
            m_fscale = wp_fractional_scale_manager_v1_get_fractional_scale(
                scale_mgr.c_ptr, 
                surface.c_ptr
            );

            if (m_fscale) 
                wp_fractional_scale_v1_add_listener(
                    m_fscale, 
                    &scale_lsr, 
                    cast(void*)&this
                ); 
        }
    }

    void dispose()
    {
        if (m_fscale) {
            wp_fractional_scale_v1_destroy(m_fscale);
            m_fscale = null;
        }
    }

private:
    wp_fractional_scale_v1* m_fscale;
    void delegate(float) cbScaleChanged;
}

private:

alias ScaleManager = GlobalProxy!(wp_fractional_scale_manager_v1,
                                    wp_fractional_scale_manager_v1_interface,
                                    WP_FRACTIONAL_SCALE_MANAGER_V1_DESTROY);
ScaleManager scale_mgr;

static this()
{
    scale_mgr = new ScaleManager;
}

__gshared wp_fractional_scale_v1_listener scale_lsr =
{
    preferred_scale: &cb_preferred_scale
};

extern(C) nothrow {
    void cb_preferred_scale(void* data, wp_fractional_scale_v1 *, 
                            uint scale)
    {
        auto sf = cast(ScaleFactor*)data;
        float val = scale / 120.0f;
        
        try{
            if (sf.cbScaleChanged)
                sf.cbScaleChanged(val);
        }
        catch(Exception e)
            Logger.error("Callback ScaleManager preferred_scale failed: %s", e.msg);
    }
}

