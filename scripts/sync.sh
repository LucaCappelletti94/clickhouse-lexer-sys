#!/usr/bin/env bash
# Replace upstream/ with the lexer sources shipped by a ClickHouse/clickhouse-lexer release.
#
# usage: scripts/sync.sh [tag]    (default: the latest release)
#
# Exits with:
#   0 - upstream/ changed
#   2 - upstream/ unchanged
#   1 - error

set -euo pipefail
cd "$(dirname "$0")/.."

REPO=ClickHouse/clickhouse-lexer
FILES=(Lexer.cpp Lexer.h LexerStandalone.h clickhouse_lexer.h COMMIT)

TAG="${1:-}"
if [ -z "$TAG" ]; then
    TAG=$(curl -sSf "https://api.github.com/repos/$REPO/releases/latest" \
        | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p')
fi
[ -n "$TAG" ] || { echo "could not determine the latest $REPO release" >&2; exit 1; }

for f in "${FILES[@]}"; do
    curl -sSf "https://raw.githubusercontent.com/$REPO/$TAG/upstream/$f" -o "upstream/$f"
done
echo "$TAG" > upstream/VERSION

echo "Synced upstream/ from $REPO@$TAG (ClickHouse/ClickHouse@$(cat upstream/COMMIT))"

if git diff --quiet -- upstream/; then
    echo "upstream/ is unchanged."
    exit 2
fi

git --no-pager diff --stat -- upstream/
