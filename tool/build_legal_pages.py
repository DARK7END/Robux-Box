#!/usr/bin/env python3
"""Renders the legal markdown in docs/ into styled HTML pages under public/,
which Firebase Hosting serves at https://<project>.web.app/privacy and /terms.

Google Play requires a publicly reachable privacy-policy URL, so these pages
are what the store listing and the in-app links point at.

Run after editing either document:

    python3 tool/build_legal_pages.py
"""
import html
import os
import re

ROOT = os.path.join(os.path.dirname(__file__), "..")
DOCS = os.path.join(ROOT, "docs")
OUT = os.path.join(ROOT, "public")

PAGES = [
    ("PRIVACY_POLICY.md", "privacy.html", "Privacy Policy"),
    ("TERMS_OF_SERVICE.md", "terms.html", "Terms of Service"),
]

CSS = """
:root { color-scheme: dark; }
* { box-sizing: border-box; }
body {
  margin: 0;
  padding: 0 20px 80px;
  background: #090909;
  color: #E8EAE8;
  font: 16px/1.65 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
}
.wrap { max-width: 760px; margin: 0 auto; }
header {
  padding: 40px 0 28px;
  border-bottom: 1px solid rgba(255,255,255,0.10);
  margin-bottom: 32px;
}
.brand {
  display: inline-flex; align-items: center; gap: 10px;
  font-weight: 800; font-size: 20px; letter-spacing: -0.3px;
  color: #fff; text-decoration: none;
}
.brand span { color: #00FF6A; }
h1 { font-size: 30px; line-height: 1.2; margin: 22px 0 0; letter-spacing: -0.6px; }
h2 {
  font-size: 19px; margin: 38px 0 12px; color: #fff;
  letter-spacing: -0.2px;
}
p, li { color: #B7BCB7; }
a { color: #00FF6A; }
ul { padding-left: 22px; }
li { margin: 6px 0; }
strong { color: #fff; }
hr { border: 0; border-top: 1px solid rgba(255,255,255,0.10); margin: 34px 0; }
footer {
  margin-top: 48px; padding-top: 22px;
  border-top: 1px solid rgba(255,255,255,0.10);
  font-size: 14px; color: #74786F;
}
footer a { margin-right: 16px; }
"""


def inline(text: str) -> str:
    """Escapes HTML, then applies bold, code and link markdown."""
    text = html.escape(text)
    text = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r'<a href="\2">\1</a>', text)
    text = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", text)
    text = re.sub(r"`([^`]+)`", r"<code>\1</code>", text)
    return text


def md_to_html(md: str) -> tuple[str, str]:
    """Returns (page_title, body_html). The first `# ` heading is the title and
    is rendered as the page's <h1>."""
    title = ""
    out: list[str] = []
    in_list = False
    para: list[str] = []

    def flush_para():
        nonlocal para
        if para:
            out.append(f"<p>{inline(' '.join(para))}</p>")
            para = []

    def close_list():
        nonlocal in_list
        if in_list:
            out.append("</ul>")
            in_list = False

    for raw in md.splitlines():
        line = raw.rstrip()
        stripped = line.strip()

        if not stripped:
            flush_para()
            close_list()
            continue

        if stripped.startswith("# "):
            flush_para()
            close_list()
            title = stripped[2:].strip()
            out.append(f"<h1>{inline(title)}</h1>")
        elif stripped.startswith("## "):
            flush_para()
            close_list()
            out.append(f"<h2>{inline(stripped[3:].strip())}</h2>")
        elif stripped.startswith("---"):
            flush_para()
            close_list()
            out.append("<hr>")
        elif stripped.startswith("- "):
            flush_para()
            if not in_list:
                out.append("<ul>")
                in_list = True
            out.append(f"<li>{inline(stripped[2:].strip())}</li>")
        else:
            # A continuation line inside a list item keeps that item going.
            if in_list and raw.startswith("  "):
                out[-1] = out[-1][:-5] + " " + inline(stripped) + "</li>"
            else:
                close_list()
                para.append(stripped)

    flush_para()
    close_list()
    return title, "\n".join(out)


def page(title: str, body: str) -> str:
    return f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{html.escape(title)} — Robux Box</title>
<style>{CSS}</style>
</head>
<body>
<div class="wrap">
  <header>
    <a class="brand" href="/">Robux <span>Box</span></a>
  </header>
  {body}
  <footer>
    <a href="/privacy.html">Privacy Policy</a>
    <a href="/terms.html">Terms of Service</a>
  </footer>
</div>
</body>
</html>
"""


INDEX = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Robux Box</title>
<style>%s</style>
</head>
<body>
<div class="wrap">
  <header>
    <a class="brand" href="/">Robux <span>Box</span></a>
    <h1>Play. Earn. Redeem.</h1>
  </header>
  <p>Earn coins by watching ads and completing offers, then redeem them for
  Robux, gift cards and digital codes.</p>
  <p><strong>Robux Box is not affiliated with, endorsed by, or sponsored by
  Roblox Corporation.</strong></p>
  <h2>Legal</h2>
  <ul>
    <li><a href="/privacy.html">Privacy Policy</a></li>
    <li><a href="/terms.html">Terms of Service</a></li>
  </ul>
</div>
</body>
</html>
""" % CSS


def main():
    os.makedirs(OUT, exist_ok=True)
    for src, dest, label in PAGES:
        with open(os.path.join(DOCS, src), encoding="utf-8") as f:
            md = f.read()
        if "[COMPANY NAME]" in md or "[DATE]" in md:
            print(f"  ⚠  {src} still has unfilled [PLACEHOLDERS] — "
                  f"Google Play will reject the listing until they are replaced.")
        title, body = md_to_html(md)
        with open(os.path.join(OUT, dest), "w", encoding="utf-8") as f:
            f.write(page(title or label, body))
        print(f"  {src} → public/{dest}")

    with open(os.path.join(OUT, "index.html"), "w", encoding="utf-8") as f:
        f.write(INDEX)
    print("  → public/index.html")
    print("Done. Deploy with: firebase deploy --only hosting")


if __name__ == "__main__":
    main()
