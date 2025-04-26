#!/bin/bash

# Проверка наличия Python 3
if ! command -v python3 &> /dev/null; then
    echo "Python3 is required but not installed"
    exit 1
fi

# Проверка минимального количества аргументов
if [ $# -lt 2 ]; then
    echo "Usage: $0 input_dir output_dir [--max_depth N]"
    exit 1
fi

INPUT_DIR="$1"
OUTPUT_DIR="$2"
MAX_DEPTH=-1

# Парсинг параметра --max_depth
if [ "$3" = "--max_depth" ] && [ -n "$4" ]; then
    if [[ "$4" =~ ^[0-9]+$ ]]; then
        MAX_DEPTH="$4"
    else
        echo "Error: --max_depth requires a positive integer"
        exit 1
    fi
fi

# Проверка существования входной директории
if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: Input directory does not exist"
    exit 1
fi

# Создание выходной директории, если её нет
mkdir -p "$OUTPUT_DIR"

# Нормализация путей
INPUT_DIR=$(realpath "$INPUT_DIR")
OUTPUT_DIR=$(realpath "$OUTPUT_DIR")

# Проверка, что выходная директория не находится внутри входной
if [[ "$OUTPUT_DIR" == "$INPUT_DIR"* ]]; then
    echo "Error: Output directory cannot be inside input directory"
    exit 1
fi

# Python скрипт для обработки файлов
PYTHON_SCRIPT=$(cat << 'EOF'
import os
import shutil
import sys
from collections import defaultdict

def collect_files(input_dir, output_dir, max_depth):
    file_counts = defaultdict(int)
    input_dir = os.path.abspath(input_dir)
    
    for root, dirs, files in os.walk(input_dir):
        # Вычисляем текущую глубину
        rel_path = os.path.relpath(root, input_dir)
        current_depth = 0 if rel_path == '.' else len(rel_path.split(os.sep))
        
        # Пропускаем, если превышена максимальная глубина
        if max_depth >= 0 and current_depth > max_depth:
            continue
            
        # Обрабатываем файлы в отсортированном порядке
        for file in sorted(files):
            src_path = os.path.join(root, file)
            base, ext = os.path.splitext(file)
            
            # Генерируем новое имя файла с учетом дубликатов
            file_counts[file] += 1
            count = file_counts[file]
            new_file = f"{base}{count}{ext}" if count > 1 else file
            
            dst_path = os.path.join(output_dir, new_file)
            
            try:
                shutil.copy2(src_path, dst_path)
            except Exception as e:
                print(f"Error copying {src_path}: {e}", file=sys.stderr)

if __name__ == "__main__":
    if len(sys.argv) < 4:
        sys.exit(1)
    collect_files(sys.argv[1], sys.argv[2], int(sys.argv[3]))
EOF
)

# Выполнение Python скрипта
echo "$PYTHON_SCRIPT" | python3 - "$INPUT_DIR" "$OUTPUT_DIR" "$MAX_DEPTH"

exit $?