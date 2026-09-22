# Offizielles CUDA 12.8 Basis-Image von Docling-Serve verwenden
FROM quay.io/docling-project/docling-serve-cu128:main

USER root

# Installiere huggingface_hub für den Modell-Download
RUN pip install --no-cache-dir huggingface_hub

# Erstelle die Verzeichnisse im langlebigen Workspace und im Standard-Pfad
RUN mkdir -p /workspace/docling-models /app/data

# Erstelle einen Symlink, damit RapidOCR seine Modelle im persistenten Workspace findet
RUN ln -s /workspace/docling-models/RapidOcr /app/data/RapidOcr

# Umgebungsvariablen für RunPod & GPU-Erkennung setzen
ENV HOST=0.0.0.0
ENV PORT=5001
ENV DOCLING_SERVE_ENABLE_UI=1
ENV DOCLING_DEVICE=cuda

# Pfade auf das permanente RunPod-Verzeichnis umleiten
ENV DOCLING_SERVE_ARTIFACTS_PATH=/workspace/docling-models
ENV HF_HOME=/workspace/docling-models/.cache/huggingface

# 1. Lade das CodeFormulaV2 Modell direkt in den Workspace herunter
RUN python -c "from huggingface_hub import snapshot_download; snapshot_download(repo_id='docling-project/CodeFormulaV2')"

# 2. Lädt die RapidOCR-Modelle direkt in den Workspace (durch den Symlink auch unter /app/data sichtbar)
RUN docling-tools models download rapidocr --rapidocr-backend-lang onnxruntime:ch -o /workspace/docling-models

# Berechtigungen für alle beteiligten Ordner weit öffnen (wichtig für RunPod-Instanzen)
RUN chmod -R 777 /workspace /app/data

# Port 5001 freigeben
EXPOSE 5001

# Startbefehl über das offizielle CLI-Tool
CMD ["docling-serve", "run"]
