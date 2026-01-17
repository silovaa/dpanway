module wayland;

public import wayland.display;
public import wayland.sensitive_layer;
public import wayland.logger;

//wayland protocols
public import wayland.seat;
public import wayland.xdg_shell;

version(WaylandEGL):
public import wayland.egl_window;


template WithProtocols(Base, Protocols...) {

    // 1. Фильтруем: оставляем только декораторы, у которых есть iface
    alias DecoratorsWithIface = staticFilter!(hasIface, Decorators);
    
    // 2. Преобразуем: каждый декоратор -> его интерфейс
    alias AllInterfaces = staticMap!(getIface, DecoratorsWithIface);
    
    // Класс ТОЛЬКО для сборки
    abstract class ProtocolsBase : Base, AllInterfaces {
        // Вставляем тела всех декораторов
        mixin(combineBodies!Protocols);
         
        // Базовый конструктор
        this() {
            _state = State();
        }
    }
    
    alias WithProtocols = ProtocolsBase;
}

private:

// Шаблон для проверки: имеет ли декоратор интерфейс?
template hasIface(alias D) {
    // Проверяем, можно ли получить D.iface без ошибки компиляции
    enum hasIface = __traits(compiles, { 
        alias iface = D.iface; 
    });
}

// Шаблон для получения интерфейса декоратора
template getIface(alias D) {
    static if (hasIface!D) {
        // Если есть iface - возвращаем его
        alias getIface = D.iface;
    }
}

// Шаблон для фильтрации: оставляем только декораторы с интерфейсами
template staticFilter(alias Pred, T...) {
    static if (T.length == 0) {
        // Конец списка
        alias staticFilter = AliasSeq!();
    } else static if (Pred!(T[0])) {
        // Элемент проходит условие - включаем его
        alias staticFilter = AliasSeq!(T[0], staticFilter!(Pred, T[1..$]));
    } else {
        // Элемент не проходит - пропускаем
        alias staticFilter = staticFilter!(Pred, T[1..$]);
    }
}

// Шаблон для преобразования: декоратор -> его интерфейс
template staticMap(alias F, T...) {
    static if (T.length == 0) {
        alias staticMap = AliasSeq!();
    } else {
        alias staticMap = AliasSeq!(F!(T[0]), staticMap!(F, T[1..$]));
    }
}

// Шаблон для объединения всех тел декораторов в одну строку
template combineBodies(Decorators...) {
    string combineBodies() {
        string code;
        
        // Проходим по всем декораторам и добавляем их body
        static foreach (D; Decorators) {
            code ~= D.body ~ "\n";
        }
        
        return code;
    }
}