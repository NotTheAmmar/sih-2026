"""
crypto.py — ONDC network authentication helpers.

Implements the Beckn protocol authentication standard:
  - BLAKE2b-512 payload digest
  - Ed25519 signing → Authorization header generation
  - Ed25519 verification of inbound Authorization headers

References:
  ONDC Network Policy v1.x — Authentication & Non-Repudiation
  Beckn Protocol Core Spec 1.2.0 — Authorization Header format
"""
import base64
import hashlib
import time

from nacl.encoding import RawEncoder
from nacl.exceptions import BadSignatureError
from nacl.signing import SigningKey, VerifyKey


# ── Digest ────────────────────────────────────────────────────────────────────


def generate_blake2b_digest(payload_bytes: bytes) -> str:
    """
    Compute a BLAKE2b-512 digest of *payload_bytes* and return it
    as a standard base64-encoded string.

    This digest is embedded in the Beckn signing string so that
    verifiers can confirm the payload was not tampered with in transit.
    """
    hasher = hashlib.blake2b(payload_bytes, digest_size=64)
    return base64.b64encode(hasher.digest()).decode("utf-8")


# ── Signing ───────────────────────────────────────────────────────────────────


def create_ondc_auth_header(
    payload_bytes: bytes,
    subscriber_id: str,
    unique_key_id: str,
    private_key_b64: str,
    ttl_seconds: int = 300,
) -> str:
    """
    Generate a Beckn-compliant ``Authorization`` header value.

    The signing string follows the HTTP Signatures draft standard used by ONDC:

        (created): <unix_epoch>
        (expires): <unix_epoch + ttl>
        digest: BLAKE2b-512=<base64_digest>

    Args:
        payload_bytes:   Raw JSON body bytes to be sent in the request.
        subscriber_id:   BPP subscriber ID (e.g. "kalakriti.bpp.org").
        unique_key_id:   Key ID string (e.g. "key-1").
        private_key_b64: Base64-encoded 32-byte Ed25519 private key seed.
        ttl_seconds:     Validity window in seconds (default 5 minutes).

    Returns:
        A complete Authorization header value string starting with ``Signature``.
    """
    created = int(time.time())
    expires = created + ttl_seconds

    digest = generate_blake2b_digest(payload_bytes)
    signing_string = (
        f"(created): {created}\n"
        f"(expires): {expires}\n"
        f"digest: BLAKE2b-512={digest}"
    )

    seed = base64.b64decode(private_key_b64)
    signing_key = SigningKey(seed)
    # sign() returns signed message; .signature is the detached 64-byte signature
    signed = signing_key.sign(signing_string.encode("utf-8"), encoder=RawEncoder)
    signature_b64 = base64.b64encode(signed.signature).decode("utf-8")

    return (
        f'Signature keyId="{subscriber_id}|{unique_key_id}|ed25519",'
        f'algorithm="ed25519",created="{created}",expires="{expires}",'
        f'headers="(created) (expires) digest",signature="{signature_b64}"'
    )


# ── Verification ──────────────────────────────────────────────────────────────


def verify_ondc_auth_header(
    auth_header: str,
    payload_bytes: bytes,
    public_key_b64: str,
) -> bool:
    """
    Verify the Ed25519 signature on an inbound Beckn ``Authorization`` header.

    Args:
        auth_header:    The full ``Authorization`` header value from the request.
        payload_bytes:  The raw request body bytes to verify against.
        public_key_b64: Base64-encoded 32-byte Ed25519 public key of the sender.

    Returns:
        ``True`` if the signature is valid and the digest matches the payload.
        ``False`` on any failure (bad signature, missing fields, expired, etc.).

    Note:
        For ONDC Workbench / mock testing, inbound requests are not signed.
        This function is available but not enforced on inbound routes — flip the
        ``enforce_inbound_auth`` flag in ``beckn_routes.py`` to enable it for
        production use.
    """
    try:
        # Strip "Signature " prefix and parse key=value pairs
        header_body = auth_header.strip()
        if header_body.startswith("Signature "):
            header_body = header_body[len("Signature "):]

        parts: dict[str, str] = {}
        for item in header_body.split(","):
            if "=" not in item:
                continue
            k, v = item.split("=", 1)
            parts[k.strip()] = v.strip().strip('"')

        created = parts["created"]
        expires = parts["expires"]
        signature = base64.b64decode(parts["signature"])

        digest = generate_blake2b_digest(payload_bytes)
        reconstructed_string = (
            f"(created): {created}\n"
            f"(expires): {expires}\n"
            f"digest: BLAKE2b-512={digest}"
        )

        verify_key = VerifyKey(base64.b64decode(public_key_b64))
        # verify() raises BadSignatureError if invalid
        verify_key.verify(reconstructed_string.encode("utf-8"), signature)
        return True

    except (BadSignatureError, KeyError, ValueError, Exception):
        return False
