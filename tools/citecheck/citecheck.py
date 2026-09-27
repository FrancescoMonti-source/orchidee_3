#!/usr/bin/env python3
"""citecheck: check the citations in Markdown docs before they are committed.

Four deterministic checks, run on added lines only:

  C1  a journal reference agrees with its Crossref record
  C2  a link resolves
  C3  a block quote attributed to a registered PDF appears in that PDF
  C4  a claim attributed to a watched body carries a locator (page, section...)

Nothing here is specific to one project: the files to check, the watched bodies
and the source PDFs come from the config file (.citecheck.toml at the
repository root). Standard library only; C3 needs pdftotext (poppler).

Usage:  citecheck.py --staged | --base REF [--head REF] | --all | FILE...
"""

from __future__ import annotations

import argparse
import difflib
import fnmatch
import hashlib
import json
import re
import shutil
import subprocess
import sys
import tomllib
import unicodedata
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass, field
from pathlib import Path

USER_AGENT = "citecheck/0.1 (Markdown citation checker; python-urllib)"
OK_MARK = re.compile(r"<!--\s*citecheck:\s*ok\b")

# C4 vocabulary. A clause makes a claim about a body when it uses one of these
# words; it is located when it carries one of the LOCATOR forms. A journal
# reference counts as a locator because C1 checks it.
CLAIM = re.compile(
    r"\b(?:standards?|rules?|defin\w*|requir\w*|recommend\w*|mandat\w*|specif\w*|"
    r"prescri\w*|stipulat\w*|according to|states?|says|keeps?|counts?|exclud\w*|"
    r"includ\w*|guidelines?|protocols?|criteri\w*)\b",
    re.IGNORECASE,
)
LOCATOR = re.compile(
    r"\bpp?\.\s?\d|§\s?\d|\b(?:[Ss]ection|[Tt]able|[Aa]nnexe?|[Aa]ppendix|[Ff]igure|"
    r"[Ff]ig\.|[Cc]hapter|[Nn]ote)\s+[A-Z0-9][\w.]*"
    r"|\d+\s*\(\d+\)\s*:\s*e?\d+|\b10\.\d{4,9}/\S"
)

JOURNAL_REF = re.compile(r"(?<![\w.])(\d{1,4})\s*\((\d{1,4}(?:[-–]\d{1,4})?)\)\s*:\s*(e?\d+)")
DOI = re.compile(r"\b10\.\d{4,9}/[^\s\"<>)\]]+")
URL = re.compile(r"https?://[^\s<>()\[\]\"'`]+")
TITLE = re.compile(r"(?<![*\w])[*_](?![*\s])([^*_]{20,}?)(?<!\s)[*_](?![*\w])")
AUTHOR_ET_AL = re.compile(r"([A-Z][\w'’-]+)\s+et al\b")
AUTHOR_VANCOUVER = re.compile(r"([A-Z][\w'’-]+)\s+[A-Z]{1,3}\s*,")
ABBREVIATIONS = {"e.g", "i.e", "p", "pp", "al", "cf", "vs", "fig", "no", "vol", "ed", "etc"}


# ---------------------------------------------------------------- config ----

@dataclass
class Source:
    name: str
    aliases: list[str]
    pdf: str


@dataclass
class Config:
    include: list[str]
    bodies: list[str]
    sources: list[Source]

    def wants(self, path: str) -> bool:
        return any(fnmatch.fnmatch(path, pattern) for pattern in self.include)


def load_config(path: Path) -> Config:
    raw = tomllib.loads(Path(path).read_text(encoding="utf-8"))
    return Config(
        include=raw["include"],
        bodies=raw["bodies"],
        sources=[Source(s["name"], s["aliases"], s["pdf"]) for s in raw.get("source", [])],
    )


@dataclass
class Finding:
    path: str
    line: int
    severity: str  # "error" blocks the commit, "warning" does not
    check: str
    message: str

    def __str__(self) -> str:
        return f"{self.path}:{self.line}: {self.severity} {self.check}: {self.message}"


# --------------------------------------------------------------- network ----

class Offline(Exception):
    pass


class Net:
    """HTTP access. Crossref records never change, so they are cached on disk
    forever; offline=True serves only that cache (the tests replay it)."""

    def __init__(self, cache_dir: Path, offline: bool = False):
        self.cache_dir = Path(cache_dir)
        self.offline = offline

    def crossref(self, path: str, params: dict | None = None) -> dict | None:
        """The `message` of a Crossref reply, or None if Crossref has no such record."""
        url = "https://api.crossref.org/" + path
        if params:
            url += "?" + urllib.parse.urlencode(params)
        cached = self.cache_dir / (hashlib.sha1(url.encode()).hexdigest()[:16] + ".json")
        if cached.exists():
            return json.loads(cached.read_text(encoding="utf-8"))["message"]
        if self.offline:
            raise Offline(url)
        for attempt in (1, 2):  # Crossref has transient failures; one retry clears most
            try:
                with urllib.request.urlopen(_request(url), timeout=20) as reply:
                    data = json.load(reply)
                break
            except urllib.error.HTTPError as e:
                if e.code == 404:
                    data = {"message": None}
                    break
                if attempt == 2:
                    raise Offline(f"{url}: HTTP {e.code}") from e
            except (urllib.error.URLError, TimeoutError) as e:
                if attempt == 2:
                    raise Offline(url) from e
        data["url"] = url
        self.cache_dir.mkdir(parents=True, exist_ok=True)
        cached.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
        return data["message"]

    def status(self, url: str) -> int | None:
        """HTTP status of a link, None when unreachable. HEAD first, then GET,
        because some servers refuse HEAD."""
        if self.offline:
            return None
        code = None
        for method in ("HEAD", "GET"):
            try:
                with urllib.request.urlopen(_request(url, method), timeout=15) as reply:
                    return reply.status
            except urllib.error.HTTPError as e:
                code = e.code
            except (urllib.error.URLError, TimeoutError, ValueError):
                pass
        return code


def _request(url: str, method: str = "GET") -> urllib.request.Request:
    return urllib.request.Request(url, method=method, headers={"User-Agent": USER_AGENT})


# -------------------------------------------------------------- markdown ----

@dataclass
class Unit:
    """A paragraph, list item, table row, heading or block quote."""

    kind: str
    heading: str  # the nearest heading above it
    lines: list[tuple[int, str]] = field(default_factory=list)

    @property
    def text(self) -> str:
        return " ".join(s for _, s in self.lines)

    def line_at(self, offset: int) -> int:
        position = 0
        for number, s in self.lines:
            position += len(s) + 1
            if offset < position:
                return number
        return self.lines[-1][0]

    def touches(self, added: set[int] | None, start: int = 0, end: int | None = None) -> bool:
        if added is None:
            return True
        end = len(self.text) if end is None else end
        first, last = self.line_at(start), self.line_at(max(start, end - 1))
        return any(first <= n <= last for n in added)


FENCE = re.compile(r"^\s*(```|~~~)")
ITEM = re.compile(r"^\s*(?:[-*+]|\d+[.)])\s+")


def parse_units(text: str) -> list[Unit]:
    units: list[Unit] = []
    current: Unit | None = None
    heading, in_fence = "", False

    def close():
        nonlocal current
        if current and current.lines:
            units.append(current)
        current = None

    for number, line in enumerate(text.splitlines(), 1):
        if FENCE.match(line):
            close()
            in_fence = not in_fence
            continue
        stripped = line.strip()
        if in_fence or not stripped:
            close()
            continue
        if stripped.startswith("#"):
            close()
            heading = stripped.lstrip("#").strip()
            units.append(Unit("heading", heading, [(number, heading)]))
        elif stripped.startswith(">"):
            if current is None or current.kind != "quote":
                close()
                current = Unit("quote", heading)
            current.lines.append((number, stripped[1:].strip()))
        elif stripped.startswith("|"):
            close()
            if re.fullmatch(r"[|:\-\s]+", stripped) and units and units[-1].kind == "row":
                units[-1].kind = "header"
            units.append(Unit("row", heading, [(number, stripped)]))
        elif ITEM.match(line):
            close()
            current = Unit("item", heading, [(number, ITEM.sub("", line, count=1).strip())])
        else:
            if current is None or current.kind == "quote":
                close()
                current = Unit("para", heading)
            current.lines.append((number, stripped))
    close()
    return units


def mask(text: str, *patterns: str) -> str:
    """Blank out matches with spaces, keeping offsets (and so line numbers) intact."""
    for pattern in patterns:
        text = re.sub(pattern, lambda m: " " * len(m.group()), text, flags=re.DOTALL)
    return text


CODE_SPAN, COMMENT = r"`[^`]*`", r"<!--.*?-->"
QUOTED = r'"[^"\n]*"|“[^”]*”|«[^»]*»'


def sentences(text: str):
    """(start, end) spans of the sentences in text."""
    start = 0
    for m in re.finditer(r"[.!?](?=\s+[\"'(*_«\[]*[A-ZÀ-Ý])", text):
        before = re.search(r"([\w.]+)$", text[start:m.start()])
        if before and before.group(1).lower() in ABBREVIATIONS:
            continue
        yield start, m.end()
        start = m.end()
    if text[start:].strip():
        yield start, len(text)


def clauses(text: str, start: int, end: int):
    """Split a sentence at semicolons outside parentheses."""
    depth, begin = 0, start
    for i in range(start, end):
        c = text[i]
        depth += c == "("
        depth -= c == ")" and depth > 0
        if c == ";" and depth == 0:
            yield begin, i
            begin = i + 1
    yield begin, end


def fold(text: str) -> str:
    """Letters and digits only, casefolded, accents kept: the form quotes are matched in."""
    return "".join(c for c in unicodedata.normalize("NFKC", text).casefold() if c.isalnum())


def plain(text: str) -> str:
    """Casefolded, accents stripped: the form titles and author names are compared in."""
    decomposed = unicodedata.normalize("NFKD", text.casefold())
    return re.sub(r"\W+", " ", "".join(c for c in decomposed if not unicodedata.combining(c))).strip()


# ---------------------------------------------------------------- checks ----

def check_document(path: str, text: str, added: set[int] | None, config: Config,
                   net: Net, root: Path) -> list[Finding]:
    """All findings for one Markdown document. `added` is the set of added line
    numbers, or None to check every line."""
    units = parse_units(text)
    found: list[Finding] = []
    for i, unit in enumerate(units):
        if OK_MARK.search(unit.text) or not unit.touches(added):
            continue
        if unit.kind == "quote":
            found += check_quote(path, units, i, config, root)
            continue
        if unit.kind == "heading":
            continue
        found += check_references(path, unit, added, net)
        found += check_links(path, unit, added, net)
        # A reference list names bodies in titles without claiming anything; C1 checks it.
        if unit.kind != "header" and not REFERENCE_SECTION.search(unit.heading):
            found += check_attributions(path, unit, added, config)
    return found


REFERENCE_SECTION = re.compile(r"reference|bibliograph|sources", re.IGNORECASE)


def check_attributions(path: str, unit: Unit, added, config: Config) -> list[Finding]:
    """C4: a clause naming a watched body and making a claim needs a locator."""
    body = re.compile(r"(?<![\w-])(" + "|".join(map(re.escape, config.bodies)) + r")(?![\w-])")
    text = mask(unit.text, COMMENT, CODE_SPAN, URL.pattern, r"\*")
    found = []
    for s_start, s_end in sentences(text):
        for start, end in clauses(text, s_start, s_end):
            clause = text[start:end]
            names = list(dict.fromkeys(m.group() for m in body.finditer(clause)))
            if not names or not CLAIM.search(clause) or LOCATOR.search(clause):
                continue
            if not unit.touches(added, start, end):
                continue
            first = start + body.search(clause).start()
            found.append(Finding(
                path, unit.line_at(first), "error", "C4",
                f"claim attributed to {', '.join(names)} has no locator (p., §, section, "
                f"table, annex, Note): \"{_excerpt(clause)}\"",
            ))
    return found


def check_references(path: str, unit: Unit, added, net: Net) -> list[Finding]:
    """C1: a reference with a DOI or a volume(issue): page must match Crossref."""
    text = mask(unit.text, COMMENT, CODE_SPAN, QUOTED)
    spans = [(0, len(text))] if unit.kind in ("item", "row") else list(sentences(text))
    found = []
    for start, end in spans:
        segment = text[start:end]
        doi, ref = DOI.search(segment), JOURNAL_REF.search(segment)
        if not (doi or ref) or not unit.touches(added, start, end):
            continue
        line = unit.line_at(start + (doi or ref).start())
        try:
            if doi:
                record = net.crossref("works/" + urllib.parse.quote(doi.group().rstrip(".,;"), safe="/"))
                if record is None:
                    found.append(Finding(path, line, "error", "C1", f"DOI {doi.group()} is not in Crossref"))
                    continue
            else:
                query = re.sub(r"[*_\[\]<>]|\s+", " ", enclosing_parentheses(segment, ref.start())).strip()[:400]
                items = net.crossref("works", {"query.bibliographic": query, "rows": 1})["items"]
                record = items[0] if items else {}
        except Offline:
            found.append(Finding(path, line, "warning", "C1", "Crossref unreachable; reference not checked"))
            continue
        problems, identified = compare_reference(segment, ref, record)
        if not (doi or identified):
            # A search hit is only the cited work if its title or first author agrees.
            found.append(Finding(path, line, "warning", "C1",
                                 "Crossref search did not find this work; add its DOI or title to have it checked"))
        elif problems:
            found.append(Finding(path, line, "error", "C1", "; ".join(problems) + f". Crossref: {describe(record)}"))
    return found


def enclosing_parentheses(text: str, at: int) -> str:
    """The parenthesised citation around position `at`, else the whole text,
    so that a Crossref search is not diluted by the sentence around it."""
    depth = 0
    for i in range(at - 1, -1, -1):
        depth += (text[i] == ")") - (text[i] == "(")
        if depth < 0:
            for j in range(i + 1, len(text)):
                depth += (text[j] == "(") - (text[j] == ")")
                if depth < -1:
                    return text[i + 1:j]
            return text
    return text


def compare_reference(segment: str, ref, record: dict) -> tuple[list[str], bool]:
    """Where the citation disagrees with the record, and whether its title or
    first author agree (the record is then taken to be the cited work)."""
    problems, identified = [], False
    title = TITLE.search(segment)
    record_title = (record.get("title") or [""])[0]
    if title and record_title:
        ratio = difflib.SequenceMatcher(None, plain(title.group(1)), plain(record_title)).ratio()
        if ratio < 0.9:
            problems.append("title differs")
        else:
            identified = True
    if ref:
        volume, issue, page = ref.groups()
        record_page = (record.get("page") or record.get("article-number") or "").split("-")[0]
        for label, cited, actual in (("volume", volume, record.get("volume")),
                                     ("issue", issue, record.get("issue")),
                                     ("page", page, record_page)):
            if actual and cited.casefold() != actual.casefold():
                problems.append(f"{label} {cited} ≠ {actual}")
    author = AUTHOR_ET_AL.search(segment) or AUTHOR_VANCOUVER.search(segment)
    first = next((a.get("family", "") for a in record.get("author", []) if a.get("sequence") == "first"), "")
    if author and first:
        if plain(author.group(1)) != plain(first):
            problems.append(f"first author {author.group(1)} ≠ {first}")
        else:
            identified = True
    return problems, identified


def describe(record: dict) -> str:
    first = next((a.get("family", "") for a in record.get("author", [])), "?")
    title = (record.get("title") or ["?"])[0]
    page = record.get("page") or record.get("article-number") or "?"
    return (f"{first} et al., \"{_excerpt(title, 70)}\", {(record.get('container-title') or ['?'])[0]} "
            f"{record.get('volume', '?')}({record.get('issue', '?')}): {page}, doi:{record.get('DOI')}")


def check_links(path: str, unit: Unit, added, net: Net) -> list[Finding]:
    """C2: a link must resolve. Only a vanished page (404, 410) blocks."""
    found = []
    text = mask(unit.text, COMMENT)
    for m in URL.finditer(text):
        if not unit.touches(added, m.start(), m.end()):
            continue
        url = m.group().rstrip(".,;:*_")
        code = net.status(url)
        if code in (404, 410):
            found.append(Finding(path, unit.line_at(m.start()), "error", "C2", f"link is gone (HTTP {code}): {url}"))
        elif code is None or code >= 400:
            reason = "unreachable" if code is None else f"HTTP {code}"
            found.append(Finding(path, unit.line_at(m.start()), "warning", "C2", f"link not verified ({reason}): {url}"))
    return found


def check_quote(path: str, units: list[Unit], i: int, config: Config, root: Path) -> list[Finding]:
    """C3: a block quote attributed to a registered source must be in its PDF.

    The source is an alias followed by a page (`SPARES p. 16`) in the quote or
    the unit just before or after it; failing that, an alias in the heading
    above, with the page taken from a `(page 16)` inside the quote if there is
    one. Unattributed quotes are not checked."""
    quote = units[i]
    source, pages = None, None
    neighbours = [quote] + [units[j] for j in (i + 1, i - 1) if 0 <= j < len(units) and units[j].kind != "heading"]
    for s in config.sources:
        alias = "|".join(map(re.escape, s.aliases))
        page_ref = re.compile(rf"(?<![\w-])(?:{alias})(?![\w-])[^.\n]{{0,40}}?{PAGE}")
        m = next(filter(None, (page_ref.search(u.text) for u in neighbours)), None)
        if m:
            source, pages = s, (int(m.group(1)), int(m.group(2) or m.group(1)))
            break
    if source is None:
        source = next((s for s in config.sources
                       if any(re.search(rf"(?<![\w-]){re.escape(a)}(?![\w-])", quote.heading) for a in s.aliases)), None)
        m = IN_QUOTE_PAGE.search(quote.text)
        if source and m:
            pages = (int(m.group(1)), int(m.group(2) or m.group(1)))
    if source is None:
        return []

    line = quote.lines[0][0]
    pdf_pages = read_pdf(root / source.pdf)
    if isinstance(pdf_pages, str):
        return [Finding(path, line, "warning", "C3", pdf_pages)]

    body = IN_QUOTE_PAGE.sub(" ", " ".join(s for _, s in quote.lines if not re.match(r"^(?:—|--)", s)))
    parts = [p for p in re.split(r"\[[^\]]*\]|…|\.\.\.", body) if len(fold(p)) >= 12]
    folded = [fold(p) for p in pdf_pages]
    where = source.name
    if pages:
        where += f" p. {pages[0]}" if pages[0] == pages[1] else f" pp. {pages[0]}-{pages[1]}"
    for part in parts:
        fragment = fold(part)
        if pages:
            window = "".join(folded[pages[0] - 1:pages[1]])
            if fragment in window:
                continue
        elif fragment in "".join(folded):
            continue
        elsewhere = [n for n, p in enumerate(folded, 1) if fragment in p]
        hint = f"; it is on p. {elsewhere[0]}" if elsewhere else ""
        return [Finding(path, line, "error", "C3",
                        f"quoted text not found in {where}{hint}: \"{_excerpt(part, 70)}\"")]
    return []


PAGE = r"\b(?:pp?\.|[Pp]ages?)\s?(\d+)(?:\s*[-–]\s*(\d+))?"
IN_QUOTE_PAGE = re.compile(rf"\([^()]*?{PAGE}[^()]*\)")
_PDF_CACHE: dict[Path, list[str] | str] = {}


def pdftotext_path() -> str | None:
    for candidate in ("pdftotext", "C:/Program Files/Git/mingw64/bin/pdftotext.exe"):
        found = shutil.which(candidate)
        if found:
            return found
    return None


def read_pdf(pdf: Path) -> list[str] | str:
    """The text of each page, or a message saying why it could not be read."""
    if pdf not in _PDF_CACHE:
        tool = pdftotext_path()
        if tool is None:
            _PDF_CACHE[pdf] = "pdftotext not found; quote not checked"
        elif not pdf.exists():
            _PDF_CACHE[pdf] = f"source PDF missing: {pdf}"
        else:
            out = subprocess.run([tool, "-enc", "UTF-8", str(pdf), "-"], capture_output=True, check=True)
            _PDF_CACHE[pdf] = out.stdout.decode("utf-8", errors="replace").split("\f")
    return _PDF_CACHE[pdf]


def _excerpt(text: str, width: int = 90) -> str:
    text = re.sub(r"\s+", " ", text).strip()
    return text if len(text) <= width else text[: width - 1] + "…"


# ------------------------------------------------------------------- git ----

HUNK = re.compile(r"^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@")


def added_lines(diff: str) -> dict[str, set[int]]:
    """Added line numbers per file, from a `git diff -U0`."""
    files: dict[str, set[int]] = {}
    current = None
    for line in diff.splitlines():
        if line.startswith("+++ "):
            target = line[4:].rstrip("\t")
            current = None if target == "/dev/null" else target[2:]
            if current:
                files.setdefault(current, set())
        elif current and (m := HUNK.match(line)):
            start, count = int(m.group(1)), int(m.group(2) or 1)
            files[current].update(range(start, start + count))
    return files


def git(root: Path | None, *args: str) -> str:
    return subprocess.run(["git", "-c", "core.quotepath=off", *args], cwd=root, capture_output=True,
                          check=True, text=True, encoding="utf-8").stdout


def documents(args, root: Path, config: Config):
    """(path, text, added lines or None) for every document to check."""
    if args.staged or args.base:
        span = ["--cached"] if args.staged else [args.base, args.head]
        diff = git(root, "diff", "-U0", "--no-color", "--diff-filter=AMR", *span)
        for path, lines in sorted(added_lines(diff).items()):
            if config.wants(path) and lines:
                blob = f":{path}" if args.staged else f"{args.head}:{path}"
                yield path, git(root, "show", blob), lines
        return
    paths = args.files or [p for p in git(root, "ls-files").splitlines() if config.wants(p)]
    for path in paths:
        yield path, (root / path).read_text(encoding="utf-8"), None


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--staged", action="store_true", help="lines added in the index (pre-commit hook)")
    mode.add_argument("--base", metavar="REF", help="lines added between REF and --head (CI)")
    mode.add_argument("--all", action="store_true", help="every line of every included file")
    parser.add_argument("--head", default="HEAD", metavar="REF")
    parser.add_argument("--config", default=".citecheck.toml")
    parser.add_argument("files", nargs="*", help="check these files in full")
    args = parser.parse_args(argv)
    if not (args.staged or args.base or args.all or args.files):
        parser.error("say what to check: --staged, --base REF, --all or FILE...")

    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    root = Path(git(None, "rev-parse", "--show-toplevel").strip())
    config = load_config(root / args.config)
    net = Net(Path(git(root, "rev-parse", "--path-format=absolute", "--git-common-dir").strip()) / "citecheck-cache")

    found = []
    for path, text, added in documents(args, root, config):
        found += check_document(path, text, added, config, net, root)
    for finding in found:
        print(finding)
    errors = sum(f.severity == "error" for f in found)
    sys.stdout.flush()
    if errors:
        print(f"\ncitecheck: {errors} error(s). Fix the citation, or, if a flagged sentence only "
              "mentions a body without claiming anything, end its paragraph with "
              "<!-- citecheck: ok, <reason> -->.", file=sys.stderr)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
