# Expense Tracker

A simple personal expense tracker that syncs straight to a Google Sheet.

## What's in this project

- `lib/` — the app itself (Flutter/Dart)
- `apps_script/Code.gs` — reference copy of the backend script (the real one lives inside your Google Sheet)
- `.github/workflows/build.yml` — automatically builds an installable APK every time you push code

## One-time setup

1. **Deploy the backend first.** Open your Google Sheet → Extensions → Apps Script → paste in `apps_script/Code.gs` → set your own `SECRET` → Deploy as a Web App → copy the URL.
2. **Connect the app to it.** Open `lib/services/sync_service.dart` and replace:
   - `scriptUrl` with the Web App URL from step 1
   - `secret` with the same SECRET you set in step 1
3. **Push this whole folder to a new GitHub repository.**
4. Go to the **Actions** tab on GitHub → you'll see "Build APK" running automatically → once it finishes (green checkmark), click into it → download the `expense-tracker-apk` file from the bottom of the page.
5. Unzip it, transfer the `.apk` to your phone, and install it (you may need to allow "install unknown apps" once).

## Making changes later

Every time you push new code to GitHub, a fresh APK is built automatically — no local setup needed.
