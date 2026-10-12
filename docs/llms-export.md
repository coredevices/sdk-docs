# Markdown export for agents

`plugins/llms_export.rb` and `lib/llms_export.rb` run after Jekyll has rendered
the site and write:

* `/llms.txt`: an index of every page with a one-line description, grouped by
  the main menu sections, with a short instructions block at the top.
* A `.md` twin of every page at the page URL with `.md` appended
  (`/guides/foo/` and `/docs/c/Foo/index.html` both become `.../Foo.md`).
  Each twin starts with `title`, `canonical_url`, `last_updated` and
  `sdk_version` front matter. `last_updated` is the date of the last commit
  that touched the source file, so the build needs the full git history
  (`fetch-depth: 0` in `build.yml`); generated pages use the build date.
* `/llms-full.txt` and `/guides/llms-full.txt`, `/guides/alloy/llms-full.txt`,
  `/docs/c/llms-full.txt`, `/docs/pebblekit-js/llms-full.txt`: all pages under
  that prefix concatenated.

`plugins/api_index.rb` writes `/api-index.json`, one record per C and
PebbleKit JS symbol, from the parsed doxygen data and
`source/_data/jsdocs-pkjs.json`. The C records are only present when the
doxygen output exists (CI); local builds emit the JS records only.

Rendered pages link to their twin with
`<link rel="alternate" type="text/markdown" href="...">` in `master.html`.
Pages can opt out with `llms_exclude: true` in their front matter.

## Content negotiation (Cloudflare)

Some agents request pages with `Accept: text/markdown`. Serving the `.md`
twin for those requests is a Cloudflare rule outside this repository. Add a
Transform Rule (URL rewrite) on the `developer.repebble.com` zone:

* When: `http.request.headers["accept"][0] contains "text/markdown"` and
  `not ends_with(http.request.uri.path, ".md")` and the path has no file
  extension other than `.html`.
* Rewrite path to:
  `regex_replace(regex_replace(http.request.uri.path, "/index\.html$", "/"), "/$", "") + ".md"`,
  with `/` itself mapped to `/index.md`.

Requests for paths that have no twin return the site's 404 page; keep the
rule limited to the paths `llms.txt` lists if that matters.
