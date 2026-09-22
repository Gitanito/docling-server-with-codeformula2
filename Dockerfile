# Offizielles CUDA 12.8 Basis-Image von Docling-Serve verwenden
FROM quay.io/docling-project/docling-serve-cu128:main

USER root

# Installiere huggingface_hub für den direkten Download
RUN pip install --no-cache-dir huggingface_hub

# Erstelle ein isoliertes Backup-Verzeichnis im Image
RUN mkdir -p /app/bak/models/RapidOcr /workspace/docling-models

# Umgebungsvariablen für RunPod & GPU-Erkennung setzen
ENV HOST=0.0.0.0
ENV PORT=5001
ENV DOCLING_SERVE_ENABLE_UI=1
ENV DOCLING_DEVICE=cuda

# Pfade für die RUNTIME auf den permanenten Workspace umbiegen
ENV DOCLING_SERVE_ARTIFACTS_PATH=/workspace/docling-models
ENV HF_HOME=/workspace/docling-models/.cache/huggingface

# 1. Download von CodeFormulaV2 direkt in die vom Server erwartete HF-Struktur
RUN python -c "import os; os.environ['HF_HOME']='/app/bak/models/.cache/huggingface'; from huggingface_hub import snapshot_download; snapshot_download(repo_id='docling-project/CodeFormulaV2')"

# 2. Download der 3 exakt geforderten RapidOCR-Modelle direkt von Hugging Face ohne das fehlerhafte docling-tools CLI
RUN python -c "\
import urllib.request;\
base_url = 'https://huggingface.co';\
models = ['det/PP-OCRv6_det_small.onnx', 'rec/PP-OCRv6_rec_small.onnx'];\
for m in models:\
    print(f'Lade {m}...');\
    os.makedirs(os.path.dirname(f'/app/bak/models/RapidOcr/{os.path.basename(m)}'), exist_ok=True);\
    urllib.request.urlretrieve(base_url + m, f'/app/bak/models/RapidOcr/{os.path.basename(m)}');\
"
# Zusätzliche fehlende Klassifizierungsdatei für RapidOCR herunterladen
RUN python -c "import urllib.request; urllib.request.urlretrieve('https://huggingface.co', '/app/bak/models/RapidOcr/ch_ppocr_mobile_v2.0_cls_mobile.onnx')"

# Berechtigungen für RunPod weit öffnen
RUN chmod -R 777 /app/bak /workspace

# Port 5001 freigeben
EXPOSE 5001

# Startbefehl: Schiebt beim First-Boot alle Modelle flach in den permanenten /workspace
CMD bash -c "\
mkdir -p /workspace/docling-models && \
if [ -z \"\$(ls -A /workspace/docling-models)\" ]; then \
    echo 'Kopiere Modelle flach in den RunPod-Workspace...'; \
    cp -r /app/bak/models/* /workspace/docling-models/; \
fi && \
echo 'Modelle verifiziert. Starte Docling-Server...'; \
docling-serve run"
