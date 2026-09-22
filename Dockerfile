# Offizielles CUDA 12.8 Basis-Image von Docling-Serve verwenden
FROM quay.io/docling-project/docling-serve-cu128:main

USER root

# Erstelle die Backup- und Workspace-Verzeichnisse
RUN mkdir -p /app/bak/models /workspace/docling-models

# Umgebungsvariablen für RunPod & GPU-Erkennung setzen
ENV HOST=0.0.0.0
ENV PORT=5001
ENV DOCLING_SERVE_ENABLE_UI=1
ENV DOCLING_DEVICE=cuda

# Runtime-Pfade auf das permanente RunPod-Verzeichnis verweisen
ENV DOCLING_SERVE_ARTIFACTS_PATH=/workspace/docling-models
ENV HF_HOME=/workspace/docling-models/.cache/huggingface

# KORREKTUR: "--all" statt "--enrich". Lädt alle Docling-Modelle inklusive 
# RapidOCR und CodeFormula in perfekter Ordnerstruktur in das Backup-Verzeichnis.
RUN docling-tools models download --all -o /app/bak/models

# Berechtigungen für RunPod weit öffnen
RUN chmod -R 777 /app/bak /workspace

# Port 5001 freigeben
EXPOSE 5001

# Startbefehl: Befüllt das gemountete RunPod-Volume beim allerersten Booten.
# Bei jedem weiteren Neustart des Pods wird das Kopieren übersprungen.
CMD bash -c "\
mkdir -p /workspace/docling-models && \
if [ -z \"\$(ls -A /workspace/docling-models)\" ]; then \
    echo 'Initialisiere persistenten RunPod-Workspace mit allen Modellen (einmalig)...'; \
    cp -r /app/bak/models/* /workspace/docling-models/; \
fi && \
echo 'Modelle erfolgreich im Workspace verifiziert. Starte Docling Server...'; \
docling-serve run"
