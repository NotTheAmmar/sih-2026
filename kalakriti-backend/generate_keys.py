#!/usr/bin/env python3
"""
generate_keys.py — One-shot Ed25519 keypair generator for ONDC BPP.

Run once before starting the server:
    python generate_keys.py

Copy the printed values into your .env file.
The public key must also be submitted to the ONDC registry for your
subscriber ID (required for production; not needed for Workbench mock testing).
"""
import base64
from nacl.signing import SigningKey


def main() -> None:
    key = SigningKey.generate()
    private_b64 = base64.b64encode(key.encode()).decode("utf-8")
    public_b64 = base64.b64encode(key.verify_key.encode()).decode("utf-8")

    print("─" * 50)
    print("  KalaKriti BPP — ONDC Ed25519 Keypair")
    print("─" * 50)
    print(f"BPP_SIGNING_PRIVATE_KEY={private_b64}")
    print(f"BPP_SIGNING_PUBLIC_KEY={public_b64}")
    print("─" * 50)
    print("Paste both lines into your .env file.")
    print(
        "The PUBLIC key must be registered in the ONDC subscriber registry\n"
        "for production use. For Workbench mock testing it can remain local."
    )


if __name__ == "__main__":
    main()
