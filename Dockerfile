# Offizielles CUDA 12.8 Basis-Image von Docling-Serve verwenden
FROM quay.io/docling-project/docling-serve-cu128:main

USER root

# Erstelle die Backup-Verzeichnisse im unveränderlichen Image-Bereich
RUN mkdir -p /app/bak/models /workspace/docling-models

# Umgebungsvariablen für RunPod & GPU-Erkennung setzen
ENV HOST=0.0.0.0
ENV PORT=5001
ENV DOCLING_SERVE_ENABLE_UI=1
ENV DOCLING_DEVICE=cuda

# WICHTIG: Wir biegen die Pfade für die RUNTIME auf den persistenten Workspace um
ENV DOCLING_SERVE_ARTIFACTS_PATH=/workspace/docling-models
ENV HF_HOME=/workspace/docling-models/.cache/huggingface

# 1. Herunterladen aller benötigten Modelle während der Build-Phase in das Backup-Verzeichnis
# Docling-tools sorgt automatisch für die exakt richtige Ordnerstruktur im Filesystem!
RUN docling-tools models download rapidocr --rapidocr-backend-lang onnxruntime:ch -o /app/bak/models
RUN docling-tools models download code-formula -o /app/bak/models

# Berechtigungen für RunPod weit öffnen
RUN chmod -R 777 /app/bak /workspace

# Port 5001 freigeben
EXPOSE 5001

# Startbefehl: Wenn der langlebige RunPod-Workspace beim ersten Start leer ist,
# kopieren wir die fertig vorstrukturierten Modelle rüber. Danach startet der Server direkt.
CMD bash -c "\
mkdir -p /workspace/docling-models && \
if [ -z \"\$(ls -A /workspace/docling-models)\" ]; then \
    echo 'Kopiere vorkonfigurierte Modelle in den RunPod-Workspace (einmalig)...'; \
    cp -r /app/bak/models/* /workspace/docling-models/; \
fi && \
echo 'Modelle verifiziert. Starte Docling-Server mit GPU-Support...'; \
docling-serve run"
