# Project Tracker: steps to go live and use it on your phone

Work through these in order. Each step says where to click.

## Part 1: Set up the database (one time, in Supabase)

1. Sign in at supabase.com and open your tracker project.
2. Click **SQL Editor**, then **New query**.
3. Open each file below from the `supabase` folder, paste it in, and click **Run**. Run them in this order and only once each:
   1. `004_line_fields.sql`
   2. `005_schedule.sql`
   3. `006_payment_notes.sql`
   4. `007_contract.sql`
   5. `008_draws.sql`
   6. `009_photos.sql`
   7. `010_photo_lines.sql`
   8. `011_vendor_confirm.sql`
4. If a file shows an error, stop and send me the message. Do not run the next file.
5. Re-running a file is safe, but do not skip one.

## Part 2: Put the new version live (Netlify)

Run step 011 in Part 1 before merging. Without it, the Request Payment Confirmation button fails.

1. Open the repository on GitHub: `github.com/snsquareinc/projectm`.
2. Click **Pull requests**, then **New pull request**.
3. Set **base** to `main` and **compare** to `phase1-database`. Click **Create pull request**, then **Merge pull request**.
4. Netlify rebuilds the site automatically. Wait about one minute.
5. Open `https://snsquareinc.com/tracker/` on your computer and sign in. Check that the Projects list loads.

## Part 3: Add the tracker to your phone's home screen

**iPhone (Safari only):**
1. Open `https://snsquareinc.com/tracker/` in **Safari**. Other iPhone browsers cannot add it.
2. Tap the **Share** button (square with an arrow).
3. Scroll down and tap **Add to Home Screen**, then **Add**.
4. Open the **SN Tracker** icon from your home screen. It opens full screen and asks you to sign in once.

**Android (Chrome):**
1. Open `https://snsquareinc.com/tracker/` in **Chrome**.
2. Tap the **⋮** menu, then **Install app** (or **Add to Home screen**).
3. Tap **Install**. Open **SN Tracker** from your app drawer or home screen.

## Part 4: Test it with a real project (about 15 minutes)

Do these on your phone, then check the numbers on a computer.

1. **Project:** open a project, or create one with **New Project**. Enter the name, address, lender and loan amount.
2. **Budget:** on the Budget screen, add one line with a division, sub-task, quantity and rate. Check the budget total.
3. **Transaction:** open **Transactions**, tap **+ Add Transaction**, pick the line, enter an amount, and attach a photo of a receipt. Save.
4. **Draw:** open **Draws**, tap **+ New Draw**, enter a built % for a line, and check the **Request** amount. Tap **Download draw report (PDF)** and save it.
5. **Photo:** open **Photos**, choose a line under **New uploads go to**, tap **+ Add Photos**, and take or choose a picture. Check that it appears under that line.
6. **Reports:** open **Reports** and check that paid, owed, and payments by contractor match the transaction you entered.

If any number is wrong, write down the screen, the step and what you expected, and send it to me.

## Part 5: Before you give it to anyone else (not needed for your own use)

Right now any signed-in user can see all projects. That is fine for you alone. Before sharing it with other companies or selling it, we need:

1. **Separate accounts:** each company sees only its own projects (a database rule per company).
2. **Sign-up and billing:** how new companies join and pay.
3. **Backups and support:** a tested restore process and a support contact.
4. **Terms and privacy policy:** written by a lawyer for your situation.

Tell me when you want to start on these and I will plan them with you.
