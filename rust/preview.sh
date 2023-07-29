#! /bin/bash
# fix  below shellcheck warning
workspace=$(cd "$(dirname "$0")" && pwd -P)
cd "$workspace" || exit

chapterNo=${2:-"1"}
case "$1" in
"slide")
    if ! command -v marp &>/dev/null; then
        echo "marp-cli could not be found, install marp-cli"
        brew install marp-cli
    fi
    echo "Preview src/chapter_$chapterNo.md as slide"
    marp "src/chapter_$chapterNo.md" --preview
    ;;
*)
    if ! command -v mdbook &>/dev/null; then
        echo "mdbook could not be found, install mdbook"
        cargo install mdbook
    fi
    echo "Preview as mdbook"
    mdbook serve -p 3100 -n 127.0.0.1
    ;;
esac
