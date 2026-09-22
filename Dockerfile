# Basis-Image von Docling-Serve (CPU-Version)
FROM quay.io/docling-project/docling-serve-cpu:latest

USER root

# Installiere huggingface_hub für den Modell-Download
RUN pip install --no-cache-dir huggingface_hub

# Verzeichnisse für Modelle und Cache erstellen
RUN mkdir -p /app/data/docling/models /app/data/.cache/huggingface

# Umgebungsvariablen für RunPod setzen
ENV DOCLING_SERVE_ARTIFACTS_PATH=/app/data
ENV HF_HOME=/app/data/.cache/huggingface
ENV HOST=0.0.0.0
ENV PORT=5001
ENV DOCLING_SERVE_ENABLE_UI=1

# Lade das CodeFormulaV2 Modell während des Builds herunter
RUN python -c "from huggingface_hub import snapshot_download; snapshot_download(repo_id='docling-project/CodeFormulaV2')"

# Berechtigungen für alle User öffnen (RunPod wechselt IDs dynamisch)
RUN chmod -R 777 /app/data

# Port 5001 für RunPod freigeben
EXPOSE 5001

# Starte das Uvicorn-Backend direkt auf Port 5001
CMD ["uvicorn", "docling_serve.main:app", "--host", "0.0.0.0", "--port", "5001"]
