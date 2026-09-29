"""Acceptance tests for citecheck.

The two failures found on 2026-09-27 must be flagged, and their corrections
must pass. Crossref answers are replayed from tests/fixtures/crossref, so the
tests run offline; set CITECHECK_RECORD=1 to fetch and record missing ones.
The quote tests read the real SPARES PDF and are skipped without pdftotext.

Run from the repository root:  python -m unittest discover tools/citecheck/tests
"""

import os
import sys
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))

import citecheck as cc  # noqa: E402

REPO = HERE.parents[2]
CONFIG = cc.load_config(REPO / ".citecheck.toml")
NET = cc.Net(HERE / "fixtures" / "crossref", offline=not os.environ.get("CITECHECK_RECORD"))


def findings(text, check):
    found = cc.check_document("docs/x.md", text, None, CONFIG, NET, REPO)
    return [f for f in found if f.check == check]


# Case 1 — reference list entry as committed in 5c9a098. The DOI behind
# e0240902 is an unrelated article; the paper is Kajihara et al., 15(6): e0228234.
OLD_REFERENCE = (
    "4. **Ohmagari et al. (2020)**: *Comparison of de-duplication methods used by "
    "WHO Global Antimicrobial Resistance Surveillance System (GLASS) and Japan "
    "Nosocomial Infections Surveillance (JANIS) in the surveillance of antimicrobial "
    "resistance*. PLoS ONE 15(10): e0240902.\n"
)
CORRECTED_REFERENCE = (
    "4. **Kajihara T, Yahara K, Stelling J, et al. (2020)**: *Comparison of "
    "de-duplication methods used by WHO Global Antimicrobial Resistance Surveillance "
    "System (GLASS) and Japan Nosocomial Infections Surveillance (JANIS) in the "
    "surveillance of antimicrobial resistance*. PLoS ONE 15(6): e0228234. "
    "doi:10.1371/journal.pone.0228234. Checked. (Previously cited as \"Ohmagari et "
    "al., 15(10): e0240902\"; that DOI is an unrelated article.)\n"
)

# Case 2 — the claim as committed in 5ebd39c, and its correction.
OLD_EARS_NET = (
    "- **30-Day Rolling Refractory Window (European Reference)**: ORCHIDEE implements "
    "the European EARS-Net / ECDC 30-day episode standard using the **chronological "
    "sweep automaton** (`docs/evidence/dedup_window_30day_refractory_witness.md`), "
    "while preserving phenotype-awareness for emergent resistance under therapy.\n"
)
CORRECTED_EARS_NET = (
    "- **30-Day Rolling Refractory Window (Experiment)**: an ORCHIDEE experiment using "
    "the **chronological sweep automaton** "
    "(`docs/evidence/dedup_window_30day_refractory_witness.md`), preserving "
    "phenotype-awareness for emergent resistance under therapy. It is **not** a "
    "European standard. EARS-Net defines no episode: it keeps the first blood or CSF "
    "isolate per patient and pathogen in the calendar year (ECDC reporting protocol "
    "2025, p. 22 and pp. 24-25). The nearest published rule is Japan's JANIS: 30 days, "
    "whatever the specimen type, keeping isolates whose resistance phenotype changed "
    "(Kajihara et al., PLoS ONE 2020;15(6):e0228234).\n"
)


class Case1WrongReference(unittest.TestCase):
    def test_old_reference_is_flagged(self):
        found = findings(OLD_REFERENCE, "C1")
        self.assertEqual(len(found), 1, found)
        self.assertEqual(found[0].severity, "error")
        self.assertIn("e0228234", found[0].message)

    def test_old_reference_with_its_doi_is_flagged(self):
        text = OLD_REFERENCE.replace("e0240902.", "e0240902. doi:10.1371/journal.pone.0240902.")
        found = findings(text, "C1")
        self.assertEqual(len(found), 1, found)
        self.assertIn("title", found[0].message)

    def test_corrected_reference_passes(self):
        self.assertEqual(findings(CORRECTED_REFERENCE, "C1"), [])

    def test_inline_corrected_citation_passes(self):
        self.assertEqual(findings(CORRECTED_EARS_NET, "C1"), [])

    def test_unrelated_search_hit_only_warns(self):
        # Without a DOI, Crossref's top hit is the cited work only if its title or
        # first author agrees; otherwise it says nothing about the citation.
        text = "A made-up source (Zzyzxquo et al., Imaginary Journal 1999;3(2):e777).\n"
        self.assertEqual([f.severity for f in findings(text, "C1")], ["warning"])


class Case2UnlocatedAttribution(unittest.TestCase):
    def test_old_ears_net_claim_is_flagged(self):
        found = findings(OLD_EARS_NET, "C4")
        self.assertEqual(len(found), 1, found)
        self.assertIn("EARS-Net", found[0].message)

    def test_corrected_ears_net_claim_passes(self):
        self.assertEqual(findings(CORRECTED_EARS_NET, "C4"), [])

    def test_locator_on_the_next_line_counts(self):
        text = "EARS-Net keeps the first blood isolate per patient\n(ECDC protocol 2025, p. 22).\n"
        self.assertEqual(findings(text, "C4"), [])

    def test_each_clause_needs_its_own_locator(self):
        # 07-dedoublonnage.md, 07.2 note: the GLASS claim rides on the ECDC locator.
        text = (
            "EARS-Net keeps the first blood or CSF isolate per patient and pathogen in the "
            "calendar year (ECDC reporting protocol 2025, p. 22 and pp. 24-25); WHO GLASS "
            "keeps the first isolate per patient, specimen type and surveillance period.\n"
        )
        found = findings(text, "C4")
        self.assertEqual(len(found), 1, found)
        self.assertIn("GLASS", found[0].message)

    def test_reference_lists_and_table_headers_make_no_claim(self):
        text = (
            "## 6. References & Primary Sources\n\n"
            "2. **ECDC HAI-Net & BSI Surveillance Protocol**: not consulted.\n\n"
            "## Results\n\n| Surveillance Model | Window Shape / Rule | Δ vs. Annual (SPARES) |\n"
            "|---|---|---|\n| Annual | calendar | 0 |\n"
        )
        self.assertEqual(findings(text, "C4"), [])

    def test_opt_out_marker(self):
        text = OLD_EARS_NET.rstrip() + " <!-- citecheck: ok, historical wording -->\n"
        self.assertEqual(findings(text, "C4"), [])


@unittest.skipUnless(cc.pdftotext_path(), "pdftotext not installed")
class QuotesAgainstPdf(unittest.TestCase):
    QUOTE = (
        "> Un doublon est une souche isolée chez un malade pour lequel une souche de la\n"
        "> même espèce et de même antibiotype a déjà été prise en compte durant la\n"
        "> période de l'enquête pour un même type de prélèvement à visée diagnostique.\n"
    )

    def test_quote_under_source_heading_passes(self):
        self.assertEqual(findings("## What SPARES says\n\n" + self.QUOTE, "C3"), [])

    def test_altered_quote_is_flagged(self):
        text = "## What SPARES says\n\n" + self.QUOTE.replace("même espèce", "même famille")
        self.assertEqual(len(findings(text, "C3")), 1)

    def test_cited_page_is_checked(self):
        self.assertEqual(findings("SPARES p. 10:\n\n" + self.QUOTE, "C3"), [])
        found = findings("SPARES p. 20:\n\n" + self.QUOTE, "C3")
        self.assertEqual(len(found), 1, found)
        self.assertIn("p. 10", found[0].message)

    def test_off_by_one_page_is_flagged(self):
        self.assertEqual(len(findings("SPARES p. 11:\n\n" + self.QUOTE, "C3")), 1)
        self.assertEqual(findings("SPARES pp. 9-10:\n\n" + self.QUOTE, "C3"), [])

    def test_translated_quote_is_flagged(self):
        text = (
            "## What SPARES says\n\n> A duplicate is an isolate from a patient for whom "
            "an isolate of the same species and antibiotype was already counted.\n"
        )
        self.assertEqual(len(findings(text, "C3")), 1)

    def test_page_inside_the_quote(self):
        heading = "## What SPARES says\n\n"
        self.assertEqual(findings(heading + self.QUOTE.rstrip() + " (page 10)\n", "C3"), [])
        found = findings(heading + self.QUOTE.rstrip() + " (page 20)\n", "C3")
        self.assertEqual(len(found), 1, found)
        self.assertIn("p. 10", found[0].message)

    def test_quote_line_opening_with_a_parenthesis(self):
        text = (
            "## What SPARES says\n\n> Deux antibiotypes sont considérés comme différents s'il "
            "existe, entre les\n> souches comparées et pour au moins une molécule, une "
            "différence majeure\n> (S <-> R ou SFP <-> R) de catégories cliniques.\n"
        )
        self.assertEqual(findings(text, "C3"), [])

    def test_elisions_and_insertions(self):
        text = (
            "## What SPARES says\n\n> Une absence de résultat [case vide] [...] ne fait pas "
            "partie des caractères\n> discriminants pour le dédoublonnage.\n"
        )
        self.assertEqual(findings(text, "C3"), [])


class OnlyAddedLines(unittest.TestCase):
    def test_diff_parsing(self):
        diff = (
            "diff --git a/docs/a b.md b/docs/a b.md\n--- a/docs/a b.md\n+++ b/docs/a b.md\n"
            "@@ -3,0 +4,2 @@ ctx\n+x\n+y\n@@ -10 +12 @@\n-z\n+w\n"
        )
        self.assertEqual(cc.added_lines(diff), {"docs/a b.md": {4, 5, 12}})

    def test_untouched_claim_is_not_checked(self):
        text = "Intro.\n\n" + OLD_EARS_NET
        found = cc.check_document("docs/x.md", text, {1}, CONFIG, NET, REPO)
        self.assertEqual([f for f in found if f.check == "C4"], [])


if __name__ == "__main__":
    unittest.main()
