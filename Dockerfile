FROM quay.io/docling-project/docling-serve-cu128:main
USER root

ENV DOCLING_SERVE_ARTIFACTS_PATH=/app/models
ENV HF_HOME=/app/models/.cache/huggingface
ENV DOCLING_DEVICE=cuda

RUN mkdir -p /app/models/.cache/huggingface && \
    docling-tools models download --all -o /app/models && \
    docling-tools models download rapidocr --rapidocr-backend-lang onnxruntime:ch -o /app/models
RUN chmod -R 777 /app/models

RUN pip install --no-cache-dir "runpod>=1.6" requests

COPY handler.py /opt/app-root/src/handler.py
WORKDIR /opt/app-root/src
# WICHTIG: ersetzt den bisherigen docling-serve-Start
CMD ["python", "-u", "handler.py"]
