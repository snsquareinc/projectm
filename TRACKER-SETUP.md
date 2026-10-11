# Construction Project Tracker

A web app for your project: budget by category, tasks with schedule and costs, and receipt uploads.
It runs on Netlify (hosting) and Supabase (database, login, and receipt storage). You own both accounts.

## Files

- `tracker/index.html`: the app. Served at `/tracker/` on your site.
- `config.js`: your Supabase URL and public key. Served at `/config.js`.
- `schema.sql`: database tables, access rules, and the receipts storage bucket.

## One-time setup

### 1. Create the Supabase project
1. Go to supabase.com, sign in, and create a new project. Choose a region near Massachusetts and save the database password.
2. Open **SQL Editor**, paste all of `schema.sql`, and click **Run**.

### 2. Lock down sign-ups and add yourself
1. In Supabase, go to **Authentication > Sign In / Providers > Email** and turn off "Allow new users to sign up". This keeps strangers out.
2. Go to **Authentication > Users > Add user**, enter your email and a password, and create the user.
   Add anyone else who should have access the same way.

### 3. Connect the app to Supabase
1. In Supabase, go to **Project Settings > API**.
2. Copy the **Project URL** and the **anon public** key into `config.js`.

### 4. Put the files on your Netlify site
Add the `tracker` folder and `config.js` to your site's repository, at the top level next to the site's
other files, then push. Netlify redeploys automatically.

If your site's publish folder is not the repository root, put `tracker/` and `config.js` inside that folder instead,
and change the `../config.js` line in `tracker/index.html` to match.

Open `https://snsquareinc.com/tracker/` (or your Netlify address plus `/tracker/`) and sign in.

## Using it

- **Quick add** (bottom button): name, category, status, costs, and date. Edit the task later for the rest.
- **Add task / Edit**: all fields. Receipts can be attached once the task is saved.
- **Categories**: add a category, then type its approved budget in the table.
- **Project details**: name, client, manager, and dates.
- Delete buttons ask you to press them twice.

## Notes

- Only signed-in users can read or write data. The public key in `config.js` is safe to publish;
  the access rules in `schema.sql` are what protect the data.
- Receipts are stored privately in Supabase. Opening one creates a link that expires after an hour.
- Backups: in Supabase, your data is kept by the provider, but keep your own copy too. The free tier has
  limits on storage and on paused projects; check current limits on supabase.com before relying on it.
- Netlify and Supabase pricing and limits change. Check their pricing pages when you set up.

## Changing the app later

The app is one HTML file. Edits can be made here, or by a developer working from this folder.
If you want changes made for you, share the repository or the file with me.
