#!/usr/bin/env python3
"""Exports the names the admin analytics page needs to show unused items.

Writes backend/data/analytics_catalog.json from the Dart sources:
  effects  <- EffectType enum (lib/pixel/effects/effects.dart)
  tools    <- PixelTool enum (lib/pixel/tools.dart)
  features <- AnalyticsFeature constants (lib/core/services/analytics_features.dart)

Run after adding an effect, tool or feature, then upload the JSON with the backend:
  python3 tool/export_analytics_catalog.py
"""
import json
import pathlib
import re

root = pathlib.Path(__file__).resolve().parent.parent


def enum_values(path: str, name: str) -> list[str]:
    text = (root / path).read_text()
    body = re.search(r'enum\s+' + name + r'\s*(?:implements[^{]*)?\{(.*?)\n\}', text, re.S).group(1)
    # Only the value list: it ends at the first ';' (members follow) or at the closing brace.
    values = body.split(';')[0]
    values = re.sub(r'//.*', '', values)
    return [v.strip() for v in values.split(',') if re.fullmatch(r'\s*[A-Za-z_]\w*\s*', v)]


def feature_names(path: str) -> list[str]:
    text = (root / path).read_text()
    return re.findall(r"static const \w+ = '([a-z_]+)';", text)


catalog = {
    'effects': enum_values('lib/pixel/effects/effects.dart', 'EffectType'),
    'tools': enum_values('lib/pixel/tools.dart', 'PixelTool'),
    'features': feature_names('lib/core/services/analytics_features.dart'),
}
out = root / 'backend' / 'data' / 'analytics_catalog.json'
out.parent.mkdir(exist_ok=True)
out.write_text(json.dumps(catalog, indent=2) + '\n')
print({k: len(v) for k, v in catalog.items()}, '->', out)
