#!/usr/bin/env python3
"""Scrape Hyprland source code for config values and generate JSON schemas."""

import argparse
import json
import os
import re
import sys
from pathlib import Path
from typing import Any


def format_title_label(key: str) -> str:
    """Convert option name to human-friendly Title Case label."""
    leaf = key.split(":")[-1]
    if leaf.startswith("col."):
        leaf = leaf[4:] + " color"
    words = leaf.replace("_", " ").replace("-", " ").split()
    acronyms = {"vrr", "vfr", "hdr", "kb", "dpms", "lmb", "rmb", "mmb", "xwayland", "anr", "fps", "cm", "sdr", "eotf", "icc", "vcgt", "fp16", "hw", "ctm"}
    formatted = []
    for w in words:
        if w.lower() in acronyms:
            formatted.append(w.upper())
        else:
            formatted.append(w.capitalize())
    return " ".join(formatted)


def parse_default_value(raw_val: str, opt_type: str) -> Any:
    raw_val = raw_val.strip()
    if raw_val == "STRVAL_EMPTY" or raw_val == '""' or raw_val == "''":
        return ""
    if raw_val.startswith('"') and raw_val.endswith('"'):
        return raw_val[1:-1]
    if raw_val == "true":
        return True
    if raw_val == "false":
        return False
    if "CHyprColor" in raw_val:
        m = re.search(r"0x([0-9a-fA-F]+)", raw_val)
        if m:
            return f"0x{m.group(1).lower()}"
        return raw_val
    if raw_val.startswith("0x") or raw_val.startswith("0X"):
        return raw_val.lower()
    if "VEC2" in raw_val or "Config::VEC2" in raw_val:
        m = re.search(r"\{([-\d.]+)\s*,\s*([-\d.]+)\}", raw_val)
        if m:
            return f"{m.group(1)} {m.group(2)}"
        return "0 0"

    # Numeric
    if opt_type == "int":
        try:
            return int(raw_val.rstrip("FfUuLl"))
        except ValueError:
            pass
    elif opt_type == "float":
        try:
            return float(raw_val.rstrip("Ff"))
        except ValueError:
            pass

    return raw_val.rstrip("Ff")


def scrape_config_values(hyprland_src_path: Path) -> list[dict[str, Any]]:
    values_cpp = hyprland_src_path / "src" / "config" / "values" / "ConfigValues.cpp"
    if not values_cpp.exists():
        print(f"Error: Could not find {values_cpp}", file=sys.stderr)
        sys.exit(1)

    content = values_cpp.read_text(encoding="utf-8")

    options: list[dict[str, Any]] = []

    ms_pattern = re.compile(
        r'MS<([a-zA-Z0-9_]+)>\s*\(\s*"([^"]+)"\s*,\s*"((?:\\.|[^"\\])*)"\s*(?:,\s*([^,;()]+(?:\([^)]*\))?(?:\{[^}]*\})?))?(?:,\s*\{([^}]*)\})?\s*\)',
        re.DOTALL
    )

    for match in ms_pattern.finditer(content):
        raw_type, key, description, raw_default, raw_options = match.groups()
        
        type_lower = raw_type.lower()
        if type_lower in ("int", "cintvalue"):
            opt_type = "int"
        elif type_lower in ("float", "cfloatvalue"):
            opt_type = "float"
        elif type_lower in ("bool", "cboolvalue"):
            opt_type = "bool"
        elif type_lower in ("string", "cstringvalue"):
            opt_type = "string"
        elif type_lower in ("color", "gradient", "ccolorvalue", "cgradientvalue"):
            opt_type = "color"
        elif type_lower in ("vec2", "cvec2value"):
            opt_type = "vec2"
        elif type_lower in ("cssgap", "ccssgapvalue"):
            opt_type = "int"
        elif type_lower in ("fontweight", "cfontweightvalue"):
            opt_type = "string"
        else:
            opt_type = "string"

        default_val = parse_default_value(raw_default or "", opt_type) if raw_default else None

        desc_clean = description.strip()
        if desc_clean and desc_clean[0].islower():
            desc_clean = desc_clean[0].upper() + desc_clean[1:]

        opt: dict[str, Any] = {
            "key": key,
            "label": format_title_label(key),
            "description": desc_clean,
            "type": opt_type,
        }
        if default_val is not None:
            opt["default"] = default_val

        if raw_options:
            min_m = re.search(r'\.min\s*=\s*([-\d.]+)[Ff]?', raw_options)
            if min_m:
                val = float(min_m.group(1)) if opt_type == "float" else int(float(min_m.group(1)))
                opt["min"] = val

            max_m = re.search(r'\.max\s*=\s*([-\d.]+)[Ff]?', raw_options)
            if max_m:
                val = float(max_m.group(1)) if opt_type == "float" else int(float(max_m.group(1)))
                opt["max"] = val

            map_m = re.search(r'OptionMap\s*\{([^}]*)\}', raw_options)
            if map_m:
                map_content = map_m.group(1)
                entry_pattern = re.compile(r'\{\s*"([^"]+)"\s*,\s*([-\d]+)\s*\}')
                values_list = []
                for em in entry_pattern.finditer(map_content):
                    lbl, vid = em.groups()
                    values_list.append({"id": int(vid), "label": format_title_label(lbl), "value": lbl})
                if values_list:
                    opt["type"] = "choice"
                    opt["values"] = values_list

            choice_m = re.search(r'strChoice\s*\(\s*\{([^}]*)\}\s*\)', raw_options)
            if choice_m:
                choices = [c.strip().strip('"') for c in choice_m.group(1).split(",") if c.strip().strip('"')]
                opt["type"] = "choice"
                opt["values"] = [{"id": c, "label": format_title_label(c), "value": c} for c in choices]

            dep_m = re.search(r'\.deprecationNotice\s*=\s*"([^"]+)"', raw_options)
            if dep_m:
                opt["deprecation_notice"] = dep_m.group(1)

        if opt_type == "float" and "step" not in opt:
            if "min" in opt and "max" in opt:
                diff = opt["max"] - opt["min"]
                if diff <= 2.0:
                    opt["step"] = 0.05
                elif diff <= 10.0:
                    opt["step"] = 0.1
                else:
                    opt["step"] = 0.5
            else:
                opt["step"] = 0.05

        options.append(opt)

    return options


def organize_into_groups(options: list[dict[str, Any]]) -> dict[str, Any]:
    group_meta = {
        "general": {"label": "General", "icon": "sliders-horizontal-arrow-symbolic"},
        "decoration": {"label": "Decoration", "icon": "appearance-symbolic"},
        "input": {"label": "Input", "icon": "input-keyboard-symbolic"},
        "gestures": {"label": "Gestures", "icon": "input-touchpad-symbolic"},
        "group": {"label": "Window Groups", "icon": "view-grid-symbolic"},
        "misc": {"label": "Miscellaneous", "icon": "preferences-other-symbolic"},
        "binds": {"label": "Keybinds & Navigation", "icon": "input-keyboard-symbolic"},
        "cursor": {"label": "Cursor & Pointer", "icon": "input-mouse-symbolic"},
        "xwayland": {"label": "XWayland", "icon": "application-x-executable-symbolic"},
        "ecosystem": {"label": "Ecosystem & Permissions", "icon": "security-high-symbolic"},
        "dwindle": {"label": "Dwindle Layout", "icon": "view-compact-symbolic"},
        "master": {"label": "Master Layout", "icon": "view-dual-symbolic"},
        "scrolling": {"label": "Scrolling Layout", "icon": "view-continuous-symbolic"},
        "render": {"label": "Rendering & Pipeline", "icon": "video-display-symbolic"},
        "opengl": {"label": "OpenGL", "icon": "video-display-symbolic"},
        "debug": {"label": "Debug & Diagnostics", "icon": "tools-symbolic"},
        "quirks": {"label": "Quirks & Compatibility", "icon": "dialog-warning-symbolic"},
        "experimental": {"label": "Experimental", "icon": "applications-science-symbolic"},
        "input-capture": {"label": "Input Capture", "icon": "input-keyboard-symbolic"},
        "animations": {"label": "Animations", "icon": "media-playback-start-symbolic"},
    }

    groups_map: dict[str, dict[str, Any]] = {}

    for opt in options:
        parts = opt["key"].split(":")
        grp_id = parts[0]
        sec_id = ":".join(parts[:2]) if len(parts) > 1 else grp_id

        if grp_id not in groups_map:
            meta = group_meta.get(grp_id, {"label": format_title_label(grp_id), "icon": "preferences-other-symbolic"})
            groups_map[grp_id] = {
                "id": grp_id,
                "label": meta["label"],
                "icon": meta["icon"],
                "sections": {}
            }

        sec_map = groups_map[grp_id]["sections"]
        if sec_id not in sec_map:
            sec_label = format_title_label(parts[1]) if len(parts) > 1 else "General"
            sec_map[sec_id] = {
                "id": sec_id,
                "label": sec_label,
                "options": []
            }

        sec_map[sec_id]["options"].append(opt)

    groups_list = []
    for grp in groups_map.values():
        grp["sections"] = list(grp["sections"].values())
        groups_list.append(grp)

    return {"groups": groups_list}


def main():
    parser = argparse.ArgumentParser(description="Scrape Hyprland source code for configuration schemas")
    parser.add_argument("--hyprland-src", type=Path, default=Path("/home/dim/Projects/Hyprland"), help="Path to Hyprland source root")
    parser.add_argument("--output-dir", type=Path, default=Path(__file__).parent.parent / "data" / "schema", help="Output directory for JSON schemas")
    args = parser.parse_args()

    print(f"Scraping Hyprland configuration values from: {args.hyprland_src}")
    options = scrape_config_values(args.hyprland_src)
    print(f"Extracted {len(options)} configuration options.")

    args.output_dir.mkdir(parents=True, exist_ok=True)

    # 1. Output flat dictionary catalog
    options_by_key = {opt["key"]: opt for opt in options}
    catalog_path = args.output_dir / "hyprland_options.json"
    with open(catalog_path, "w", encoding="utf-8") as f:
        json.dump(options_by_key, f, indent=2)
    print(f"Wrote full catalog ({len(options_by_key)} keys) to {catalog_path}")

    # 2. Output organized groups & sections hierarchy
    hierarchy = organize_into_groups(options)
    options_json_path = args.output_dir / "options.json"
    with open(options_json_path, "w", encoding="utf-8") as f:
        json.dump(hierarchy, f, indent=2)
    print(f"Wrote organized schema hierarchy ({len(hierarchy['groups'])} groups) to {options_json_path}")


if __name__ == "__main__":
    main()
