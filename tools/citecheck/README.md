# citecheck

Checks the citations in lines added to the docs, before they are committed.
Written after two citation failures sat in committed docs for two days
(`docs/findings.md`, 2026-09-27): a reference whose article number belonged to
an unrelated paper, and a rule attributed to EARS-Net with no page, which the
EARS-Net protocol contradicts.

| Check | What it catches | Blocks? |
|---|---|---|
| C1 | A reference (DOI, or `volume(issue): page`) that disagrees with its Crossref record on title, first author, volume, issue or page | yes |
| C2 | A link that is gone (404, 410) | yes; other failures warn |
| C3 | A block quote that is not verbatim in the PDF it is attributed to, or not on the cited page | yes |
| C4 | A clause naming a watched body (EARS-Net, SPARES, …) and making a claim, with no locator (p., §, section, table, annex, Note, or a journal reference) | yes |

Only added lines are checked, so old text is never flagged until someone edits
it. When Crossref or a link cannot be reached, the result is a warning, never a
block.

## Install

Once per clone:

```bash
git config core.hooksPath .githooks
```

The hook runs `citecheck.py --staged`. CI (`.github/workflows/citecheck.yml`)
runs the same checks on every pull request and push to `main`, for clones where
the hook is not enabled.

## When it flags something

Fix the citation: add the page, correct the reference, quote the source word
for word. A block quote promises the exact words, so a translation or paraphrase
belongs in plain text instead.

If a flagged sentence only mentions a body without claiming anything about it,
put this in the paragraph, with the reason:

```markdown
<!-- citecheck: ok, names SPARES as the legacy system, claims nothing about it -->
```

## Run by hand

```bash
python tools/citecheck/citecheck.py --staged              # what the hook does
python tools/citecheck/citecheck.py --base origin/main    # lines added since a ref
python tools/citecheck/citecheck.py docs/methods/07-dedoublonnage.md   # whole file
python tools/citecheck/citecheck.py --all                 # whole repo (audit)
```

## Configuration

`.citecheck.toml` at the repository root holds everything specific to this
project: which files to check, the watched bodies, and which PDF each source
alias (`SPARES`, `SPF`, …) refers to. Page numbers are physical PDF pages. A
quote's source is an alias followed by a page (`SPARES p. 16`) in or next to the
quote, or else an alias in the heading above it (`## What SPARES says`).

`citecheck.py` itself holds nothing project-specific. To use it in another
repository, copy it with its own `.citecheck.toml`.

## Tests

```bash
python -m unittest discover tools/citecheck/tests
```

The tests replay the recorded Crossref answers in `tests/fixtures/crossref`, so
they run offline. After adding a test that needs a new Crossref answer, record
it with `CITECHECK_RECORD=1` set. Crossref answers are cached in
`.git/citecheck-cache` so that the hook stays fast.

Requirements: Python 3.11 or newer (standard library only), and `pdftotext`
(poppler; shipped with Git for Windows) for C3.
