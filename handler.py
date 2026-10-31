import base64, io, json, logging
import runpod

from docling.datamodel.base_models import DocumentStream, InputFormat
from docling.datamodel.pipeline_options import PdfPipelineOptions
from docling.document_converter import DocumentConverter, PdfFormatOption

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("docling-handler")

FILE_KEYS = ("base64_data", "base64_string", "file", "document", "document_base64",
             "base64", "data", "data_uri", "file_data", "file_base64", "pdf_base64",
             "content", "blob")

def _base64_of(inp):
    for key in FILE_KEYS:
        value = inp.get(key)
        if isinstance(value, str) and len(value) > 64:
            return value.split(",", 1)[-1]
    raise ValueError(f"Kein Dateiinhalt im input (keys={list(inp.keys())})")

def _options(inp):
    """Optionen sowohl FLACH (input.do_formula_enrichment) als auch unter input.options."""
    merged = {}
    for key, value in inp.items():
        if key.startswith("_") or key in FILE_KEYS:
            continue
        if key in ("sources", "target", "filename", "file_name", "mime_type",
                   "format", "output_format", "return_markdown", "export_markdown"):
            continue
        merged[key] = value
    nested = inp.get("options")
    if isinstance(nested, dict):
        merged.update(nested)
    elif isinstance(nested, str):
        try:
            merged.update(json.loads(nested))
        except Exception:
            pass
    return merged

def _set(obj, attr, value):
    try:
        setattr(obj, attr, value)
        log.info("Option gesetzt: %s=%r", attr, value)
    except Exception as exc:
        log.warning("Konnte %s nicht setzen: %s", attr, exc)

def build_pipeline_options(opts):
    p = PdfPipelineOptions()

    _set(p, "do_ocr", bool(opts.get("do_ocr", True)))
    _set(p, "force_ocr", bool(opts.get("force_ocr", False)))
    _set(p, "do_table_structure", bool(opts.get("do_table_structure", True)))

    # PFLICHT für Formel- und Bild-Enrichment (ohne Seitenbilder nur Platzhalter!)
    _set(p, "generate_page_images", True)
    _set(p, "generate_picture_images", True)
    try:
        _set(p, "images_scale", float(opts.get("images_scale", 1)))
    except (TypeError, ValueError):
        pass

    # Formeln / Code -> LaTeX
    _set(p, "do_formula_enrichment", bool(opts.get("do_formula_enrichment", True)))
    _set(p, "do_code_enrichment", bool(opts.get("do_code_enrichment", True)))
    preset = opts.get("code_formula_preset") or "codeformulav2"
    try:
        from docling.datamodel.pipeline_options import CodeFormulaVlmOptions
        formula_opts = CodeFormulaVlmOptions.from_preset(preset)
        for attr in ("code_formula_options", "code_formula_vlm_options"):
            if hasattr(p, attr):
                _set(p, attr, formula_opts)
                break
    except Exception as exc:
        log.warning("Formel-Preset %s nicht verfügbar: %s", preset, exc)

    # Bilder beschreiben (optional – braucht ein VLM im Modell-Cache)
    if bool(opts.get("do_picture_description", opts.get("include_images", False))):
        _set(p, "do_picture_description", True)
        pic_preset = opts.get("picture_description_preset") or "smolvlm"
        for cls_name in ("PictureDescriptionVlmEngineOptions", "PictureDescriptionVlmOptions"):
            try:
                mod = __import__("docling.datamodel.pipeline_options", fromlist=[cls_name])
                pic_opts = getattr(mod, cls_name).from_preset(pic_preset)
                for attr in ("picture_description_options", "picture_description_model_options"):
                    if hasattr(p, attr):
                        _set(p, attr, pic_opts)
                        break
                break
            except Exception as exc:
                log.warning("Bild-Preset %s (%s) nicht verfügbar: %s", pic_preset, cls_name, exc)

    return p

def handler(job):
    inp = job.get("input") or {}
    log.info("Input-Keys: %s", list(inp.keys()))
    raw = base64.b64decode(_base64_of(inp))
    name = inp.get("file_name") or inp.get("filename") or "upload.pdf"
    opts = _options(inp)
    log.info("Optionen: %s", json.dumps(opts, ensure_ascii=False)[:2000])

    converter = DocumentConverter(
        format_options={InputFormat.PDF: PdfFormatOption(pipeline_options=build_pipeline_options(opts))}
    )
    result = converter.convert(DocumentStream(name=name, stream=io.BytesIO(raw)))
    md = result.document.export_to_markdown()
    log.info("Fertig: %d Zeichen, %d LaTeX-Blöcke, Platzhalter: %d",
             len(md), md.count("$$") // 2, md.count("formula-not-decoded"))
    return {"data": md, "format": "markdown", "status": "success"}

runpod.serverless.start({"handler": handler})
