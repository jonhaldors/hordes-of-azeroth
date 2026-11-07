#!/bin/bash
declare -A CHARS=(
    [Xenossy]="Warrior"
    [TestPal]="Paladin"
    [TestHun]="Hunter"
    [TestRog]="Rogue"
    [TestPri]="Priest"
    [TestSha]="Shaman"
    [TestMag]="Mage"
    [TestWar]="Warlock"
    [TestDru]="Druid"
)

RESULTS="C:/Users/hunau/.claude/jobs/c7a4dc53/tmp/class-results.txt"
> "$RESULTS"
LOG="C:/Users/hunau/Desktop/hoa-core/.claude/worktrees/runmaster-coop-fix/client/benilla-config/probe.log"

for char in Xenossy TestPal TestHun TestRog TestPri TestSha TestMag TestWar TestDru; do
    name=${CHARS[$char]}
    echo "Testing $name ($char)..." >&2
    
    powershell -NoProfile -File "C:\Users\hunau\Desktop\hoa-core\.claude\worktrees\runmaster-coop-fix\tools\e2e\class-test.ps1" \
        -Char "$char" -ClassName "$name" -Duration 70 2>/dev/null >/dev/null

    echo "=== $name ===" >> "$RESULTS"
    sed 's/\x1b\[[0-9;]*m//g' "$LOG" | grep -E "probe-log: (CLASS|EVENTS|ERRORS|LUA-ERROR|WEAPONS)|God mode on" | \
        sed 's/^.*probe-log: //; s/^.*chat CHAT_MSG_SYSTEM: //' | \
        sort -u | head -8 >> "$RESULTS"
    echo "" >> "$RESULTS"
done

cat "$RESULTS" >&2
