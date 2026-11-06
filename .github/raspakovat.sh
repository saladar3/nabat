#!/bin/bash
# Вызывается из .github/workflows/raspakovat.yml в корне репозитория.
set -euo pipefail
M=zagruzka/manifest.txt
[ -f "$M" ] || { echo "нет $M — ждём"; exit 0; }
val() { awk -v k="$1" '$1==k{print $2; exit}' "$M"; }
TARGET=$(val target); PARTS=$(val parts); SHA=$(val sha256)
case "$TARGET" in pikabu|yandex|vk|beta) ;; *) echo "недопустимая папка: $TARGET"; exit 1;; esac
[[ "$PARTS" =~ ^[0-9]+$ ]] && [[ "$SHA" =~ ^[0-9a-f]{64}$ ]] || { echo "manifest испорчен"; exit 1; }
N=$(find zagruzka -maxdepth 1 -name 'part.*' | wc -l)
[ "$N" -eq "$PARTS" ] || { echo "частей $N из $PARTS — ждём остальные"; exit 0; }
A=$(mktemp)
find zagruzka -maxdepth 1 -name 'part.*' | sort | xargs cat > "$A"
GOT=$(sha256sum "$A" | cut -d' ' -f1)
[ "$GOT" = "$SHA" ] || { echo "сумма не сошлась ($GOT) — ждём"; exit 0; }
NEW=$(mktemp -d)
unzip -q "$A" -d "$NEW"
[ -f "$NEW/index.html" ] || { echo "в архиве нет index.html"; exit 1; }
rm -rf "$TARGET"; mv "$NEW" "$TARGET"; chmod -R u=rwX,go=rX "$TARGET"
git rm -rq zagruzka
git add -A "$TARGET"
git config user.name "github-actions[bot]"
git config user.email "41898333+github-actions[bot]@users.noreply.github.com"
git commit -q -m "Сборка распакована в $TARGET/ (${SHA:0:12})"
git push -q origin HEAD:main
echo "распаковано: $TARGET/, файлов $(find "$TARGET" -type f | wc -l)"
[ -n "${GITHUB_OUTPUT:-}" ] && echo "done=1" >> "$GITHUB_OUTPUT"
exit 0
