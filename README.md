# विवाह सेतु

Matrimonial portal for Bhumihaar Brahman families in Muzaffarpur. Managed by **Acharya Santosh Kumar Munmun**. Profiles are stored in **Supabase** (free cloud database) so they show on **every device** — laptop, mobile, and your Netlify link.

## What was fixed

The old version saved profiles in **browser localStorage**. That only worked on the same computer/browser. Now all data lives in the cloud.

## Setup (one time, ~10 minutes)

### 1. Create free Supabase database

1. Go to [supabase.com](https://supabase.com) and sign up (free).
2. Click **New project** → pick a name (e.g. `vivah-setu`) → set a database password → **Create**.
3. Wait ~2 minutes for the project to be ready.

### 2. Create tables

1. In Supabase, open **SQL Editor** (left sidebar).
2. Click **New query**.
3. Open `supabase-setup.sql` from this folder, copy all text, paste into the editor.
4. Click **Run**. You should see “Success”.
5. Run **`fix-permissions.sql`** the same way (if you get permission errors).
6. Run **`security-hardening.sql`** the same way — **required** for phone privacy, validation, and secure admin.
7. (Optional) Run **`security-hardening-v2.sql`** for bcrypt passwords and login lockout.
8. If admin login fails with a database error, run **`fix-admin-login.sql`** once in the SQL Editor.
9. Run **`update-contact.sql`** to set admin WhatsApp to **83403 63036** (included in new installs via `supabase-setup.sql`).

### 3. Add API keys to the website

1. In Supabase, go to **Settings** → **API**.
2. Copy **Project URL** and **anon public** key.
3. Open `config.js` in this folder and replace:
   - `YOUR_SUPABASE_URL` → your Project URL
   - `YOUR_SUPABASE_ANON_KEY` → your anon key
4. Save the file.

### 4. Deploy on Netlify

1. Go to [netlify.com](https://netlify.com) and sign up (free).
2. Drag and drop the **MatrimonialWebsite** folder onto Netlify, **or** connect a GitHub repo.
3. Netlify will give you a link like `https://something.netlify.app` — share this on mobile; profiles will load from the cloud.

**Redeploy:** After changing `config.js`, upload/deploy again so Netlify has the new keys.

## Admin login

- **Username:** `admin`
- **Password:** `admin123` (change in Admin → Settings after first login)
- **Admin contact:** WhatsApp **83403 63036** (Acharya Santosh Kumar Munmun)

## Files

| File | Purpose |
|------|---------|
| `index.html` | Main website |
| `config.js` | Supabase URL and API key |
| `supabase-setup.sql` | Run once in Supabase |
| `update-contact.sql` | Set admin WhatsApp number |
| `netlify.toml` | Netlify deploy settings |

## Local test

Open `index.html` in a browser (after step 3). You should see 5 sample profiles.

**Note:** Open via Netlify or a local server — not `file://` — so Supabase API calls work on both desktop and mobile.
