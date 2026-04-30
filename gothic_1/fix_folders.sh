#!/bin/sh

echo "Starting targeted folder merge..."

# 1. Safely merge the root folders first
if [ -d "_Work" ]; then
    echo "Merging root _Work into _work..."
    cp -a _Work/. _work/ 2>/dev/null
    rm -rf _Work
fi

if [ -d "DATA" ]; then
    echo "Merging root DATA into Data..."
    cp -a DATA/. Data/ 2>/dev/null
    rm -rf DATA
fi

# 2. Recursively lowercase and merge ONLY inside the _work directory
if [ -d "_work" ]; then
    echo "Lowercasing and merging contents of _work..."
    find _work -depth | while read -r item; do
        
        # Skip the _work root directory itself
        if [ "$item" = "_work" ]; then
            continue
        fi

        dir=$(dirname "$item")
        base=$(basename "$item")
        
        lower_base=$(echo "$base" | tr '[:upper:]' '[:lower:]')
        lower_item="$dir/$lower_base"

        if [ "$base" != "$lower_base" ]; then
            if [ -e "$lower_item" ]; then
                if [ -d "$item" ] && [ -d "$lower_item" ]; then
                    cp -a "$item"/. "$lower_item"/
                    rm -rf "$item"
                else
                    mv -f "$item" "$lower_item"
                fi
            else
                mv "$item" "$lower_item"
            fi
        fi
    done
fi

# 3. Restore the specific uppercase "Data" folder inside _work for hardcoded paths
if [ -d "_work/data" ]; then 
    mv _work/data _work/Data
    echo "Restored _work/Data capitalization."
fi

# 4. Wipe old cache files just to be safe
rm -f vdfs.dmp VDFS.DMP System/vdfs.dmp System/VDFS.DMP
echo "Cleared VDFS cache."

echo "Targeted fix complete!"