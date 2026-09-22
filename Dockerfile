# Offizielles CUDA 12.8 Basis-Image von Docling-Serve verwenden
FROM quay.io/docling-project/docling-serve-cu128:main

USER root

# Installiere huggingface_hub für den Modell-Download
RUN pip install --no-cache-dir huggingface_hub

# Erstelle temporäre Backup-Verzeichnisse für den Build-Prozess
RUN mkdir -p /app/models_bak /app/data

# Umgebungsvariablen für RunPod & GPU-Erkennung setzen
ENV HOST=0.0.0.0
ENV PORT=5001
ENV DOCLING_SERVE_ENABLE_UI=1
ENV DOCLING_DEVICE=cuda

# Pfade auf das permanente RunPod-Verzeichnis umleiten
ENV DOCLING_SERVE_ARTIFACTS_PATH=/workspace/docling-models
ENV HF_HOME=/workspace/docling-models/.cache/huggingface

# 1. Lade Modelle während des Builds in den Backup-Pfad
ENV HF_HOME_BAK=/app/models_bak/.cache/huggingface
RUN python -c "import os; os.environ['HF_HOME']='/app/models_bak/.cache/huggingface'; from huggingface_hub import snapshot_download; snapshot_download(repo_id='docling-project/CodeFormulaV2')"

# 2. Lade RapidOCR in den Backup-Pfad herunter
RUN docling-tools models download rapidocr --rapidocr-backend-lang onnxruntime:ch -o /app/models_bak

# Kopiere das Entrypoint-Skript hinein
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Berechtigungen für RunPod-User anpassen
RUN chmod -R 777 /app /app/data

# Port 5001 freigeben
EXPOSE 5001

# Nutze das Skript als Entrypoint
ENTRYPOINT ["/bin/bash", "/app/entrypoint.sh"]
