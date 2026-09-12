# Resource archive

A hand-picked collection of learning resources (articles, videos) for **math**, **cs**,
and **others**, split by level (**newbie** / **advanced**).

## Adding a resource

1. Open a terminal in the project folder.
2. Run:
   ```
   ./manage_resources.sh
   ```
3. The first time you run it, it will check that `git` and `bundler` are installed.
   If something's missing, it'll ask permission to install it for you (Linux only —
   if you're on macOS/Windows, it'll just tell you what to install manually).
4. Choose **Add resource** and answer the prompts:
   - **Where** — `math`, `cs`, or `others`
   - **Type** — `article` or `video`
   - **Level** — `basic` or `advanced`
   - **Title** — the resource's name
   - **Source link** — the URL
   - **Tags** — comma-separated, e.g. `linear-algebra, intro`
   - **Short description** — one line about it (optional, can leave blank)

That's it — the script creates the file for you in the right folder.

### Editing or deleting a resource

Run the same script and choose **Edit resource** or **Delete resource**. It'll list
the existing resources in the collection you pick so you can select one by number.

## Previewing your changes locally

Before pushing, you can check how the site looks:

```
./startup.sh
```

Then open `http://127.0.0.1:4000` in your browser. Press `Ctrl+C` in the terminal to
stop the local server when you're done.

## Pushing your changes

Once you're happy with what you added:

```
git add .
git commit -m "Add resource: <short description of what you added>"
git push
```

That pushes your changes to GitHub, which automatically rebuilds and publishes the
site via GitHub Actions — no extra steps needed.

## A couple of notes

- If you ever hand-edit a resource file directly instead of using the script, make
  sure the front matter uses `link:` for the URL — **not** `url:`, since `url` is a
  reserved word in Jekyll and will silently break the link.
- If a section on a page looks empty, that's normal — it just means there are no
  resources at that level yet for that topic.
