#!/bin/bash

# --- clean-it-up.sh ---
# Finds the 20 largest files and directories under the current directory (.)
# to help identify candidates for cleanup or backup. Uses macOS compatible commands.

# Number of items to display
TOP_N=20

# Function to convert bytes to human-readable format (KB, MB, GB)
# Uses awk for portability (macOS 'numfmt' might not be installed)
human_readable() {
    # This awk script now expects space-separated input: <size_bytes> <path>
    # It reconstructs the path if it contains spaces.
    awk -v top_n="$TOP_N" '
    BEGIN {
        hum[1024**3]="G"; hum[1024**2]="M"; hum[1024**1]="K"; hum[1]="B";
        OFS="\t"; # Set output field separator to tab for clean output
    }
    {
        size = $1; # Size is the first field

        # Reconstruct path starting from the second field
        path = $2;
        for (i=3; i<=NF; i++) {
            path = path " " $i
        }

        # --- Size formatting logic (unchanged) ---
        for (x=1024**3; x>=1; x/=1024) {
            if (size >= x) {
                printf "%.1f%s\t%s\n", size/x, hum[x], path;
                next; # Go to next line once printed
            }
        }
        # Handle sizes less than 1K explicitly if the loop didnt catch them
         if (size < 1024) {
             printf "%dB\t%s\n", size, path;
         }
    }
    ' | head -n "$TOP_N"
}

# --- Find Largest Files ---
echo "--- Top $TOP_N Largest Files ---"
# Use find -exec stat to get size in bytes (%z) and path (%N) for each file.
# The format '%z %N' outputs: <size_bytes> <filename>
# Use {} + for efficiency (runs stat on multiple files at once).
# Sort numerically (-n) in reverse order (-r) based on the first field (size).
# Pipe through the human_readable function.
find . -type f -exec stat -f '%z %N' {} + | sort -nr | human_readable

echo "" # Add a blank line for separation

# --- Find Largest Directories ---
# This part was working correctly and remains unchanged.
echo "--- Top $TOP_N Largest Directories ---"
du -k . | sort -nr | \
    awk 'BEGIN {OFS="\t"} {size_kb=$1; path=$2; for(i=3; i<=NF; i++) path=path" "$i; print size_kb * 1024, path}' | \
    human_readable

echo ""
echo "Note: Directory sizes include the total size of all files and subdirectories within them."
echo "The '.' entry represents the total size of the current directory."

exit 0
