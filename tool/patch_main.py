#!/usr/bin/env python3
"""Re-apply the responsive MaterialApp.builder to lib/main.dart.

FlutterFlow regenerates main.dart on every export, dropping any manual edit.
This script re-inserts a single line that delegates to ResponsiveShell.app
(which lives in lib/custom_code/widgets/, a directory FlutterFlow never
regenerates). It is idempotent: running it on an already-patched file is a
no-op. Run automatically by .github/workflows/reapply-responsive.yml.
"""
import pathlib
import sys

MAIN = pathlib.Path("lib/main.dart")

IMPORT_ANCHOR = "import 'flutter_flow/flutter_flow_util.dart';"
IMPORT_LINE = "import 'custom_code/widgets/index.dart';"

BUILDER_ANCHOR = "routerConfig: _router,"
BUILDER_LINE = (
    "routerConfig: _router,\n"
    "      builder: (context, child) => ResponsiveShell.app(context, child),"
)


def main() -> int:
    if not MAIN.exists():
        print(f"::error::{MAIN} not found", file=sys.stderr)
        return 1

    src = MAIN.read_text()
    changed = False

    if IMPORT_LINE not in src:
        if IMPORT_ANCHOR not in src:
            print(f"::error::import anchor not found in {MAIN}", file=sys.stderr)
            return 1
        src = src.replace(IMPORT_ANCHOR, IMPORT_ANCHOR + "\n" + IMPORT_LINE, 1)
        changed = True

    if "ResponsiveShell.app" not in src:
        if BUILDER_ANCHOR not in src:
            print(f"::error::'{BUILDER_ANCHOR}' not found in {MAIN}", file=sys.stderr)
            return 1
        src = src.replace(BUILDER_ANCHOR, BUILDER_LINE, 1)
        changed = True

    if changed:
        MAIN.write_text(src)
        print("patched lib/main.dart")
    else:
        print("lib/main.dart already patched — nothing to do")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
