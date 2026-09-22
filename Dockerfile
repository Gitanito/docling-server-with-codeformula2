FROM quay.io/docling-project/docling-serve-cu128:main

USER root

# Feste Pfade im Image
ENV DOCLING_SERVE_ARTIFACTS_PATH=/app/models
ENV HF_HOME=/app/models/.cache/huggingface

ENV UVICORN_HOST=0.0.0.0
ENV UVICORN_PORT=5001
ENV DOCLING_SERVE_ENABLE_UI=1
ENV DOCLING_DEVICE=cuda

# 1. Hugging Face & Basis-Modelle laden
# 2. Die fehlenden RapidOCR PP-OCRv6 ONNX-Modelle explizit mit herunterladen
RUN mkdir -p /app/models/.cache/huggingface && \
    docling-tools models download --all -o /app/models && \
    docling-tools models download rapidocr --rapidocr-backend-lang onnxruntime:ch -o /app/models

RUN chmod -R 777 /app/models

EXPOSE 5001

CMD ["docling-serve", "run", "--host", "0.0.0.0", "--port", "5001"]
