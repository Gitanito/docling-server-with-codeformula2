# Offizielles CUDA 12.8 Basis-Image von Docling-Serve verwenden
FROM quay.io/docling-project/docling-serve-cu128:main

USER root

# Installiere huggingface_hub für den Modell-Download
RUN pip install --no-cache-dir huggingface_hub

# Erstelle den gewünschten Zielordner im Workspace
RUN mkdir -p /workspace/docling-models

# Umgebungsvariablen für RunPod & GPU-Erkennung setzen
ENV HOST=0.0.0.0
ENV PORT=5001
ENV DOCLING_SERVE_ENABLE_UI=1
ENV DOCLING_DEVICE=cuda

# Pfade auf das permanente RunPod-Verzeichnis umleiten
ENV DOCLING_SERVE_ARTIFACTS_PATH=/workspace/docling-models
ENV HF_HOME=/workspace/docling-models/.cache/huggingface

# Lade das CodeFormulaV2 Modell während des Builds direkt dorthin herunter
RUN python -c "from huggingface_hub import snapshot_download; snapshot_download(repo_id='docling-project/CodeFormulaV2')"

# Berechtigungen für den gesamten Workspace weit öffnen
RUN chmod -R 777 /workspace

# Port 5001 freigeben
EXPOSE 5001

# Startbefehl über das offizielle CLI-Tool
CMD ["docling-serve", "run"]
