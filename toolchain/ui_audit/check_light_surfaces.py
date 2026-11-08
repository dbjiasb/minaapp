#!/usr/bin/env python3
"""Guard all Flutter route surfaces against reintroduced hardcoded dark chrome.

Photo/video pixels and explicit AppColors.mediaScrim/onMedia overlays are content,
not page surfaces. This audit examines code, skipping comments and string literals.
Run from any directory. --json emits the complete inspected UI/route inventory.
"""
import argparse
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[2]
LIB = ROOT / 'biz/lib'
LEX = re.compile(r'//[^\n]*|/\*[\s\S]*?\*/|(?:r)?(?:"""[\s\S]*?"""|\'\'\'[\s\S]*?\'\'\'|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\')')
DARK_ALIASES = re.compile(r'AppColors\.(?:base_background|main|secondPage|ocBox|color_ff202026|mainDarkColor)\b')
BG = re.compile(r'\b(backgroundColor|canvasColor|fillColor|bgColor)\s*:\s*(?:const\s+)?(Color\(0[xX]([0-9a-fA-F]{8})\)|Colors\.(black\d*|grey(?:\[\d+\])?))')


def code_only(source):
    return LEX.sub(lambda match: ''.join('\n' if c == '\n' else ' ' for c in match.group()), source)


def luminance(rgb):
    channels = [int(rgb[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    channels = [c / 12.92 if c <= .04045 else ((c + .055) / 1.055) ** 2.4 for c in channels]
    return sum(a * b for a, b in zip(channels, (.2126, .7152, .0722)))


def audit():
    issues = []
    inventory = []
    for path in sorted(LIB.rglob('*.dart')):
        if '/crypt/' in str(path) or path.name == 'app_theme.dart':
            continue
        raw = path.read_text()
        code = code_only(raw)
        if not re.search(r'\b(?:Widget|Scaffold|StatelessWidget|StatefulWidget|GetView|Color|AppColors)\b', code):
            continue
        relative = str(path.relative_to(ROOT))
        inventory.append({'file': relative, 'scaffolds': len(re.findall(r'\bScaffold\s*\(', code)),
                          'app_bars': len(re.findall(r'\bAppBar\s*\(', code)),
                          'dialogs_or_sheets': len(re.findall(r'\b(?:dialog|bottomSheet|showDialog|showModalBottomSheet)\s*[<(]', code))})
        findings = [(m.start(), 'legacy color alias: use a semantic surface or foreground') for m in DARK_ALIASES.finditer(code)]
        for match in BG.finditer(code):
            value = match.group(3)
            if not value or (int(value[:2], 16) >= 128 and luminance(value[2:]) < .35):
                findings.append((match.start(), 'hardcoded dark page/input background'))
        for match in re.finditer(r'\bSystemUiOverlayStyle\.light\b', code):
            findings.append((match.start(), 'status bar style does not follow AppAppearance'))
        # Surface tokens as foregrounds produce white-on-white headers/icons.
        for match in re.finditer(r'\b(?:TextStyle|IconThemeData|Icon)\s*\([^()]*?\bcolor:\s*AppColors\.(?:background|surface|surfaceMuted)\b', code):
            findings.append((match.start(), 'surface token used for text/icon foreground'))
        for offset, reason in findings:
            issues.append({'file': relative, 'line': code.count('\n', 0, offset) + 1, 'reason': reason})
    root_source = (LIB / 'app/root_view.dart').read_text()
    routes = re.findall(r'GetPage\s*\(\s*name:\s*(Routers\.\w+)', root_source)
    return {'routes': routes, 'ui_files': inventory, 'issues': issues}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--json', action='store_true')
    args = parser.parse_args()
    report = audit()
    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        print(f"Scanned {len(report['ui_files'])} UI files, {len(report['routes'])} named routes, "
              f"{sum(f['scaffolds'] for f in report['ui_files'])} scaffolds.")
        for issue in report['issues']:
            print(f"{issue['file']}:{issue['line']}: {issue['reason']}")
        print(f"Issues: {len(report['issues'])}")
    return bool(report['issues'])


if __name__ == '__main__':
    sys.exit(main())
