#!/bin/bash

if test "$#" -ne 2; then
    printf "\nОшибка: неправильное количество аргументов.\nПравильно вызывать так:\n\t%s <входная_директория> <выходная_директория>\n\n" "$0"
    exit 1
fi

input_dir="$1"
output_dir="$2"

copying() {
  local source_file="$1"
  local dest_file="$output_dir/$(basename "$source_file")"
  local cnt=1

  while [ -e "$dest_file" ]; do
      dest_file="$output_dir/$(basename "$source_file" | cut -d '.' -f 1)_${cnt}.${source_file##*.}"
      cnt=$((cnt + 1))
  done
  cp "$source_file" "$dest_file"
}

for file in $(find "$input_dir" -type f); do
  copying "$file"
done

printf "Файлы успешно скопированы из '%s' в '%s'.\n" "$input_dir" "$output_dir"
exit 0








