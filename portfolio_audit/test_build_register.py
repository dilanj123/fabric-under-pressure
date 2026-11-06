import unittest

from portfolio_audit.build_register import non_generated_checkout_status


class CheckoutStatusTests(unittest.TestCase):
    def test_generated_worktree_changes_are_ignored_for_repeat_runs(self):
        lines = [
            " M portfolio_audit/generated/register.csv",
            "?? portfolio_audit/generated/new.csv",
        ]
        self.assertEqual(non_generated_checkout_status(lines), [])

    def test_staged_generated_changes_still_require_explicit_override(self):
        lines = [
            "M  portfolio_audit/generated/register.csv",
            "A  portfolio_audit/generated/new.csv",
            "AM portfolio_audit/generated/mixed.csv",
        ]
        self.assertEqual(non_generated_checkout_status(lines), lines)

    def test_all_non_generated_changes_are_reported(self):
        lines = [
            " M docs/PROJECT_STATE.md",
            "?? portfolio_audit/review.md",
            "R  old.md -> docs/history/old.md",
        ]
        self.assertEqual(non_generated_checkout_status(lines), lines)


if __name__ == "__main__":
    unittest.main()
