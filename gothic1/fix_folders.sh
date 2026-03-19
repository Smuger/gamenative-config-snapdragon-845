#!/bin/bash

echo "Starting dynamic lowercase and merge process..."

# We use -depth to process files bottom-up. 
# This ensures we don't rename a parent folder while the script 
# is still trying to process the files inside it.
find . -depth | while read -r item; do
    
    # Skip the root directory itself
    if [ "$item" = "." ]; then
        continue
    fi

    dir=$(dirname "$item")
    base=$(basename "$item")
    
    # Convert only the current file/folder name to lowercase
    lower_base=$(echo "$base" | tr '[:upper:]' '[:lower:]')
    lower_item="$dir/$lower_base"

    # Only act if the name actually contains uppercase letters
    if [ "$base" != "$lower_base" ]; then
        
        # If the lowercase version already exists (the collision)
        if [ -e "$lower_item" ]; then
            if [ -d "$item" ] && [ -d "$lower_item" ]; then
                # Both are directories: merge them cleanly, then delete the old one
                cp -a "$item"/. "$lower_item"/
                rm -rf "$item"
            else
                # It's a file: move and overwrite
                mv -f "$item" "$lower_item"
            fi
        else
            # No collision: just safely rename it to lowercase
            mv "$item" "$lower_item"
        fi
    fi
done

echo "Process complete. Everything is lowercased and merged!"