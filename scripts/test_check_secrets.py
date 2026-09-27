import base64
import json
import unittest

from check_secrets import has_private_material


class SecretScanTests(unittest.TestCase):
    def test_private_key_secret_key_and_privileged_jwt(self):
        self.assertTrue(has_private_material(b"-----BEGIN " + b"PRIVATE KEY-----"))
        self.assertTrue(has_private_material(b"sb_" + b"secret_" + b"a" * 24))
        payload = base64.urlsafe_b64encode(json.dumps({"role": "service_role"}).encode()).rstrip(b"=")
        self.assertTrue(has_private_material(b"eyJhbGciOiJIUzI1NiJ9." + payload + b".signature"))

    def test_public_jwt_and_placeholders_are_allowed(self):
        payload = base64.urlsafe_b64encode(json.dumps({"role": "anon"}).encode()).rstrip(b"=")
        self.assertFalse(has_private_material(b"eyJhbGciOiJIUzI1NiJ9." + payload + b".signature"))
        self.assertFalse(has_private_material(b"SUPABASE_SERVICE_ROLE_KEY=\nR2_SECRET_ACCESS_KEY=\n"))


if __name__ == "__main__":
    unittest.main()
