# Offizielles CUDA 12.8 Basis-Image von Docling-Serve verwenden
FROM quay.io/docling-project/docling-serve-cu128:main

USER root

# Installiere huggingface_hub für den direkten Download
RUN pip install --no-cache-dir huggingface_hub

# Erstelle ein isoliertes Backup-Verzeichnis im Image
RUN mkdir -p /app/bak/models /workspace/docling-models

# Umgebungsvariablen für RunPod & GPU-Erkennung setzen
ENV HOST=0.0.0.0
ENV PORT=5001
ENV DOCLING_SERVE_ENABLE_UI=1
ENV DOCLING_DEVICE=cuda

# WICHTIG: Wir biegen Docling auf das vom System bevorzugte Cache-Muster um
ENV DOCLING_SERVE_ARTIFACTS_PATH=/workspace/docling-models
ENV HF_HOME=/workspace/docling-models/.cache/huggingface

# 1. Download von CodeFormulaV2 in den HF-Backup-Pfad während des Builds
RUN python -c "import os; os.environ['HF_HOME']='/app/bak/models/.cache/huggingface'; from huggingface_hub import snapshot_download; snapshot_download(repo_id='docling-project/CodeFormulaV2')"

# 2. Download der 3 von Docling erwarteten RapidOCR-Modelle über ein stabiles HuggingFace-Mirror Repository
RUN python -c "\
import urllib.request, os;\
base_url = 'https://huggingface.co';\
files = ['PP-OCRv6_det_small.onnx', 'PP-OCRv6_rec_small.onnx', 'ch_ppocr_mobile_v2.0_cls_mobile.onnx'];\
os.makedirs('/app/bak/models/RapidOcr', exist_ok=True);\
for f in files:\
    print(f'Lade {f} herunter...');\
    urllib.request.urlretrieve(base_url + f, f'/app/bak/models/RapidOcr/{f}');\
"

# Berechtigungen für RunPod weit öffnen
RUN chmod -R 777 /app/bak /workspace

# Port 5001 freigeben
EXPOSE 5001

# Startbefehl: Befüllt den gemounteten RunPod-Workspace beim allerersten Start mit den Backups
CMD bash -c "\
mkdir -p /workspace/docling-models && \
if [ -z \"\$(ls -A /workspace/docling-models)\" ]; then \
    echo 'Initialisiere persistenten RunPod-Workspace mit Modell-Artefakten...'; \
    cp -r /app/bak/models/* /workspace/docling-models/; \
fi && \
echo 'Modelle erfolgreich verifiziert. Starte Docling Server...'; \
docling-serve run"
