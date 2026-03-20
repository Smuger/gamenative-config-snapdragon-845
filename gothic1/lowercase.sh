#!/bin/sh

find . -depth -name '*[A-Z]*' | while IFS= read -r f; do
    dir=$(dirname "$f")
    base=$(basename "$f")
    lower=$(echo "$base" | tr '[:upper:]' '[:lower:]')
    mv -n "$f" "$dir/$lower"
done