#!/usr/bin/env python3
"""Generate Copywriting locale maps from the encrypted English source strings."""

from __future__ import annotations

import argparse
import base64
import re
import time
import json
import urllib.parse
import urllib.request
from pathlib import Path

from Crypto.Cipher import AES
from Crypto.Util.Padding import unpad


ROOT = Path(__file__).resolve().parents[2]
COPYWRITING_PATH = ROOT / "biz/lib/base/crypt/copywriting.dart"
OUTPUT_DIR = ROOT / "biz/lib/localize"
API_URL = "https://clients5.google.com/translate_a/t"

AES_KEY = b"CDhvMci5g7ExnCT885TqT7LT9S9I2A5l"
AES_IV = b"xm7uIbAfnoq8TxCJ"

LANGUAGES = {
    "de_DE": ("de", "German"),
    "fr_FR": ("fr", "French"),
    "it_IT": ("it", "Italian"),
    "pt_PT": ("pt", "European Portuguese"),
    "es_ES": ("es", "Spanish"),
    "ar_AE": ("ar", "Modern Standard Arabic"),
}

DO_NOT_TRANSLATE = {
    "security_sF_Pro",
    "security_sF_Pro_bold",
    "security_mM_dd_HH_mm",
    "security_mM_dd__HH_mm_",
}

MANUAL_TRANSLATIONS = {
    "de": {
        "security_just_now": "Gerade eben",
        "security_one_minute_ago": "Vor 1 Minute",
        "security_minutes_ago": "Vor {count} Minuten",
        "security_one_hour_ago": "Vor 1 Stunde",
        "security_hours_ago": "Vor {count} Stunden",
        "security_one_day_ago": "Vor 1 Tag",
        "security_days_ago": "Vor {count} Tagen",
        "security_one_week_ago": "Vor 1 Woche",
        "security_weeks_ago": "Vor {count} Wochen",
    },
    "fr": {
        "security_just_now": "À l'instant",
        "security_one_minute_ago": "Il y a 1 minute",
        "security_minutes_ago": "Il y a {count} minutes",
        "security_one_hour_ago": "Il y a 1 heure",
        "security_hours_ago": "Il y a {count} heures",
        "security_one_day_ago": "Il y a 1 jour",
        "security_days_ago": "Il y a {count} jours",
        "security_one_week_ago": "Il y a 1 semaine",
        "security_weeks_ago": "Il y a {count} semaines",
    },
    "it": {
        "security_just_now": "Proprio ora",
        "security_one_minute_ago": "1 minuto fa",
        "security_minutes_ago": "{count} minuti fa",
        "security_one_hour_ago": "1 ora fa",
        "security_hours_ago": "{count} ore fa",
        "security_one_day_ago": "1 giorno fa",
        "security_days_ago": "{count} giorni fa",
        "security_one_week_ago": "1 settimana fa",
        "security_weeks_ago": "{count} settimane fa",
    },
    "pt": {
        "security_just_now": "Agora mesmo",
        "security_one_minute_ago": "Há 1 minuto",
        "security_minutes_ago": "Há {count} minutos",
        "security_one_hour_ago": "Há 1 hora",
        "security_hours_ago": "Há {count} horas",
        "security_one_day_ago": "Há 1 dia",
        "security_days_ago": "Há {count} dias",
        "security_one_week_ago": "Há 1 semana",
        "security_weeks_ago": "Há {count} semanas",
    },
    "es": {
        "security_just_now": "Ahora mismo",
        "security_one_minute_ago": "Hace 1 minuto",
        "security_minutes_ago": "Hace {count} minutos",
        "security_one_hour_ago": "Hace 1 hora",
        "security_hours_ago": "Hace {count} horas",
        "security_one_day_ago": "Hace 1 día",
        "security_days_ago": "Hace {count} días",
        "security_one_week_ago": "Hace 1 semana",
        "security_weeks_ago": "Hace {count} semanas",
    },
    "ar": {
        "security_just_now": "الآن",
        "security_one_minute_ago": "منذ دقيقة واحدة",
        "security_minutes_ago": "منذ {count} د",
        "security_one_hour_ago": "منذ ساعة واحدة",
        "security_hours_ago": "منذ {count} س",
        "security_one_day_ago": "منذ يوم واحد",
        "security_days_ago": "منذ {count} يوم",
        "security_one_week_ago": "منذ أسبوع واحد",
        "security_weeks_ago": "منذ {count} أسبوع",
    },
}


def extract_copywriting() -> dict[str, str]:
    source = COPYWRITING_PATH.read_text(encoding="utf-8")
    pattern = re.compile(
        r"^\s*static\s+(?:late\s+final\s+String|String\s+get)\s+"
        r"(security_\w+)[\s\S]*?decrypt\(\s*['\"]([^'\"]+)['\"]"
        r"[\s\S]*?\);\s*//\s?(.*)$",
        re.MULTILINE,
    )
    result: dict[str, str] = {}
    for key, encoded, comment in pattern.findall(source):
        try:
            cipher = AES.new(AES_KEY, AES.MODE_CBC, AES_IV)
            plaintext = unpad(cipher.decrypt(base64.b64decode(encoded)), 16)
            result[key] = plaintext.decode("utf-8")
        except (ValueError, UnicodeDecodeError):
            result[key] = comment.replace(r"\'", "'").replace(r"\n", "\n")
    if not result:
        raise RuntimeError(f"No Copywriting entries found in {COPYWRITING_PATH}")
    return result


def translate(source: dict[str, str], target_language: str) -> dict[str, str]:
    result: dict[str, str] = {}
    manual = MANUAL_TRANSLATIONS.get(target_language, {})
    pending = [
        (key, value)
        for key, value in source.items()
        if key not in DO_NOT_TRANSLATE and key not in manual
    ]
    batches: list[list[tuple[str, str]]] = []
    current: list[tuple[str, str]] = []
    current_size = 0
    for item in pending:
        item_size = len(item[1]) + 16
        if current and current_size + item_size > 4500:
            batches.append(current)
            current = []
            current_size = 0
        current.append(item)
        current_size += item_size
    if current:
        batches.append(current)

    completed = 0
    for batch in batches:
        query = urllib.parse.urlencode(
            [
                ("client", "dict-chrome-ex"),
                ("sl", "en"),
                ("tl", target_language),
                *[("q", value) for _, value in batch],
            ]
        )
        request = urllib.request.Request(
            f"{API_URL}?{query}", headers={"User-Agent": "Mozilla/5.0"}
        )
        for attempt in range(4):
            try:
                with urllib.request.urlopen(request, timeout=60) as response:
                    translated = json.loads(response.read().decode("utf-8"))
                break
            except Exception:
                if attempt == 3:
                    raise
                time.sleep(2 ** attempt)
        if len(translated) != len(batch):
            raise RuntimeError(
                f"Expected {len(batch)} translations, received {len(translated)}"
            )
        result.update((key, str(value)) for (key, _), value in zip(batch, translated))
        completed += len(batch)
        print(f"  {completed}/{len(pending)}")
        time.sleep(0.25)

    return {
        key: source[key] if key in DO_NOT_TRANSLATE else manual.get(key, result[key])
        for key in source
    }


def dart_string(value: str) -> str:
    escaped = (
        value.replace("\\", "\\\\")
        .replace("'", "\\'")
        .replace("$", "\\$")
        .replace("\n", "\\n")
        .replace("\r", "\\r")
    )
    return f"'{escaped}'"


def render(locale: str, class_suffix: str, values: dict[str, str]) -> str:
    rows = "\n".join(
        f"    {dart_string(key)}: {dart_string(value)}," for key, value in values.items()
    )
    return (
        "// Generated by toolchain/translate/generate_copywriting_localizations.py.\n"
        "// Edit Copywriting or the generator instead of changing keys by hand.\n\n"
        f"abstract final class CopywritingStrings{class_suffix} {{\n"
        f"  static const Map<String, String> values = <String, String>{{\n{rows}\n  }};\n"
        "}\n"
    )


def rewrite_copywriting_getters() -> None:
    source = COPYWRITING_PATH.read_text(encoding="utf-8")
    declaration = re.compile(
        r"^(\s*)static late final String (security_\w+)\s*=\s*(decrypt\(.*\));(\s*//.*)$",
        re.MULTILINE,
    )

    def replacement(match: re.Match[str]) -> str:
        indent, key, decrypt_call, comment = match.groups()
        return (
            f"{indent}static String get {key} => "
            f"LocalizationService.text('{key}', () => {decrypt_call});{comment}"
        )

    rewritten, field_count = declaration.subn(replacement, source)
    getter = re.compile(
        r"^\s*static\s+String\s+get\s+(security_\w+)\s*=>"
        r"[\s\S]*?decrypt\(\s*['\"]([^'\"]+)['\"]\s*,?\s*\)"
        r"[\s\S]*?;\s*//\s?(.*)$",
        re.MULTILINE,
    )

    def compact(match: re.Match[str]) -> str:
        key, encrypted, comment = match.groups()
        return (
            f"  static String get {key} => LocalizationService.text("
            f"'{key}', () => decrypt('{encrypted}')); // {comment}"
        )

    rewritten, getter_count = getter.subn(compact, rewritten)
    if "// dart format off" not in rewritten:
        rewritten = rewritten.replace(
            "  Copywriting._();", "  Copywriting._();\n\n  // dart format off", 1
        )
        closing = rewritten.rfind("}")
        rewritten = rewritten[:closing] + "  // dart format on\n" + rewritten[closing:]
    COPYWRITING_PATH.write_text(rewritten, encoding="utf-8")
    print(
        f"Rewrote {field_count} fields and compacted {getter_count} localized getters."
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--locale", choices=list(LANGUAGES), action="append", help="Generate only this locale"
    )
    parser.add_argument("--rewrite-only", action="store_true")
    args = parser.parse_args()
    if args.rewrite_only:
        rewrite_copywriting_getters()
        return
    source = extract_copywriting()
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    (OUTPUT_DIR / "copywriting_strings_en.dart").write_text(
        render("en_US", "En", source), encoding="utf-8"
    )

    locales = args.locale or list(LANGUAGES)
    for locale in locales:
        file_suffix, language_name = LANGUAGES[locale]
        print(f"Translating {len(source)} entries to {language_name}...")
        values = translate(source, file_suffix)
        class_suffix = file_suffix.title()
        (OUTPUT_DIR / f"copywriting_strings_{file_suffix}.dart").write_text(
            render(locale, class_suffix, values), encoding="utf-8"
        )


if __name__ == "__main__":
    main()
