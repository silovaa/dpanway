module wayland;

public import wayland.display;
public import wayland.sensitive_layer;
public import wayland.logger;

//wayland protocols
public import wayland.seat;
public import wayland.xdg_shell;
public import wayland.surface;

version(WaylandEGL):
public import wayland.egl_window;

import std.meta : AliasSeq;
import wayland_import;


template WithProtocols(Base, Protocols...) {

    // 1. Фильтруем: оставляем только декораторы, у которых есть iface
    alias AllInterfaces = staticFilter!(isInterface, Protocols);

    // Класс ТОЛЬКО для сборки
    abstract class ProtocolsBase: Base, AllInterfaces {

        private wl_proxy* [Protocols.length] proxy;
         
        this()
        {
            static foreach (i, P; Protocols) {
                static if (__traits(hasMember, P, "initialize")) {
                    proxy[i] = P.initialize(this); 
                }
            }
        }
import std.stdio;
        override void dispose() 
        {
            static foreach (i, P; Protocols) {
                static if (__traits(hasMember, P, "dispose")) {
                    if (proxy[i]) P.dispose(proxy[i]); 
                }
                writeln("Destroy ", P.stringof);
            }

            super.dispose();
        }
    }
    
    alias WithProtocols = ProtocolsBase;
}

private:

// Предикат для фильтрации
template isInterface(T) {
    enum isInterface = is(T == interface);
}

template staticFilter(alias Pred, T...) {
    static if (T.length == 0) {
        alias staticFilter = AliasSeq!();
    } else {
        // Важно: передаем T[0] в предикат
        static if (Pred!(T[0])) {
            alias staticFilter = AliasSeq!(T[0], staticFilter!(Pred, T[1..$]));
        } else {
            alias staticFilter = staticFilter!(Pred, T[1..$]);
        }
    }
}

