# SN Square Project Tracker

A mobile-first web app for projects: library of divisions and sub-tasks, budget roll-up, payments with
receipts, contractors with insurance and W-9 tracking.
It runs on Netlify (hosting) and Supabase (database, login, and file storage). You own both accounts.

## Files

- `tracker/index.html`: the app. Served at `/tracker/` on your site.
- `config.js`: your Supabase URL and public key. Served at `/config.js`.
- `supabase/001_phase1.sql`: tables, access rules, library seed (21 divisions, 212 sub-tasks).
- `supabase/002_project_vendors.sql`: contractor assignments to projects.
- `supabase/003_qty_rate.sql`: Sq.Ft. / Qty and Rate on budget lines (budget = qty × rate).

## One-time setup

### 1. Create the Supabase project
1. Go to supabase.com, sign in, and create a new project. Choose a region near Massachusetts and save the database password.
2. Open **SQL Editor**, paste `supabase/001_phase1.sql`, and click **Run**.
3. In a new query, paste `supabase/002_project_vendors.sql` and click **Run**.
4. In a new query, paste `supabase/003_qty_rate.sql` and click **Run**.

### 2. Lock down sign-ups and add yourself
1. In Supabase, go to **Authentication > Sign In / Providers > Email**, keep Email enabled, and turn off "Allow new users to sign up".
2. Go to **Authentication > Users > Add user**, enter your email and a password, and create the user.

### 3. Connect the app to Supabase
1. In Supabase, go to **Project Settings > API**.
2. Copy the **Project URL** and the **anon public** key into `config.js`.

### 5. Deploy
Push the repository. Netlify redeploys the site. Open `https://snsquareinc.com/tracker/` and sign in.

## Using it

- **Projects**: create a project, then open it. Project details can be edited any time.
- **Budget**: add sub-tasks from the Library, or a custom line. Division totals roll up from their lines.
  Record a revision on a line with a reason. Lines with payments cannot be deleted.
- **Payments**: every payment needs a budget line. If the description does not match an existing line,
  pick one or choose "+ New line" to add it. Receipts and invoices attach to each payment.
- **Contractors**: assign a contractor to a project. Each one needs a certificate of insurance. The reminder
  shows every day until the certificate is added or dismissed with a reason from the list.
- **Contractors (main tab)**: all contractors, W-9 status, and 1099 totals by year. Tap one for its payment ledger.
- **Library**: divisions and sub-tasks shared by every project.

## Notes

- Only signed-in users can read or write data. The public key in `config.js` is safe to publish;
  the access rules in the SQL files are what protect the data.
- Files are stored privately. Opening one creates a link that expires after 10 minutes.
- Not yet built: draws, schedule and look-ahead, the bank draw report, vendor confirmation pages,
  statements by email, the Reports tab, and the Files tab. These are the next phases.
- Backups: keep your own copy of important files. Check current Supabase and Netlify limits and pricing before relying on them.
