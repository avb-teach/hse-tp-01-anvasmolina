#!/bin/bash

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    echo "Python3 is required but not installed"
    exit 1
fi

# Check minimum required arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 input_dir output_dir [--max_depth N]"
    exit 1
fi

INPUT_DIR="$1"
OUTPUT_DIR="$2"
MAX_DEPTH=-1

# Parse --max_depth parameter
if [ "$3" = "--max_depth" ] && [ -n "$4" ]; then
    if [[ "$4" =~ ^[0-9]+$ ]]; then
        MAX_DEPTH="$4"
    else
        echo "Error: --max_depth requires a positive integer"
        exit 1
    fi
fi

# Check if input directory exists
if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: Input directory does not exist"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Normalize paths
INPUT_DIR=$(realpath "$INPUT_DIR")
OUTPUT_DIR=$(realpath "$OUTPUT_DIR")

# Check if output is inside input directory
if [[ "$OUTPUT_DIR" == "$INPUT_DIR"* ]]; then
    echo "Error: Output directory cannot be inside input directory"
    exit 1
fi

# Python script to handle file collection
PYTHON_SCRIPT=$(cat << 'EOF'
import os
import shutil
import sys
from collections import defaultdict

def collect_files(input_dir, output_dir, max_depth):
    file_counts = defaultdict(int)
    input_dir = os.path.abspath(input_dir)
    
    for root, dirs, files in os.walk(input_dir):
        # Calculate current depth relative to input_dir
        rel_path = os.path.relpath(root, input_dir)
        if rel_path == '.':
            current_depth = 0
        else:
            current_depth = len(rel_path.split(os.sep))
        
        # Skip if depth exceeds max_depth
        if max_depth >= 0 and current_depth > max_depth:
            continue
            
        for file in files:
            src_path = os.path.join(root, file)
            base, ext = os.path.splitext(file)
            file_counts[file] += 1
            
            if file_counts[file] > 1:
                new_file = f"{base}{file_counts[file]}{ext}"
            else:
                new_file = file
                
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

# Execute Python script
echo "$PYTHON_SCRIPT" | python3 - "$INPUT_DIR" "$OUTPUT_DIR" "$MAX_DEPTH"

exit $?