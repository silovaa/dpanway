module wayland.surface;

import wayland.display;
import wayland.internal.core;
import wayland.logger;

struct ScaleFactor
{
private:
    alias ScaleManager = GlobalProxy!(wp_fractional_scale_manager_v1,
                                    wp_fractional_scale_manager_v1_interface,
                                    WP_FRACTIONAL_SCALE_MANAGER_V1_DESTROY);
    
    wp_fractional_scale_v1* m_fscale;

    mixin GlobalFactory!ScaleManager;

    void delegate(float /*factor*/) cbScaleChanged;

public:
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
        if (globalValid()) 
        {
            m_fscale = wp_fractional_scale_manager_v1_get_fractional_scale(
                m_global.c_ptr, 
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
}

private:

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

