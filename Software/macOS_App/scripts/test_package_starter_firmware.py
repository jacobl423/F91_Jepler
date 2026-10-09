import hashlib
import json
from pathlib import Path
import tempfile
import unittest
from package_starter_firmware import package


class StarterFirmwareTests(unittest.TestCase):
    def test_relocation_and_corruption(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            source = root / 'source'
            (source / 'zephyr').mkdir(parents=True)
            manifest = {'schemaVersion': 1, 'sourceRevision': 'test-revision',
                        'elfPath': 'zephyr/zephyr.elf', 'configPath': 'zephyr/.config'}
            for name, key in [('app.signed.bin', 'imageSHA256'), ('mcuboot.elf', 'mcubootSHA256'),
                              ('zephyr/zephyr.elf', 'elfSHA256'), ('zephyr/.config', 'configSHA256')]:
                data = name.encode()
                (source / name).write_bytes(data)
                manifest[key] = hashlib.sha256(data).hexdigest()
            (source / 'firmware-manifest.json').write_text(json.dumps(manifest))
            package(source, root / 'first')
            package(root / 'first', root / 'relocated')
            relocated = json.loads((root / 'relocated/firmware-manifest.json').read_text())
            self.assertEqual(relocated['sourceRevision'], 'test-revision')
            for name in ['app.signed.bin', 'mcuboot.elf', 'zephyr.elf', 'firmware.config']:
                with self.subTest(name=name):
                    path = root / 'first' / name
                    original = path.read_bytes()
                    path.write_bytes(b'corrupt')
                    with self.assertRaises(ValueError):
                        package(root / 'first', root / 'rejected')
                    self.assertFalse((root / 'rejected').exists())
                    path.write_bytes(original)


if __name__ == '__main__':
    unittest.main()
