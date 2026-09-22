#!/bin/bash
set -e

echo "=== RunPod Bootstrapping ==="

# Erstelle die nötigen Ordnerstrukturen im langlebigen Workspace
mkdir -p /workspace/docling-models/.cache/huggingface
mkdir -p /app/data

# Falls die Modelle noch nicht im Workspace liegen, kopiere sie aus dem Backup-Ordner
if [ ! -d "/workspace/docling-models/RapidOcr" ]; then
    echo "Kopiere Modelle in den permanenten RunPod-Workspace (nur beim ersten Start)..."
    cp -r /app/models_bak/* /workspace/docling-models/
fi

# Erstelle den Symlink dynamisch zur Laufzeit, damit RunPod ihn nicht überschreibt
rm -rf /app/data/RapidOcr
ln -sf /workspace/docling-models/RapidOcr /app/data/RapidOcr

echo "Modelle erfolgreich verknüpft. Starte Docling Server..."
exec docling-serve run
