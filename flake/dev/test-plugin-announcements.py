import importlib.util
import json
import pathlib
import unittest


SCRIPT = pathlib.Path(__file__).with_name("plugin-announcements.py")
SPEC = importlib.util.spec_from_file_location("plugin_announcements", SCRIPT)
plugin_announcements = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(plugin_announcements)


class PluginAnnouncementsTest(unittest.TestCase):
    def test_added_plugin_renders_messages(self):
        diff = {
            "added": {"plugins": ["foo"], "colorschemes": []},
            "removed": {"plugins": [], "colorschemes": []},
        }
        metadata = [
            {
                "name": "foo",
                "namespace": "plugins",
                "kind": "plugin",
                "displayName": "foo.nvim",
                "url": "https://github.com/example/foo.nvim",
                "description": "Example plugin",
            }
        ]
        pr = {
            "number": 123,
            "url": "https://github.com/nix-community/nixvim/pull/123",
            "author_name": "alice",
            "author_url": "https://github.com/alice",
        }

        result = plugin_announcements.build_announcements(diff, metadata, pr)

        self.assertFalse(result["blocked"])
        self.assertIsNone(result["comment_markdown"])
        self.assertEqual(result["removed"], [])
        self.assertEqual(result["added"][0]["displayName"], "foo.nvim")
        self.assertIn("NEW PLUGIN", result["added"][0]["markdown"])
        self.assertIn("plugins.foo", result["summary_markdown"])
        self.assertIn("PR #123", result["summary_markdown"])

    def test_added_colorscheme_uses_docs_namespace(self):
        diff = {
            "added": {"plugins": [], "colorschemes": ["night"]},
            "removed": {"plugins": [], "colorschemes": []},
        }

        result = plugin_announcements.build_announcements(diff, [], None)

        self.assertFalse(result["blocked"])
        self.assertEqual(result["added"][0]["kind"], "colorscheme")
        self.assertIn(
            "https://nix-community.github.io/nixvim/colorschemes/night/index.html",
            result["added"][0]["plain"],
        )

    def test_removed_plugins_block_automatic_announcements(self):
        diff = {
            "added": {"plugins": ["foo"], "colorschemes": []},
            "removed": {"plugins": ["bar"], "colorschemes": []},
        }

        result = plugin_announcements.build_announcements(diff, [], None)

        self.assertTrue(result["blocked"])
        self.assertIn("Automatic announcements were not prepared", result["summary_markdown"])
        self.assertIn("plugins.bar", result["comment_markdown"])

    def test_empty_diff_reports_no_announcements(self):
        diff = {
            "added": {"plugins": [], "colorschemes": []},
            "removed": {"plugins": [], "colorschemes": []},
        }

        result = plugin_announcements.build_announcements(diff, [], None)

        self.assertFalse(result["blocked"])
        self.assertEqual(result["added"], [])
        self.assertIn("No plugin or colorscheme", result["summary_markdown"])

    def test_cli_json_is_serializable_shape(self):
        diff = {
            "added": {"plugins": ["foo"], "colorschemes": []},
            "removed": {"plugins": [], "colorschemes": []},
        }
        result = plugin_announcements.build_announcements(diff, [], None)

        encoded = json.dumps(result)
        decoded = json.loads(encoded)

        self.assertEqual(decoded["added"][0]["name"], "foo")


if __name__ == "__main__":
    unittest.main()
