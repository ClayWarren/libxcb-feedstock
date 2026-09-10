import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys

subdir = sys.argv[1]
os.environ.update(CONDA_SUBDIR=subdir, CONDA_SOLVER="libmamba", CONDA_CHANNEL_PRIORITY="strict")
local = Path("C:/libxcb-local")
conda = [sys.executable, "C:/libxcb-tools/Scripts/conda-script.py"]

def run(args):
    print(subprocess.list2cmdline([str(a) for a in args]), flush=True)
    subprocess.run(args, check=True)

run(conda + ["index", str(local)])
run(conda + ["build", "recipe", "-m", f".ci_support/{subdir.replace('-', '_')}_.yaml",
             "--variants", json.dumps({"build_platform": subdir}),
             "--croot", "C:/libxcb-build", "--output-folder", str(local), "--no-anaconda-upload",
             "--override-channels", "-c", "file:///C:/libxcb-local", "-c", "conda-forge"])
print(f"PASS: libxcb build and installed consumer tests on {subdir}", flush=True)
manifest = [{"file": p.name, "sha256": hashlib.sha256(p.read_bytes()).hexdigest()}
            for p in sorted((local / subdir).glob("*.conda"))]
(local / subdir / "sha256.json").write_text(json.dumps(manifest, indent=2))
