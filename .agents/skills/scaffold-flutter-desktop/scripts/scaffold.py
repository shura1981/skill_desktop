#!/usr/bin/env python3
"""
scaffold.py — Scaffold a new Flutter desktop project from the multi_window_app template.

Usage:
  python3 scaffold.py --name my_app [options]

Options:
  --name      Snake_case project name (required). Used as package name and binary name.
  --id        Application ID in reverse-domain format. Default: com.example.<name>
  --display   Human-readable application name. Default: Title-cased from --name.
  --desc      Short description for pubspec.yaml. Default: "A Flutter desktop application"
  --table     SQLite main table name. Default: same as --name
  --out       Parent directory where the project folder will be created. Default: current dir.

Example:
  python3 .github/skills/scaffold-flutter-desktop/scripts/scaffold.py \\
    --name invoice_manager \\
    --id com.acme.invoice_manager \\
    --display "Invoice Manager" \\
    --desc "Desktop invoice management application" \\
    --out ~/projects
"""

import argparse
import re
import shutil
import subprocess
import sys
from pathlib import Path

# ── Paths ─────────────────────────────────────────────────────────────────────
SKILL_DIR = Path(__file__).resolve().parent.parent
TEMPLATES_DIR = SKILL_DIR / "templates"

# ── Placeholder tokens ─────────────────────────────────────────────────────────
PLACEHOLDER_KEYS = [
    "{{PROJECT_NAME}}",
    "{{APP_NAME}}",
    "{{APP_ID}}",
    "{{APP_DESCRIPTION}}",
    "{{TABLE_NAME}}",
]

# Extensions of text files where placeholder substitution is applied.
TEXT_EXTENSIONS = {
    ".dart", ".yaml", ".yml", ".txt", ".md",
    ".cmake", ".cc", ".cpp", ".h", ".tmpl",
    ".gradle", ".xml", ".json", ".sh",
    # CMakeLists.txt has no extension in the glob, handled via .txt
}


def to_title(snake: str) -> str:
    return " ".join(word.capitalize() for word in snake.split("_"))


def is_text_file(path: Path) -> bool:
    return path.suffix.lower() in TEXT_EXTENSIONS or path.name in {
        "CMakeLists.txt", "Makefile", "Dockerfile", ".gitignore",
    }


def apply_substitutions(text: str, substitutions: dict) -> str:
    for placeholder, value in substitutions.items():
        text = text.replace(placeholder, value)
    return text


def copy_template_file(src: Path, dest: Path, substitutions: dict) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    if is_text_file(src):
        content = src.read_text(encoding="utf-8")
        content = apply_substitutions(content, substitutions)
        dest.write_text(content, encoding="utf-8")
    else:
        shutil.copy2(src, dest)
    rel = dest.relative_to(dest.parent.parent)
    print(f"  + {rel}")


def validate_project_name(name: str) -> str:
    name = name.lower().replace("-", "_").replace(" ", "_")
    if not re.match(r"^[a-z][a-z0-9_]*$", name):
        sys.exit(f"Error: invalid project name '{name}'. Use lowercase letters, digits, and underscores.")
    return name


def scaffold(
    project_name: str,
    app_id: str,
    app_name: str,
    app_description: str,
    table_name: str,
    out_dir: Path,
) -> None:
    out_path = out_dir / project_name

    if out_path.exists():
        sys.exit(f"Error: directory already exists: {out_path}")

    if not TEMPLATES_DIR.exists():
        sys.exit(
            f"Error: templates directory not found at {TEMPLATES_DIR}\n"
            "Run this script from the project root or adjust the SKILL_DIR path."
        )

    substitutions = {
        "{{PROJECT_NAME}}": project_name,
        "{{APP_NAME}}": app_name,
        "{{APP_ID}}": app_id,
        "{{APP_DESCRIPTION}}": app_description,
        "{{TABLE_NAME}}": table_name,
    }

    print(f"\nScaffolding Flutter desktop project '{project_name}'")
    print(f"  App ID:      {app_id}")
    print(f"  Display:     {app_name}")
    print(f"  Description: {app_description}")
    print(f"  Table name:  {table_name}")
    print(f"  Output:      {out_path}\n")

    # Walk all template files; strip .tmpl extension in destination.
    for src in sorted(TEMPLATES_DIR.rglob("*")):
        if src.is_dir():
            continue

        rel = src.relative_to(TEMPLATES_DIR)
        # Remove .tmpl suffix from destination filename.
        dest_name = str(rel)
        if dest_name.endswith(".tmpl"):
            dest_name = dest_name[:-5]
        dest = out_path / dest_name

        copy_template_file(src, dest, substitutions)

    print(f"\n{len(list(out_path.rglob('*')))} files created.")

    # Run flutter pub get
    flutter_cmd = shutil.which("fvm") and ["fvm", "flutter"] or ["flutter"]
    print(f"\nRunning `{' '.join(flutter_cmd)} pub get` ...")
    result = subprocess.run(flutter_cmd + ["pub", "get"], cwd=out_path)
    if result.returncode != 0:
        print("\n⚠️  flutter pub get failed. Run it manually inside the new project.")
    else:
        print(f"\n✅ Done! Project ready at: {out_path}")
        print("   Next steps:")
        print(f"   1. cd {out_path}")
        print("   2. Add your tray icon to assets/tray_icon.png")
        print("   3. Edit lib/app/window/main_window.dart to build your UI")
        print("   4. flutter run -d linux")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Scaffold a Flutter desktop project from the multi_window_app template.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("--name", required=True, help="Snake_case project name")
    parser.add_argument("--id", dest="app_id", default=None,
                        help="App ID reverse-domain (default: com.example.<name>)")
    parser.add_argument("--display", dest="app_name", default=None,
                        help="Human-readable app name (default: title-cased --name)")
    parser.add_argument("--desc", dest="app_description",
                        default="A Flutter desktop application",
                        help="Short description for pubspec.yaml")
    parser.add_argument("--table", dest="table_name", default=None,
                        help="SQLite main table name (default: same as --name)")
    parser.add_argument("--out", dest="out_dir", default=".",
                        help="Output parent directory (default: current directory)")
    args = parser.parse_args()

    project_name = validate_project_name(args.name)
    app_id = args.app_id or f"com.example.{project_name}"
    app_name = args.app_name or to_title(project_name)
    table_name = args.table_name or project_name
    out_dir = Path(args.out_dir).resolve()

    scaffold(project_name, app_id, app_name, args.app_description, table_name, out_dir)


if __name__ == "__main__":
    main()
