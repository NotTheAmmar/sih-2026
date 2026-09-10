# `.env` Setup Guide — KalaKriti AI

> **Who needs this:** Everyone on the team who wants to run the app.  
> **Time required:** 5 minutes for mock mode, 15 minutes for live AI mode.

---

## Step 1: Create your `.env` file

The `.env` file is **never committed to git** (it's in `.gitignore`). You must create it yourself from the template:

```bash
# Run this in the project root
cp .env.example .env
```

Then open `.env` in any text editor and fill in the values for your use case.

---

## Step 2: Choose your mode

### Mode A — Mock Mode (demo/UI testing, no API keys needed)

This is the default. The app returns pre-built craft catalog data (Chanderi silk, Bishnupur terracotta, Bastar Dhokra) without any real AI processing.

```env
USE_MOCK_DATA=true
VOICE_PIPELINE=auto
```

That's it. Run the app and everything works offline.

---

### Mode B — Live AI Mode (Path 3: Groq + Gemini, recommended for jury demo)

This uses real AI: Groq Whisper transcribes the artisan's voice, and Gemini extracts the structured catalog.

**Time to set up: ~15 minutes**

#### 1. Get a Groq API key (free, no credit card)

1. Go to [console.groq.com](https://console.groq.com)
2. Sign up / log in with Google
3. Click **API Keys** → **Create API Key**
4. Copy the key (starts with `gsk_...`)

```env
GROQ_API_KEY=gsk_xxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**Free tier:** 14,400 audio transcription requests/day — more than enough for demos and testing.

---

#### 2. Get a Gemini API key (free, 1,500 requests/day)

1. Go to [aistudio.google.com](https://aistudio.google.com)
2. Click **Get API key** → **Create API key in new project**
3. Copy the key

```env
GEMINI_API_KEY=AIzaSyxxxxxxxxxxxxxxxxxxxxxxxx
GEMINI_MODEL=gemini-2.5-flash
```

> **Important:** Keep the model as `gemini-2.5-flash`. It supports structured JSON output mode which we rely on.

---

#### 3. Enable live mode

```env
USE_MOCK_DATA=false
VOICE_PIPELINE=auto    # auto = uses Groq since GROQ_API_KEY is set
```

#### Complete `.env` for Path 3 (minimum viable)

```env
USE_MOCK_DATA=false
VOICE_PIPELINE=auto

GROQ_API_KEY=gsk_your_actual_key_here
GEMINI_API_KEY=AIzaSy_your_actual_key_here
GEMINI_MODEL=gemini-2.5-flash

# Leave these as defaults for now
BHASHINI_API_KEY=your_bhashini_key_here
BHASHINI_ULCA_KEY=your_ulca_key_here
BHASHINI_API_URL=https://dhruva-api.bhashini.gov.in
BACKEND_URL=http://localhost:8000
API_BASE_URL=https://api.kalakriti.dev/v1
```

---

### Mode C — Bhashini Cloud Mode (Path 2, govt endpoints)

Use this when you have credentials from your college SPOC (SIH coordinator).

#### How to get Bhashini credentials

1. Register at [bhashini.gov.in/ulca](https://bhashini.gov.in/ulca)
2. Contact your SIH SPOC and ask for MeitY Bhashini API access
3. You'll receive:
   - `BHASHINI_API_KEY` (Authorization header)
   - `BHASHINI_ULCA_KEY` (pipeline access key)

```env
USE_MOCK_DATA=false
VOICE_PIPELINE=bhashini

BHASHINI_API_KEY=your_bhashini_key_here
BHASHINI_ULCA_KEY=your_ulca_key_here
BHASHINI_API_URL=https://dhruva-api.bhashini.gov.in
```

---

### Mode D — AI4Bharat Self-Hosted Backend (Path 1, national screening)

Use this when a GPU backend is running the full AI4Bharat stack.

1. Start the FastAPI backend on your GPU VM (see `voice-pipeline-architecture.md` §9)
2. Find the VM's local network IP: `hostname -I | awk '{print $1}'`

```env
USE_MOCK_DATA=false
VOICE_PIPELINE=ai4bharat

BACKEND_URL=http://192.168.x.x:8000    # replace with your VM's IP
```

> Make sure the phone and the VM are on the **same Wi-Fi network**.

---

## All `.env` Keys Reference

| Key | Required for | Description |
|---|---|---|
| `USE_MOCK_DATA` | All modes | `true` = offline demo, `false` = live AI |
| `VOICE_PIPELINE` | All modes | `auto` / `groq` / `bhashini` / `ai4bharat` |
| `GROQ_API_KEY` | Path 3 | Whisper-Large-v3 ASR key (console.groq.com) |
| `GEMINI_API_KEY` | Path 3 | Entity extraction key (aistudio.google.com) |
| `GEMINI_MODEL` | Path 3 | Default: `gemini-2.5-flash` |
| `BHASHINI_API_KEY` | Path 2 | Govt ASR+TTS key (via SPOC) |
| `BHASHINI_ULCA_KEY` | Path 2 | ULCA pipeline access key |
| `BHASHINI_API_URL` | Path 2 | Default: Dhruva endpoint |
| `BACKEND_URL` | Path 1 & 2 | FastAPI backend IP:port |
| `API_BASE_URL` | Phase 2 | Future KalaKriti cloud API |

---

## Troubleshooting

### "GROQ_API_KEY is not set in .env"
→ Make sure `USE_MOCK_DATA=false` in `.env` and that `GROQ_API_KEY` is set correctly.

### "Gemini extraction failed (400)"
→ The `GEMINI_MODEL` might be wrong. Make sure it's `gemini-2.5-flash` (not `gemini-1.5-pro` or similar).

### "Groq ASR failed (401)"
→ The Groq key is incorrect or expired. Regenerate it at [console.groq.com](https://console.groq.com).

### Audio transcription returns English even for Hindi input
→ Normal for some Hindi recordings. Gemini's extraction prompt handles mixed Hindi-English (Hinglish) — the final catalog card will still be in Hindi.

### The app crashes on startup with "Error loading .env"
→ Run `flutter clean && flutter pub get` and rebuild. The `.env` file must be in the project root (same folder as `pubspec.yaml`).

### "Backend failed (connection refused)" when using Path 1
→ The FastAPI backend isn't running. Either start it or switch to `VOICE_PIPELINE=groq` for immediate testing.

---

## Security Notes

- **Never commit `.env`** — it's already in `.gitignore`.
- The `.env` file is bundled into the APK as an asset. For production, move API calls to a backend proxy.
- The `GEMINI_API_KEY` visible in your `.env` is for the prototype demo only. For national screening, use a backend-only key.
- Share your actual keys only via a secure channel (e.g., WhatsApp DM to teammate, never in GitHub issues or commit messages).

---

## Quick Checklist Before Demo

```
[ ] .env exists in project root (not committed to git)
[ ] USE_MOCK_DATA=false
[ ] GROQ_API_KEY is set (starts with gsk_)
[ ] GEMINI_API_KEY is set (starts with AIzaSy)
[ ] GEMINI_MODEL=gemini-2.5-flash
[ ] Phone has microphone permission granted
[ ] Phone is connected to the internet
[ ] Tested with a real 10-second Hindi voice recording
```
