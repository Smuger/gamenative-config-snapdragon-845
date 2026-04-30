#!/bin/sh

LOGFILE="gothic_diag.txt"

echo "Gathering Gothic diagnostic data..."
echo "Generating log at $LOGFILE..."

echo "=== CURRENT DIRECTORY ===" > "$LOGFILE"
pwd >> "$LOGFILE"

echo "\n=== ROOT FOLDER CONTENTS ===" >> "$LOGFILE"
ls -la >> "$LOGFILE"

echo "\n=== DATA FOLDER CONTENTS (Checking VDF sizes) ===" >> "$LOGFILE"
# We check all variations just in case something renamed them
ls -la Data/ >> "$LOGFILE" 2>/dev/null
ls -la DATA/ >> "$LOGFILE" 2>/dev/null
ls -la data/ >> "$LOGFILE" 2>/dev/null

echo "\n=== VDFS.CFG CONTENTS (Raw) ===" >> "$LOGFILE"
cat VDFS.CFG >> "$LOGFILE" 2>/dev/null

echo "\n=== VDFS.CFG CONTENTS (Hex / Hidden Chars) ===" >> "$LOGFILE"
# This will expose \r (carriage returns) as \r or ^M so we can see the exact formatting
od -c VDFS.CFG >> "$LOGFILE" 2>/dev/null || cat -v VDFS.CFG >> "$LOGFILE" 2>/dev/null

echo "\n=== CHECKING VDFS CACHE FILES ===" >> "$LOGFILE"
find . -iname "vdfs.dmp" >> "$LOGFILE" 2>/dev/null

echo "\n=== CHECKING CORE _WORK DIRECTORIES ===" >> "$LOGFILE"
ls -ld _work/* >> "$LOGFILE" 2>/dev/null
ls -ld _work/Data/* >> "$LOGFILE" 2>/dev/null

echo "Diagnostics complete!"