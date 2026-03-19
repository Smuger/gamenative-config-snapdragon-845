#!/bin/sh

echo "Starting dynamic lowercase and merge process..."

# Part 1: Merge and Lowercase Everything
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

echo "Base merge complete! Applying Gothic VDFS engine fixes..."

# Part 2: Force critical engine folders to the correct Title Case
if [ -d "data" ]; then 
    mv data Data
    echo "Fixed root Data folder."
fi

if [ -d "_work/data" ]; then 
    mv _work/data _work/Data
    echo "Fixed _work/Data folder."
fi

if [ -d "system" ]; then
    mv system System
    echo "Fixed System folder."
fi

# Fix the ini file if it exists so the engine can read it
if [ -f "System/gothic.ini" ]; then 
    mv System/gothic.ini System/Gothic.ini
fi

# Part 3: Wipe out old desynced cache files (covering all possible casings)
rm -f vdfs.dmp VDFS.DMP System/vdfs.dmp System/VDFS.DMP system/vdfs.dmp system/VDFS.DMP
echo "Cleared old VDFS cache."

# Part 4: Generate the correct, factory-standard VDFS.CFG file
echo "[VDFS]" > VDFS.CFG
echo "*.vdf" >> VDFS.CFG
echo "*.mod" >> VDFS.CFG
echo "[END]" >> VDFS.CFG
echo "Generated correct VDFS.CFG."

echo "All fixes applied! You are ready to launch GothicMod.exe."