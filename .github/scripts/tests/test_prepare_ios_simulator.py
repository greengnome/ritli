"""Exercise simulator discovery and recovery without booting a simulator."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / "prepare-ios-simulator.sh"
MOCK = r'''#!/usr/bin/env python3
import json
import os
from pathlib import Path
import sys

name = Path(sys.argv[0]).name
root = Path(os.environ["MOCK_ROOT"])
with (root / "calls").open("a") as log:
    log.write(name + " " + " ".join(sys.argv[1:]) + "\n")
mode = os.environ["MOCK_MODE"]
if name == "xcrun":
    if sys.argv[1:4] == ["simctl", "list", "runtimes"]:
        installed = not mode.startswith("download") or (
            mode == "download" and (root / "downloaded").exists()
        )
        runtimes = [{"identifier": "com.apple.CoreSimulator.SimRuntime.iOS-26-5", "version": "26.5", "isAvailable": True}] if installed else []
        print(json.dumps({"runtimes": runtimes}))
    elif sys.argv[1:3] == ["simctl", "create"]:
        print("TEST-UDID")
elif name == "killall":
    (root / "recovered").touch()
elif name == "xcodebuild":
    if "-downloadPlatform" in sys.argv:
        (root / "downloaded").touch()
        sys.exit(0)
    if mode == "command_failure":
        sys.exit(1)
    print('Destinations compatible with the "Ritli" scheme:' if mode == "xcode27" else 'Available destinations for the "Ritli" scheme:')
    print('{ platform:iOS Simulator, id:generic, name:Any iOS Simulator Device }')
    if mode == "ineligible":
        print('Destinations incompatible with the "Ritli" scheme:')
    if mode not in ("never", "recover") or (mode == "recover" and (root / "recovered").exists()):
        print('{ platform:iOS Simulator, arch:arm64, id:TEST-UDID, OS:26.5, name:Ritli CI }')
'''


class SimulatorPreparationTests(unittest.TestCase):
    def run_preparation(self, mode, expects_simulator=True):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            mock = root / "mock"
            mock.write_text(MOCK)
            mock.chmod(0o755)
            for command in ("xcrun", "xcodebuild", "killall", "sleep"):
                (root / command).symlink_to(mock)
            env = dict(os.environ, PATH=f"{root}:{os.environ['PATH']}",
                       MOCK_ROOT=str(root), MOCK_MODE=mode,
                       GITHUB_ENV=str(root / "env"), IOS_RUNTIME_VERSION="26.5")
            result = subprocess.run(["bash", str(SCRIPT)], env=env,
                                    capture_output=True, text=True, timeout=20)
            calls = (root / "calls").read_text()
            if expects_simulator:
                self.assertEqual((root / "env").read_text(), "IOS_SIMULATOR_ID=TEST-UDID\n")
            else:
                self.assertFalse((root / "env").exists())
            return result, calls

    def test_available_destination_needs_no_restart(self):
        for mode in ("normal", "xcode27"):
            with self.subTest(mode=mode):
                result, calls = self.run_preparation(mode)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertNotIn("killall", calls)

    def test_recovers_once_after_discovery_exhaustion(self):
        result, calls = self.run_preparation("recover")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(calls.count("killall "), 1)
        self.assertEqual(calls.count("xcodebuild "), 7)
        self.assertEqual(calls.count("xcrun simctl bootstatus"), 2)
        self.assertLess(calls.index("xcrun simctl shutdown"), calls.index("killall "))

    def test_downloads_a_missing_runtime_once(self):
        result, calls = self.run_preparation("download")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("Installing the missing iOS 26.5 simulator runtime.", result.stdout)
        self.assertEqual(calls.count("xcodebuild -downloadPlatform iOS -buildVersion 26.5"), 1)
        self.assertLess(
            calls.index("xcodebuild -downloadPlatform"),
            calls.index("xcrun simctl create"),
        )

    def test_runtime_still_missing_after_download_fails(self):
        result, calls = self.run_preparation("download_missing", expects_simulator=False)
        self.assertEqual(result.returncode, 1)
        self.assertIn("not available after runtime installation", result.stdout)
        self.assertNotIn("simctl create", calls)

    def test_persistent_failure_is_not_hidden(self):
        for mode in ("never", "ineligible", "command_failure"):
            with self.subTest(mode=mode):
                result, calls = self.run_preparation(mode)
                self.assertEqual(result.returncode, 1)
                self.assertIn("after recovery", result.stdout)
                self.assertEqual(calls.count("killall "), 1)
                self.assertEqual(calls.count("xcodebuild "), 12)


if __name__ == "__main__":
    unittest.main()
