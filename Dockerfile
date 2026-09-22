FROM quay.io/docling-project/docling-serve-cu128:main

USER root

# 1. Temporärer Pfad für das Image-Backup (nicht /workspace!)
ENV TEMP_BACKUP=/app/bak/models
ENV HF_HOME=${TEMP_BACKUP}/.cache/huggingface

RUN mkdir -p ${TEMP_BACKUP}/.cache/huggingface && \
    docling-tools models download --all -o ${TEMP_BACKUP}

# 2. Runtime-Variablen auf das gemountete RunPod-Volume umstellen
ENV DOCLING_SERVE_ARTIFACTS_PATH=/workspace/docling-models
ENV HF_HOME=/workspace/docling-models/.cache/huggingface
ENV UVICORN_HOST=0.0.0.0
ENV UVICORN_PORT=5001
ENV DOCLING_SERVE_ENABLE_UI=1
ENV DOCLING_DEVICE=cuda

EXPOSE 5001

# 3. Startskript als Exec-Form: cp -a kopiert auch versteckte Dotfiles (.cache)
CMD ["bash", "-c", "\
mkdir -p /workspace/docling-models && \
if [ ! -d /workspace/docling-models/.cache ]; then \
    echo 'Initialisiere persistenten RunPod-Workspace mit allen Modellen...'; \
    cp -a /app/bak/models/. /workspace/docling-models/; \
    chmod -R 777 /workspace/docling-models; \
fi && \
echo 'Starte Docling Server...'; \
docling-serve run --host 0.0.0.0 --port 5001"]
