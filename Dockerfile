# Offizielles CUDA 12.8 Basis-Image von Docling-Serve verwenden
FROM quay.io/docling-project/docling-serve-cu128:main

USER root

# Installiere huggingface_hub für den Modell-Download
RUN pip install --no-cache-dir huggingface_hub

# Erstelle die Backup-Verzeichnisse im Image (isoliert von RunPods Mounts)
RUN mkdir -p /app/bak/RapidOcr /app/bak/.cache/huggingface /workspace/docling-models

# Umgebungsvariablen für RunPod & GPU-Erkennung setzen
ENV HOST=0.0.0.0
ENV PORT=5001
ENV DOCLING_SERVE_ENABLE_UI=1
ENV DOCLING_DEVICE=cuda

# Das ist der Pfad, den Docling erzwingt und unter dem es sucht
ENV DOCLING_SERVE_ARTIFACTS_PATH=/workspace/docling-models
ENV HF_HOME=/workspace/docling-models/.cache/huggingface

# 1. Lade CodeFormulaV2 in den HF-Backup-Pfad herunter
RUN python -c "import os; os.environ['HF_HOME']='/app/bak/.cache/huggingface'; from huggingface_hub import snapshot_download; snapshot_download(repo_id='docling-project/CodeFormulaV2')"

# 2. Lade RapidOCR direkt in den korrekten Unterordner des Backups herunter
RUN docling-tools models download rapidocr --rapidocr-backend-lang onnxruntime:ch -o /app/bak

# Berechtigungen für alle Verzeichnisse öffnen
RUN chmod -R 777 /app/bak /workspace

# Port 5001 freigeben
EXPOSE 5001

# Startbefehl: Prüft beim Booten, ob der Workspace leer ist. 
# Falls ja, kopiert er ALLE Modelle rüber und startet dann stabil den Server.
CMD bash -c "\
mkdir -p /workspace/docling-models/RapidOcr /workspace/docling-models/.cache/huggingface && \
if [ -z \"\$(ls -A /workspace/docling-models/RapidOcr)\" ]; then \
    echo 'Kopiere RapidOCR-Modelle in den permanenten Workspace...'; \
    cp -r /app/bak/RapidOcr/* /workspace/docling-models/RapidOcr/; \
fi && \
if [ -z \"\$(ls -A /workspace/docling-models/.cache/huggingface)\" ]; then \
    echo 'Kopiere CodeFormulaV2-Modelle in den permanenten Workspace...'; \
    cp -r /app/bak/.cache/huggingface/* /workspace/docling-models/.cache/huggingface/; \
fi && \
echo 'Alle Modelle verifiziert. Starte Docling Server...'; \
docling-serve run"
