#!/usr/bin/env python3
"""Re-apply the whole responsive layer after a FlutterFlow export.

FlutterFlow owns lib/ and regenerates it on every export, deleting the
ResponsiveShell widget, the index.dart export line, and the main.dart builder.
This script lives under .github/ (which FlutterFlow never touches) and restores
all three from the canonical copy in .github/responsive/. It is idempotent:
run on an already-restored tree it changes nothing. Invoked by
.github/workflows/reapply-responsive.yml on every push to `flutterflow`.
"""
import pathlib
import sys

ROOT = pathlib.Path(".")
TEMPLATE = ROOT / ".github/responsive/responsive_shell.dart"
WIDGET = ROOT / "lib/custom_code/widgets/responsive_shell.dart"
INDEX = ROOT / "lib/custom_code/widgets/index.dart"
MAIN = ROOT / "lib/main.dart"

EXPORT_LINE = "export 'responsive_shell.dart' show ResponsiveShell;"

IMPORT_ANCHOR = "import 'flutter_flow/flutter_flow_util.dart';"
IMPORT_LINE = "import 'custom_code/widgets/index.dart';"

BUILDER_ANCHOR = "routerConfig: _router,"
BUILDER_LINE = (
    "routerConfig: _router,\n"
    "      builder: (context, child) => ResponsiveShell.app(context, child),"
)


def ensure_widget() -> None:
    if not TEMPLATE.exists():
        print(f"::error::{TEMPLATE} missing — cannot restore widget", file=sys.stderr)
        sys.exit(1)
    WIDGET.parent.mkdir(parents=True, exist_ok=True)
    want = TEMPLATE.read_text()
    if not WIDGET.exists() or WIDGET.read_text() != want:
        WIDGET.write_text(want)
        print(f"restored {WIDGET}")


def ensure_index() -> None:
    if not INDEX.exists():
        print(f"::warning::{INDEX} missing — skipping export line")
        return
    s = INDEX.read_text()
    if EXPORT_LINE not in s:
        if not s.endswith("\n"):
            s += "\n"
        s += EXPORT_LINE + "\n"
        INDEX.write_text(s)
        print("added ResponsiveShell export to index.dart")


def ensure_main() -> None:
    if not MAIN.exists():
        print(f"::error::{MAIN} not found", file=sys.stderr)
        sys.exit(1)
    s = MAIN.read_text()
    changed = False
    if IMPORT_LINE not in s:
        if IMPORT_ANCHOR not in s:
            print(f"::error::import anchor not found in {MAIN}", file=sys.stderr)
            sys.exit(1)
        s = s.replace(IMPORT_ANCHOR, IMPORT_ANCHOR + "\n" + IMPORT_LINE, 1)
        changed = True
    if "ResponsiveShell.app" not in s:
        if BUILDER_ANCHOR not in s:
            print(f"::error::'{BUILDER_ANCHOR}' not found in {MAIN}", file=sys.stderr)
            sys.exit(1)
        s = s.replace(BUILDER_ANCHOR, BUILDER_LINE, 1)
        changed = True
    if changed:
        MAIN.write_text(s)
        print("patched lib/main.dart")


if __name__ == "__main__":
    ensure_widget()
    ensure_index()
    ensure_main()
    print("responsive layer up to date")
