#!/bin/bash

copying() {
  if test "$#" -ne 2; then
    printf "\nОшибка: неправильное количество аргументов.\nПравильно вызывать так:\n\t%s <входная_директория> <выходная_директория>\n\n" "$0"
    exit 1
  fi

  input_dir="$1"
  output_dir="$2"

  for file in $(find "$input_dir" -type f); do
    local source_file="$file"
    local dest_file=$(create_name "$source_file")
    cp "$source_file" "$dest_file"
  done

  printf "Файлы скопированы из '%s' в '%s'.\n" "$input_dir" "$output_dir"
}

create_name() {
  local source_file="$1"
  local dest_file="$output_dir/$(basename "$source_file")"

  local name="${source_file##*/}"
  local base="${name%.*}" 
  local extension="${name##*.}" 

  local cnt=1
  
  while [ -e "$dest_file" ]; do
      dest_file="$output_dir/${base}_${cnt}.${extension}"
      let cnt=cnt+1
  done

  echo "$dest_file"
}

copying "$@"
exit 0









