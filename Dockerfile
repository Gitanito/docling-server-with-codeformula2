# Offizielles CUDA 12.8 Basis-Image von Docling-Serve verwenden
FROM quay.io/docling-project/docling-serve-cu128:main

USER root

# Installiere huggingface_hub für den Modell-Download
RUN pip install --no-cache-dir huggingface_hub

# Erstelle die Verzeichnisse
RUN mkdir -p /workspace/docling-models /app/data/RapidOcr

# Umgebungsvariablen für RunPod & GPU-Erkennung setzen
ENV HOST=0.0.0.0
ENV PORT=5001
ENV DOCLING_SERVE_ENABLE_UI=1
ENV DOCLING_DEVICE=cuda

# Pfade für HuggingFace auf das permanente RunPod-Verzeichnis umleiten
ENV DOCLING_SERVE_ARTIFACTS_PATH=/workspace/docling-models
ENV HF_HOME=/workspace/docling-models/.cache/huggingface

# 1. Lade CodeFormulaV2 in ein temporäres Verzeichnis (wird beim ersten Start in den Workspace kopiert)
RUN python -c "import os; os.environ['HF_HOME']='/app/hf_bak'; from huggingface_hub import snapshot_download; snapshot_download(repo_id='docling-project/CodeFormulaV2')"

# 2. FIX: Lade RapidOCR DIREKT in den Systempfad, den es erwartet (isoliert von RunPods /workspace)
RUN docling-tools models download rapidocr --rapidocr-backend-lang onnxruntime:ch -o /app/data

# Berechtigungen für alle Ordner weit öffnen
RUN chmod -R 777 /workspace /app/data /app/hf_bak

# Port 5001 freigeben
EXPOSE 5001

# Startbefehl kombiniert: Kopiert bei Bedarf HF-Modelle in den Workspace und startet direkt
CMD bash -c "mkdir -p /workspace/docling-models/.cache/huggingface && if [ -z \"\$(ls -A /workspace/docling-models/.cache/huggingface)\" ]; then echo 'Kopiere CodeFormulaV2...'; cp -r /app/hf_bak/* /workspace/docling-models/.cache/huggingface/; fi && docling-serve run"
