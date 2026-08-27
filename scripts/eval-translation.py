#!/usr/bin/env python3
"""Score a candidate model's Bislama/Fijian translation against the
fluent-speaker-reviewed catalogs in locales/.

Why this exists: the assistant grew one-tap translate buttons in 26.08.14
and lost them in 26.08.15, because the model behind them could not actually
translate into either language -- Fijian came out with Samoan morphology,
Bislama as parroted example phrases. "Looks plausible to someone who does
not speak it" is exactly the failure mode, so candidates are scored against
reviewed references instead of eyeballed.

Measured baselines (2026-08-27, temperature 0.3, presence_penalty 1.5,
few-shot prompts, 5 held-out pairs per language):

    Qwen3-4B    Q4_K_M   bi F1 0.05   fj F1 0.08   (Samoan tells in fj)
    Qwen3.5-4B  Q4_K_M   bi F1 0.06   fj F1 0.04

Anything proposing to bring translation features back should beat those by
a wide margin -- as a reference point, a usable translator should land
most of the reviewed vocabulary, not one token in twenty. The likely
candidates are dedicated MT models (e.g. NLLB-200 covers both languages),
not general chat models; see the removal comment in
ai-assistant/venu-pacific-assistant.

Usage: start any OpenAI-compatible server with the candidate model, then

    llama-server -m candidate.gguf --port 8091 --jinja
    ./scripts/eval-translation.py 8091

The few-shot examples and the scored pairs are disjoint, so a model cannot
score by echoing the prompt -- which is precisely what Qwen3.5-4B tried.
"""
import json
import re
import sys
import urllib.request
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent

SENTENCES = [
    "The cyclone is coming tomorrow. Please keep your family safe.",
    "Wash your hands before you eat.",
    "The school is closed today because of the storm.",
]

# Orthography that should NOT appear: fa'a-/'o le/macrons are Samoan, which
# both failing models drifted into for "Fijian".
SAMOAN_TELLS = ["fa'a", "fa’a", "'o le", "’o le", " le ", "ā", "ō", "ī"]

LANG_DESC = {
    "bi": ("Bislama", "Bislama, the English-based creole language of Vanuatu"),
    "fj": ("Fijian", "Fijian (na vosa vaka-Viti), the indigenous language of Fiji"),
}


def parse_po(path):
    text = Path(path).read_text()
    pairs = []
    for match in re.finditer(
        r'msgid\s+((?:"[^"]*"\s*)+)\s*msgstr\s+((?:"[^"]*"\s*)+)', text
    ):
        source = "".join(re.findall(r'"([^"]*)"', match.group(1)))
        target = "".join(re.findall(r'"([^"]*)"', match.group(2)))
        # Skip the header, format strings, language names (identity
        # translations score free points), and anything long enough to
        # make token-F1 mushy.
        if (source and target and "%" not in source and len(source) < 90
                and source.lower() not in ("bislama", "fijian", "english")):
            pairs.append((source, target))
    return pairs


def ask(port, prompt):
    body = {
        "messages": [{"role": "user", "content": prompt}],
        "temperature": 0.3,
        "max_tokens": 160,
        "presence_penalty": 1.5,
        "chat_template_kwargs": {"enable_thinking": False},
    }
    request = urllib.request.Request(
        f"http://127.0.0.1:{port}/v1/chat/completions",
        data=json.dumps(body).encode(),
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(request, timeout=900) as response:
        return json.load(response)["choices"][0]["message"]["content"].strip()


def token_f1(hypothesis, reference):
    tokens = lambda s: re.findall(r"[a-z']+", s.lower())
    hyp, ref = tokens(hypothesis), tokens(reference)
    if not hyp or not ref:
        return 0.0
    common = sum(min(hyp.count(w), ref.count(w)) for w in set(hyp))
    if not common:
        return 0.0
    precision, recall = common / len(hyp), common / len(ref)
    return 2 * precision * recall / (precision + recall)


def main():
    port = sys.argv[1] if len(sys.argv) > 1 else "8091"
    for lang in ("bi", "fj"):
        name, description = LANG_DESC[lang]
        pairs = parse_po(REPO / "locales" / lang / "venu-pacific.po")
        few_shot, held_out = pairs[:4], pairs[4:]
        shots = "\n".join(f'- "{a}" -> "{b}"' for a, b in few_shot)

        scores, samoan_hits = [], 0
        for source, reference in held_out:
            prompt = (
                f"{description}. Examples of correct translations:\n{shots}\n\n"
                f"Translate the following English text into {name}. "
                f"Output only the translation, nothing else:\n\n{source}"
            )
            hypothesis = ask(port, prompt)
            scores.append(token_f1(hypothesis, reference))
            samoan_hits += any(t in hypothesis.lower() for t in SAMOAN_TELLS)
            print(f"  {source[:36]!r:38} ref={reference[:28]!r:30} got={hypothesis[:44]!r}")

        mean = sum(scores) / len(scores) if scores else 0.0
        print(f"== {lang}: mean F1 {mean:.2f} over {len(scores)} held-out pairs; "
              f"samoan-tell in {samoan_hits} ==")
        for sentence in SENTENCES:
            prompt = (
                f"{description}. Examples:\n{shots}\n\nTranslate into {name}. "
                f"Output only the translation:\n\n{sentence}"
            )
            print(f"  free: {ask(port, prompt)[:100]}")
        print()


if __name__ == "__main__":
    main()
