import contextlib
import hashlib
import importlib.util
import io
import json
from pathlib import Path
import shutil
import tempfile
import unittest


spec = importlib.util.spec_from_file_location(
    "workflow", Path(__file__).resolve().parents[1] / "workflow.py"
)
workflow = importlib.util.module_from_spec(spec)
spec.loader.exec_module(workflow)


class SavedPlanSafetyTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        (self.root / "main.tf").write_text('provider "tailscale" {}\n')
        (self.root / "policy.hujson").write_text('{"ssh": []}\n')
        (self.root / ".terraform.lock.hcl").write_text("provider lock\n")
        bundle = self.root / ".terraform" / "reviewed-plans" / "review"
        bundle.mkdir(parents=True)
        self.plan = bundle / "plan.tfplan"
        self.original = b"original saved plan bytes"
        self.plan.write_bytes(self.original)
        self.review = {
            "root": str(self.root.resolve()),
            "source": workflow.source_fingerprint(self.root),
            "plan_sha256": hashlib.sha256(self.original).hexdigest(),
            "tailnet": "reviewed-tailnet",
        }
        (bundle / "review.json").write_text(json.dumps(self.review))

    def test_changed_plan_cannot_use_its_previous_review(self):
        self.plan.write_bytes(b"different operations")
        with self.assertRaises(ValueError):
            workflow.load_review(self.root, self.plan)

    def test_changed_policy_requires_a_new_plan(self):
        (self.root / "policy.hujson").write_text('{"ssh": [{"action": "accept"}]}\n')
        with self.assertRaises(ValueError):
            workflow.load_review(self.root, self.plan)

    def test_new_override_configuration_requires_a_new_plan(self):
        (self.root / "override.tf.json").write_text('{"provider": {}}\n')
        with self.assertRaises(ValueError):
            workflow.load_review(self.root, self.plan)

    def test_removed_provider_lock_invalidates_review(self):
        (self.root / ".terraform.lock.hcl").unlink()
        with self.assertRaises(ValueError):
            workflow.load_review(self.root, self.plan)

    def test_another_checkout_cannot_supply_the_plan(self):
        with tempfile.TemporaryDirectory() as other:
            with self.assertRaises(ValueError):
                workflow.load_review(Path(other), self.plan)

    def test_copying_an_artifact_to_another_checkout_does_not_transfer_approval(self):
        with tempfile.TemporaryDirectory() as other:
            copied_root = Path(other) / "checkout"
            shutil.copytree(self.root, copied_root)
            copied_plan = copied_root / self.plan.relative_to(self.root)
            with self.assertRaises(ValueError):
                workflow.load_review(copied_root, copied_plan)

    def test_missing_authoritative_state_requires_explicit_recovery(self):
        with self.assertRaises(ValueError):
            workflow.require_local_state(self.root)

    def test_original_artifact_mutation_cannot_change_review_snapshot(self):
        with workflow.review_snapshot(self.root, self.plan) as (snapshot, review):
            self.plan.write_bytes(b"unreviewed replacement")
            workflow.verify_review(self.root, snapshot, review)
            self.assertEqual(snapshot.read_bytes(), self.original)
            self.assertEqual(snapshot.stat().st_mode & 0o077, 0)
            self.assertEqual(snapshot.parent.stat().st_mode & 0o077, 0)
        self.assertFalse(snapshot.exists())

    def test_configuration_change_during_confirmation_is_rejected(self):
        with workflow.review_snapshot(self.root, self.plan) as (snapshot, review):
            (self.root / "main.tf").write_text(
                'provider "tailscale" { alias = "new" }\n'
            )
            with self.assertRaises(ValueError):
                workflow.verify_review(self.root, snapshot, review)

    def test_noninteractive_apply_is_refused_before_running_opentofu(self):
        with contextlib.redirect_stdout(io.StringIO()):
            with self.assertRaises(ValueError):
                workflow.apply_plan(self.root, self.plan)

    def test_deletion_and_replacement_plans_are_refused(self):
        for actions in (["delete"], ["delete", "create"], ["create", "delete"]):
            with self.subTest(actions=actions):
                document = {
                    "configuration": {
                        "provider_config": {
                            "tailscale": {
                                "expressions": {
                                    "tailnet": {"constant_value": "reviewed-tailnet"}
                                }
                            }
                        }
                    },
                    "resource_changes": [{"change": {"actions": actions}}],
                }
                with self.assertRaises(ValueError):
                    workflow.plan_tailnet(document)

    def test_unpinned_tailnet_cannot_be_authorized(self):
        with self.assertRaises(ValueError):
            workflow.plan_tailnet({"configuration": {"provider_config": {}}})


if __name__ == "__main__":
    unittest.main()
