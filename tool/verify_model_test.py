import hashlib
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import verify_model


class VerifyModelTest(unittest.TestCase):
    def test_lfs_pointer_is_rejected_with_recovery_instruction(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'model.onnx'
            path.write_text('version https://git-lfs.github.com/spec/v1\n')
            with self.assertRaisesRegex(ValueError, 'git lfs pull'):
                verify_model.verify(path)

    def test_same_size_corruption_is_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'model.onnx'
            path.write_bytes(b'good')
            with patch.object(verify_model, 'MODEL_SIZE', 4), patch.object(
                    verify_model, 'MODEL_SHA256', hashlib.sha256(b'good').hexdigest()):
                verify_model.verify(path)
                path.write_bytes(b'evil')
                with self.assertRaisesRegex(ValueError, 'SHA-256 mismatch'):
                    verify_model.verify(path)


if __name__ == '__main__':
    unittest.main()
