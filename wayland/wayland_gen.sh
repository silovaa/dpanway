#!/bin/bash

# Настройки путей
OUT_DIR="c_generated"
PROTO_BASE="/usr/share/wayland-protocols"  # Основной системный путь
PROTO_DIR="xml_protocols"                  # Дополнительный путь проекта

# Список имен протоколов (только ИМЯ без расширения xml)
PROTOCOLS=(
    "xdg-shell"
    "fractional-scale-v1"
)

mkdir -p "$OUT_DIR"

IMPORT_FILE="$OUT_DIR/wayland_import.c"
echo '#include <wayland-client.h>' > "$IMPORT_FILE"

# Функция поиска файла
find_xml() {
    local name=$1
    find "$PROTO_BASE" "$PROTO_DIR" -name "${name}.xml" -print -quit 2>/dev/null
}

for proto in "${PROTOCOLS[@]}"; do
    xml_path=$(find_xml "$proto")
    if [ -z "$xml_path" ]; then
        echo "⚠️ Протокол '$proto' не найден"
        continue
    fi

    # Имя для D-модуля (без дефисов)
    safe_name=$(echo "$proto" | tr '-' '_')
    
    H_FILE="$OUT_DIR/${safe_name}.h"
    C_FILE="$OUT_DIR/${safe_name}.c"

    # Добавляем инклюд в общий файл в любом случае
    echo "#include \"${safe_name}.h\"" >> "$IMPORT_FILE"

    # ПРОВЕРКА: Если файлы .h и .c существуют И они новее чем XML-файл — пропускаем
    if [[ -f "$H_FILE" && -f "$C_FILE" && "$H_FILE" -nt "$xml_path" ]]; then
        echo "⏩ Пропуск: $safe_name (уже актуален)"
        continue
    fi

    echo "🔨 Генерация: $proto -> $safe_name"
    wayland-scanner client-header "$xml_path" "$H_FILE"
    wayland-scanner private-code "$xml_path" "$C_FILE"
done

echo "ok: $IMPORT_FILE"
