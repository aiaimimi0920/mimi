# -*- mode: python ; coding: utf-8 -*-
import sys
sys.setrecursionlimit(sys.getrecursionlimit() * 5)
from PyInstaller.utils.hooks import collect_submodules, copy_metadata, collect_data_files, collect_all

datas=[]
binaries = []
hiddenimports = []

need_import_name = ["torch", "chromadb", "sentence_transformers", "safetensors", "importlib_metadata", 
        "regex","langchain","chardet","charset_normalizer","certifi","unstructured"]
for cur_name in need_import_name:
    cur_datas, cur_binaries, cur_hiddenimports = collect_all(cur_name)
    datas += cur_datas
    datas += copy_metadata(cur_name, recursive=True)
    binaries += cur_binaries
    hiddenimports += cur_hiddenimports
    print("cur_name: ",cur_name)


hiddenimports+=['onnxruntime','hnswlib','sklearn',"sklearn.metrics","sklearn.utils._cython_blas",
    "sklearn.metrics._pairwise_distances_reduction._datasets_pair","sklearn.metrics._pairwise_distances_reduction._middle_term_computer",
    "sklearn.utils._heap",'sklearn.utils._sorting',"sklearn.utils._vector_sentinel","sklearn.utils",
    "certifi","unstructured",
    'networkx',
    'aleph-alpha-client',
    'deeplake',
    'libdeeplake',
    'pgvector',
    'psycopg2-binary',
    'pyowm',
    'async-timeout',
    'azure-identity',
    'gptcache',
    'atlassian-python-api',
    'pytesseract',
    'html2text',
    'numexpr',
    'duckduckgo-search',
    'azure-cosmos',
    'lark',
    'lancedb',
    'pexpect',
    'pyvespa',
    'O365',
    'jq',
    'pdfminer-six',
    'docarray',
    'lxml',
    'pymupdf',
    'pypdfium2',
    'gql',
    'pandas',
    'telethon',
    'neo4j',
    'langkit',
    'chardet',
    'requests-toolbelt',
    'openlm',
    'scikit-learn',
    'azure-ai-formrecognizer',
    'azure-ai-vision',
    'azure-cognitiveservices-speech',
    'sqlalchemy',
    'databricks-sql-connector',
    'cnos-connector',
    'clearml',
    'spacy',
    "lxml._elementpath",
    ]
datas += ("C:/Users/vmjcv/.cache/torch/sentence_transformers/sentence-transformers_paraphrase-multilingual-MiniLM-L12-v2",
        "sentence-transformers_paraphrase-multilingual-MiniLM-L12-v2"),
datas += ("C:/Users/vmjcv/Envs/chroma/Lib/site-packages/unstructured/nlp/*.txt", "unstructured/nlp"),
datas += ("C:/Users/vmjcv/Envs/chroma/Lib/site-packages/iso639/languages.db", "iso639"),
datas += ("C:/Users/vmjcv/Envs/chroma/Lib/site-packages/langdetect/utils/messages.properties", "langdetect/utils"),
datas += ("C:/Users/vmjcv/Envs/chroma/Lib/site-packages/langdetect/profiles", "langdetect/profiles"),

a = Analysis(
    ['main.py'],
    pathex=[],
    binaries=binaries,
    datas=datas,
    hiddenimports = hiddenimports,
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=False,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.datas,
    [],
    name='main',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=True,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)
