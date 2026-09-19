#!/bin/bash
# uninstall.sh — Revierte install.sh.
rm -f "$HOME/.local/bin/jar_manager.sh" "$HOME/.local/bin/lang_es.sh" "$HOME/.local/bin/lang_en.sh"
rm -rf "$HOME/.local/bin/lib/jar_core.sh"
rm -f "$HOME/.local/share/applications/jar-manager.desktop"
rmdir "$HOME/.local/bin/lib" 2>/dev/null || true
echo "Desinstalado."
