"""Exercise matugen-ctl's command, status and passthrough contract."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


MATUGEN_ROOT = Path(__file__).resolve().parents[1]
CTL = MATUGEN_ROOT / "matugen-ctl"


class MatugenCtlTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="matugen ctl ")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        # Two axes share one store root: theme/palette and theme/feel.
        self.theme_store = self.root / "theme" / "palette"
        self.feel_store = self.root / "theme" / "feel"
        self.env = {
            **os.environ,
            "THEME_ROOT": str(self.theme_store),
            "FEEL_ROOT": str(self.feel_store),
        }

    def call(self, *args, **overrides):
        return subprocess.run(
            [str(CTL), *args], capture_output=True, text=True,
            env={**self.env, **overrides}, timeout=30, cwd="/",
        )

    def test_help_prints_usage(self):
        result = self.call("--help")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Usage: matugen-ctl", result.stdout)

    def test_default_command_is_help(self):
        result = self.call()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Usage: matugen-ctl", result.stdout)

    def test_unknown_command_fails_loudly(self):
        result = self.call("apply")
        self.assertEqual(result.returncode, 2)
        self.assertIn("unknown command", result.stderr)

    def test_copy_without_scripts_fails_loudly(self):
        lonely = self.root / "copied"
        lonely.mkdir()
        shutil.copy2(CTL, lonely / "matugen-ctl")
        result = subprocess.run(
            [str(lonely / "matugen-ctl"), "list"], capture_output=True,
            text=True, env=self.env, timeout=10, cwd="/",
        )
        self.assertEqual(result.returncode, 2)
        self.assertIn("script/palette.sh", result.stderr)

    def test_symlinked_entry_point_finds_its_scripts(self):
        entry = self.root / "bin" / "matugen-ctl"
        entry.parent.mkdir()
        entry.symlink_to(CTL)
        result = subprocess.run(
            [str(entry), "list"], capture_output=True, text=True,
            env=self.env, timeout=30, cwd="/",
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("wallpaper-based", result.stdout)

    def test_list_shows_palettes_profiles_and_consumers(self):
        result = self.call("list")
        self.assertEqual(result.returncode, 0, result.stderr)
        for expected in ("wallpaper-based", "kanagawa-dragon-lotus", "dark",
                         "light", "default", "kitty", "consumers:"):
            with self.subTest(expected=expected):
                self.assertIn(expected, result.stdout)

    def test_palette_requires_a_source(self):
        result = self.call("palette")
        self.assertEqual(result.returncode, 2)
        self.assertIn("needs a wallpaper", result.stderr)

    def test_feel_requires_a_profile(self):
        result = self.call("feel")
        self.assertEqual(result.returncode, 2)
        self.assertIn("needs a profile", result.stderr)

    def test_palette_dry_run_passes_the_store_prefix_and_writes_nothing(self):
        image = self.root / "wall.png"
        image.write_bytes(b"")
        result = self.call("palette", "--dry-run", str(image))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("wallpaper-based", result.stdout)
        self.assertIn(f"{self.theme_store}/generated/matugen", result.stdout)
        self.assertFalse(self.theme_store.exists())

    def test_palette_dry_run_uses_the_blueprint_theme(self):
        blueprint = MATUGEN_ROOT / "core/palette/kanagawa-dragon-lotus/blueprint/light.json"
        result = self.call("palette", "--dry-run", str(blueprint))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("kanagawa-dragon-lotus", result.stdout)
        self.assertIn(f"-p {self.theme_store}/generated/matugen", result.stdout)
        self.assertFalse(self.theme_store.exists())

    def test_palette_dry_run_forwards_a_scheme_for_images(self):
        image = self.root / "wall.png"
        image.write_bytes(b"")
        result = self.call("palette", "--dry-run", str(image),
                           "--scheme", "scheme-vibrant")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("--type scheme-vibrant", result.stdout)

    def test_palette_scheme_accepts_the_equals_form(self):
        image = self.root / "wall.png"
        image.write_bytes(b"")
        result = self.call("palette", "--dry-run", str(image),
                           "--scheme=scheme-content")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("--type scheme-content", result.stdout)

    def test_palette_without_scheme_keeps_the_matugen_default(self):
        image = self.root / "wall.png"
        image.write_bytes(b"")
        result = self.call("palette", "--dry-run", str(image))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("--type", result.stdout)

    def test_palette_scheme_needs_a_value(self):
        result = self.call("palette", "--scheme")
        self.assertEqual(result.returncode, 2)
        self.assertIn("--scheme butuh nama", result.stderr)

    def test_palette_scheme_needs_an_image_source(self):
        result = self.call("palette", "--scheme", "scheme-vibrant")
        self.assertEqual(result.returncode, 2)
        self.assertIn("--scheme butuh sumber gambar", result.stderr)

    def test_palette_scheme_rejects_blueprints(self):
        blueprint = MATUGEN_ROOT / "core/palette/kanagawa-dragon-lotus/blueprint/light.json"
        result = self.call("palette", str(blueprint),
                           "--scheme", "scheme-vibrant")
        self.assertEqual(result.returncode, 2)
        self.assertIn("hanya untuk sumber gambar", result.stderr)

    def test_missing_source_fails_like_the_renderer(self):
        result = self.call("palette", str(self.root / "absent.png"))
        self.assertEqual(result.returncode, 1)
        self.assertIn("sumber tidak ada", result.stderr)
        self.assertFalse(self.theme_store.exists())

    def test_reload_dry_run_stays_dry(self):
        result = self.call("reload", "--dry-run", "scss")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("eww", result.stdout)
        self.assertFalse(self.theme_store.exists())

    def test_reload_rejects_unknown_consumer(self):
        result = self.call("reload", "bogus")
        self.assertEqual(result.returncode, 2)
        self.assertIn("consumer tidak dikenal", result.stderr)

    def test_feel_dry_run_renders_the_hypr_part_only(self):
        result = self.call("feel", "default", "--wm", "hypr", "--dry-run")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("hypr.json", result.stdout)
        self.assertIn("apps.json", result.stdout)
        self.assertNotIn("niri.json", result.stdout)
        self.assertIn("wm: hypr", result.stderr)
        self.assertFalse(self.feel_store.exists())

    def test_feel_niri_renders_the_niri_part_only(self):
        result = self.call("feel", "default", "--wm", "niri", "--dry-run")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("apps.json", result.stdout)
        self.assertIn("niri.json", result.stdout)
        self.assertNotIn("hypr.json", result.stdout)
        self.assertIn("wm: niri", result.stderr)

    def test_feel_rejects_unknown_profile(self):
        result = self.call("feel", "absent", "--dry-run")
        self.assertEqual(result.returncode, 2)
        self.assertIn("feel profile tidak ada", result.stderr)

    def test_feel_rejects_unknown_wm(self):
        result = self.call("feel", "default", "--wm", "sway", "--dry-run")
        self.assertEqual(result.returncode, 2)
        self.assertIn("wm tidak dikenal", result.stderr)

    def test_status_reports_none_without_stores(self):
        result = self.call("status")
        self.assertEqual(result.returncode, 1)
        self.assertIn("palette  none", result.stdout)
        self.assertIn("feel     none", result.stdout)

    def test_status_reads_the_active_links(self):
        palette_dir = self.theme_store / "generated" / "matugen" / "kanagawa-dragon-lotus"
        feel_dir = self.feel_store / "generated" / "default"
        palette_dir.mkdir(parents=True)
        feel_dir.mkdir(parents=True)
        (self.theme_store / "current").symlink_to(palette_dir)
        (self.feel_store / "current").symlink_to(feel_dir)

        result = self.call("status")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(f"palette  matugen/kanagawa-dragon-lotus  ({palette_dir})", result.stdout)
        self.assertIn(f"feel     default  ({feel_dir})", result.stdout)


if __name__ == "__main__":
    unittest.main()
