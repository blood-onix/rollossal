# Negative tests for export_all.py: each fixture breaks one modelling rule, and the export must exit
# non-zero with a message naming that rule. Run from the repo root with the stdlib driver:
#   python3 -I art/scripts/test_export_negative.py [--blender /path/to/blender]
# The driver builds the fixture .blend files with Blender in a temp dir, then runs export_all.py
# against each one with --source. Blender is taken from --blender, $BLENDER, or PATH.

import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
EXPORT = os.path.join(HERE, "export_all.py")
SELF = os.path.abspath(__file__)

CELL_UV = (0.0625, 0.96875)  # centre of palette cell 0 (inner rect x 1..127, y 1..62 px)
EDGE_UV = ((0.05, 0.9), (0.2, 0.9))  # spans cell 0 and cell 1, outside both inner rects
OBJECT_ID = "acorn"  # tier 1, size 0.5, budget 500 triangles (budgets.json)

CASES = {
    "uv_across_cell_edge": ("UVs span outside every cell and strip", "cube", ["Palette"], "edge"),
    "second_material": ("expected exactly one material 'Palette'", "cube", ["Palette", "Extra"], "cell"),
    "over_budget_triangles": ("over budget 500", "sphere", ["Palette"], "cell"),
}


def build_fixtures(root: str) -> None:
    import bmesh
    import bpy

    for case, (_, kind, materials, uv_kind) in CASES.items():
        bpy.ops.wm.read_factory_settings(use_empty=True)
        collection = bpy.data.collections.new(OBJECT_ID)
        bpy.context.scene.collection.children.link(collection)

        bm = bmesh.new()
        if kind == "cube":
            bmesh.ops.create_cube(bm, size=0.5)
        else:
            bmesh.ops.create_uvsphere(bm, u_segments=64, v_segments=32, radius=0.25)
        bmesh.ops.translate(bm, verts=bm.verts, vec=(0.0, 0.0, 0.25))
        uv_layer = bm.loops.layers.uv.new("UVMap")
        for face in bm.faces:
            face.material_index = 1 if (case == "second_material" and face.index == 0) else 0
            for position, loop in enumerate(face.loops):
                if uv_kind == "edge" and face.index == 0:
                    loop[uv_layer].uv = EDGE_UV[position % 2]
                else:
                    loop[uv_layer].uv = CELL_UV

        mesh = bpy.data.meshes.new(OBJECT_ID)
        for name in materials:
            mesh.materials.append(bpy.data.materials.new(name))
        bm.to_mesh(mesh)
        bm.free()
        obj = bpy.data.objects.new(OBJECT_ID, mesh)
        collection.objects.link(obj)

        source = os.path.join(root, case, "source")
        os.makedirs(source, exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(source, f"{case}.blend"))


def run_case(blender: str, root: str, case: str, expected: str) -> str | None:
    base = os.path.join(root, case)
    out = os.path.join(base, "export")
    os.makedirs(out, exist_ok=True)
    result = subprocess.run(
        [blender, "--background", "--factory-startup", "--python", EXPORT, "--",
         "--source", os.path.join(base, "source"), "--out", out],
        capture_output=True, text=True,
    )
    text = result.stdout + result.stderr
    if result.returncode == 0:
        return f"{case}: export exited 0 on a broken fixture"
    if expected not in text:
        return f"{case}: exit {result.returncode}, but output lacks '{expected}'"
    print(f"PASS {case}: exit {result.returncode}, reports '{expected}'")
    return None


def main() -> int:
    args = sys.argv[1:]
    blender = os.environ.get("BLENDER") or shutil.which("blender")
    if "--blender" in args:
        blender = args[args.index("--blender") + 1]
    if not blender:
        print("FAIL: no Blender binary; pass --blender or set BLENDER", file=sys.stderr)
        return 1

    root = tempfile.mkdtemp(prefix="export-negative-")
    try:
        subprocess.run(
            [blender, "--background", "--factory-startup", "--python", SELF, "--", root],
            check=True, capture_output=True,
        )
        failures = [f for case, (expected, *_) in CASES.items()
                    if (f := run_case(blender, root, case, expected)) is not None]
    finally:
        shutil.rmtree(root, ignore_errors=True)

    for failure in failures:
        print(f"FAIL {failure}", file=sys.stderr)
    if failures:
        return 1
    print(f"OK: {len(CASES)} export failure paths exit non-zero with their rule named")
    return 0


if __name__ == "__main__":
    try:
        import bpy  # noqa: F401
    except ImportError:
        sys.exit(main())
    build_fixtures(sys.argv[sys.argv.index("--") + 1])
