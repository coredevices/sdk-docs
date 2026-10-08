#!/usr/bin/env python3
"""Serve two static site builds side by side with synced scrolling and
block-level change highlighting.

    compare_server.py --old DIR --new DIR --pages FILE [--port 4001]

/compare/<path>  shell page with two iframes
/old/<path>      old build, root-relative URLs rewritten under /old/
/new/<path>      new build, root-relative URLs rewritten under /new/
"""
import argparse
import html
import json
import mimetypes
import os
import re
import sys
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import unquote, urlparse

ARGS = None
PAGES = []  # list of dicts: path, status

INJECT = r"""
<script>
(function () {
  var SIDE = document.documentElement.getAttribute('data-compare-side');
  var SEL = 'p, li, h1, h2, h3, h4, h5, h6, pre, td, th, dt, dd, blockquote, img, figcaption, summary, a.btn, .mainmenu a, .section-menu a, .sidebar a, footer a';
  function norm(el) {
    if (el.tagName === 'IMG') return 'img:' + (el.getAttribute('src') || '').replace(/^\/(old|new)\//, '/');
    var t = (el.innerText || el.textContent || '').replace(/\s+/g, ' ').trim();
    return el.tagName.toLowerCase() + ':' + t;
  }
  function root() { return document.body; }
  function blocks() {
    var all = root().querySelectorAll(SEL), out = [];
    for (var i = 0; i < all.length; i++) {
      var el = all[i];
      if (el.closest('#disqus_thread, script, style, .mobile-nav, #mobile-nav, .quicksearch, .search-results')) continue;
      if (!el.offsetParent && el.tagName !== 'IMG') continue; // skip hidden elements
      if (el.tagName !== 'IMG' && el.querySelector(SEL)) continue; // leaf blocks only
      var k = norm(el);
      if (k.length <= 4) continue;
      out.push({ key: k, el: el });
    }
    return out;
  }
  function isFixed(el) {
    for (var e = el; e && e !== document.body; e = e.parentElement) {
      var pos = getComputedStyle(e).position;
      if (pos === 'fixed' || pos === 'sticky') return true;
    }
    return false;
  }
  function anchors() {
    return blocks().filter(function (b) { return !isFixed(b.el) && !b.el.closest('.mainmenu, .sidebar, nav, header, footer, .section-menu'); });
  }
  window.__compare = {
    blocks: blocks,
    anchors: anchors,
    mark: function (keys, cls) {
      var counts = {};
      keys.forEach(function (k) { counts[k] = (counts[k] || 0) + 1; });
      var changed = 0;
      blocks().forEach(function (b) {
        if (counts[b.key] > 0) { counts[b.key]--; b.el.setAttribute('data-diff', 'same'); }
        else { b.el.setAttribute('data-diff', cls); changed++; }
      });
      return changed;
    },
    keys: function () { return blocks().map(function (b) { return b.key; }); },
    findByKey: function (key) {
      var bs = anchors();
      for (var i = 0; i < bs.length; i++) if (bs[i].key === key) return bs[i].el;
      return null;
    }
  };
  var style = document.createElement('style');
  style.textContent =
    '[data-diff="added"]{background-color:rgba(255,235,59,.45)!important;box-shadow:-6px 0 0 #f9a825!important;}' +
    'img[data-diff="added"]{outline:4px solid #f9a825;}' +
    '[data-diff="removed"]{background-color:rgba(244,67,54,.25)!important;box-shadow:-6px 0 0 #c62828!important;text-decoration:line-through;}' +
    'img[data-diff="removed"]{outline:4px solid #c62828;opacity:.6}' +
    '#disqus_thread{display:none!important}';
  document.head.appendChild(style);
  // links: keep navigation inside this frame; tell parent on load
  window.addEventListener('load', function () { parent.postMessage({ type: 'frame-ready', side: SIDE, path: location.pathname.replace(/^\/(old|new)/, '') }, '*'); });
  var lock = false;
  window.addEventListener('scroll', function () {
    if (lock) return;
    parent.postMessage({ type: 'frame-scroll', side: SIDE, top: window.scrollY, height: document.documentElement.scrollHeight, client: window.innerHeight }, '*');
  }, { passive: true });
  window.addEventListener('message', function (e) {
    var m = e.data || {};
    if (m.type === 'set-scroll') { lock = true; window.scrollTo(0, m.top); setTimeout(function () { lock = false; }, 60); }
  });
})();
</script>
"""

SHELL = r"""<!doctype html>
<html><head><meta charset="utf-8"><title>Compare: {path}</title>
<style>
html,body{{margin:0;height:100%;font:13px/1.4 -apple-system,Helvetica,Arial,sans-serif;background:#111;color:#ddd}}
#bar{{display:flex;align-items:center;gap:10px;padding:6px 10px;background:#1d1d1d;border-bottom:1px solid #333;height:36px}}
#bar select{{max-width:640px;font:inherit;background:#2a2a2a;color:#eee;border:1px solid #444;padding:3px}}
#bar button{{font:inherit;background:#2a2a2a;color:#eee;border:1px solid #444;padding:3px 9px;cursor:pointer}}
#bar button:hover{{background:#3a3a3a}}
#bar .st{{padding:2px 6px;border-radius:3px;font-weight:600;font-size:11px}}
.NEW{{background:#2e7d32}} .CHANGED{{background:#f9a825;color:#111}} .REMOVED{{background:#c62828}} .SAME{{background:#555}}
#bar .counts{{margin-left:auto;opacity:.8}}
#frames{{display:flex;height:calc(100% - 49px)}}
#frames > div{{flex:1;display:flex;flex-direction:column;min-width:0}}
#frames .lab{{padding:3px 10px;background:#1d1d1d;color:#aaa;font-size:11px;letter-spacing:.06em;text-transform:uppercase;border-bottom:1px solid #333}}
#frames .lab b{{color:#eee}}
iframe{{flex:1;border:0;background:#fff;width:100%}}
#left{{border-right:2px solid #333}}
label{{display:flex;align-items:center;gap:4px}}
</style></head>
<body>
<div id="bar">
  <button id="prev" title="Previous page (p)">&#9664;</button>
  <select id="pages"></select>
  <button id="next" title="Next page (n)">&#9654;</button>
  <span id="status" class="st"></span>
  <button id="nextchange" title="Jump to next change (j)">Next change</button>
  <label><input type="checkbox" id="sync" checked> sync scroll</label>
  <label><input type="checkbox" id="hl" checked> highlight</label>
  <span class="counts" id="counts"></span>
</div>
<div id="frames">
  <div id="left"><div class="lab">main (current site) &nbsp; <b id="lpath"></b></div><iframe id="fl" name="fl"></iframe></div>
  <div id="right"><div class="lab">integration (all PRs) &nbsp; <b id="rpath"></b></div><iframe id="fr" name="fr"></iframe></div>
</div>
<script>
var PAGES = {pages_json};
var path = {path_json};
var fl = document.getElementById('fl'), fr = document.getElementById('fr');
var sel = document.getElementById('pages');
PAGES.forEach(function (p, i) {{
  var o = document.createElement('option'); o.value = p.path; o.textContent = '[' + p.status + '] ' + p.path; sel.appendChild(o);
}});
function cur() {{ return PAGES.findIndex(function (p) {{ return p.path === path; }}); }}
function go(p, push) {{
  path = p; sel.value = p;
  var meta = PAGES.find(function (x) {{ return x.path === p; }}) || {{status: 'SAME'}};
  var st = document.getElementById('status'); st.textContent = meta.status; st.className = 'st ' + meta.status;
  ready = {{}};
  fl.src = '/old' + p; fr.src = '/new' + p;
  document.getElementById('lpath').textContent = p; document.getElementById('rpath').textContent = p;
  if (push) history.pushState(null, '', '/compare' + p);
  document.title = 'Compare: ' + p;
}}
sel.onchange = function () {{ go(sel.value, true); }};
document.getElementById('prev').onclick = function () {{ var i = cur(); if (i > 0) go(PAGES[i-1].path, true); }};
document.getElementById('next').onclick = function () {{ var i = cur(); if (i < PAGES.length-1) go(PAGES[i+1].path, true); }};
document.addEventListener('keydown', function (e) {{
  if (e.target.tagName === 'SELECT' || e.target.tagName === 'INPUT') return;
  if (e.key === 'n') document.getElementById('next').click();
  if (e.key === 'p') document.getElementById('prev').click();
  if (e.key === 'j') document.getElementById('nextchange').click();
}});
window.onpopstate = function () {{ go(location.pathname.replace(/^\/compare/, '') || '/', false); }};

var ready = {{}};
function W(f) {{ return f.contentWindow; }}
function api(f) {{ try {{ return W(f).__compare; }} catch (e) {{ return null; }} }}
function runDiff() {{
  var a = api(fl), b = api(fr); if (!a || !b) return;
  var added = b.mark(a.keys(), 'added');
  var removed = a.mark(b.keys(), 'removed');
  document.getElementById('counts').textContent = added + ' added / ' + removed + ' removed blocks';
  if (!document.getElementById('hl').checked) toggleHl(false);
}}
function toggleHl(on) {{
  [fl, fr].forEach(function (f) {{ try {{ W(f).document.documentElement.style.setProperty('--x', '0');
    W(f).document.querySelectorAll('[data-diff]').forEach(function (el) {{ el.style.visibility = ''; if (!on) el.removeAttribute('data-diff'); }}); }} catch (e) {{}} }});
  if (on) runDiff();
}}
document.getElementById('hl').onchange = function (e) {{ toggleHl(e.target.checked); }};

var syncing = false;
function alignOther(fromSide, top, height, client) {{
  if (!document.getElementById('sync').checked) return;
  var from = fromSide === 'old' ? fl : fr, to = fromSide === 'old' ? fr : fl;
  var a = api(from), b = api(to); if (!a || !b) return;
  // find topmost visible unchanged block in source frame, align the matching block in target
  var bs = a.anchors(), anchor = null, offset = 0;
  for (var i = 0; i < bs.length; i++) {{
    var r = bs[i].el.getBoundingClientRect();
    if (r.bottom > 0 && bs[i].el.getAttribute('data-diff') === 'same') {{ anchor = bs[i]; offset = r.top; break; }}
  }}
  var target = anchor ? b.findByKey(anchor.key) : null;
  var newTop;
  if (target) {{
    var tr = target.getBoundingClientRect();
    newTop = W(to).scrollY + tr.top - offset;
  }} else {{
    var d = W(to).document.documentElement;
    var ratio = (height - client) > 0 ? top / (height - client) : 0;
    newTop = ratio * (d.scrollHeight - W(to).innerHeight);
  }}
  W(to).postMessage({{ type: 'set-scroll', top: Math.max(0, newTop) }}, '*');
}}
window.addEventListener('message', function (e) {{
  var m = e.data || {{}};
  if (m.type === 'frame-ready') {{
    ready[m.side] = m.path;
    // follow in-frame navigation on the other side
    var other = m.side === 'old' ? 'new' : 'old';
    if (ready[other] !== undefined && ready[other] !== m.path) {{ ready = {{}}; go(m.path, true); return; }}
    if (ready.old !== undefined && ready.new !== undefined) runDiff();
  }}
  if (m.type === 'frame-scroll') alignOther(m.side, m.top, m.height, m.client);
}});
function jumpTo(frame, side, el) {{
  var w = W(frame), top = Math.max(0, w.scrollY + el.getBoundingClientRect().top - 120);
  w.postMessage({{ type: 'set-scroll', top: top }}, '*');
  setTimeout(function () {{ alignOther(side, top, w.document.documentElement.scrollHeight, w.innerHeight); }}, 120);
}}
document.getElementById('nextchange').onclick = function () {{
  var b = api(fr), a = api(fl); if (!b || !a) return;
  var cand = [];
  W(fr).document.querySelectorAll('[data-diff="added"]').forEach(function (el) {{ var r = el.getBoundingClientRect(); if (r.top > 130 && el.offsetParent) cand.push({{ f: fr, s: 'new', el: el, top: r.top }}); }});
  W(fl).document.querySelectorAll('[data-diff="removed"]').forEach(function (el) {{ var r = el.getBoundingClientRect(); if (r.top > 130 && el.offsetParent) cand.push({{ f: fl, s: 'old', el: el, top: r.top }}); }});
  if (!cand.length) return;
  cand.sort(function (x, y) {{ return x.top - y.top; }});
  jumpTo(cand[0].f, cand[0].s, cand[0].el);
}};
go(path, false);
</script>
</body></html>
"""

PLACEHOLDER = """<!doctype html><html data-compare-side="{side}"><head><meta charset="utf-8">
<style>body{{font:16px -apple-system,Helvetica,sans-serif;color:#555;padding:40px}}</style></head>
<body><h2>{title}</h2><p>{msg}</p></body></html>"""


def rewrite_html(text, side):
    pref = '/' + side
    # root-relative URLs in attributes
    text = re.sub(r'((?:href|src|action|poster|data-post-url)=["\'])/(?!/)', r'\1' + pref + '/', text)
    # srcset
    text = re.sub(r'(srcset=["\'][^"\']*?)(?<=[\s,"\'])/(?!/)', r'\1' + pref + '/', text)
    # inline css url(/...)
    text = re.sub(r'url\((["\']?)/(?!/)', r'url(\1' + pref + '/', text)
    # mark side on <html>
    text = re.sub(r'<html\b', '<html data-compare-side="%s"' % side, text, count=1)
    # inject before </body>
    if '</body>' in text:
        text = text.replace('</body>', INJECT + '</body>', 1)
    else:
        text += INJECT
    return text


def rewrite_css(text, side):
    return re.sub(r'url\((["\']?)/(?!/)', r'url(\1/' + side + '/', text)


class Handler(SimpleHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def do_GET(self):
        u = urlparse(self.path)
        p = unquote(u.path)
        if p == '/' or p == '/compare':
            self.redirect('/compare' + (PAGES[0]['path'] if PAGES else '/'))
            return
        if p.startswith('/compare/'):
            path = p[len('/compare'):]
            body = SHELL.format(path=html.escape(path), pages_json=json.dumps(PAGES), path_json=json.dumps(path))
            self.send_text(body, 'text/html; charset=utf-8')
            return
        m = re.match(r'^/(old|new)(/.*)?$', p)
        if not m:
            # JS-fetched absolute paths (e.g. /mobilenav.html): fall back to the new build, then old
            for side in ('new', 'old'):
                base = ARGS.new if side == 'new' else ARGS.old
                if os.path.isfile(os.path.join(base, p.lstrip('/'))):
                    self.redirect('/%s%s' % (side, p))
                    return
            self.send_error(404)
            return
        side, rel = m.group(1), m.group(2) or '/'
        base = ARGS.old if side == 'old' else ARGS.new
        fs = os.path.normpath(os.path.join(base, rel.lstrip('/')))
        if not fs.startswith(os.path.normpath(base)):
            self.send_error(403)
            return
        if os.path.isdir(fs):
            if not rel.endswith('/'):
                self.redirect('/%s%s/' % (side, rel))
                return
            fs = os.path.join(fs, 'index.html')
        if os.path.isfile(fs) and fs.endswith('.html') and is_redirect_stub(fs):
            title = 'Not on main' if side == 'old' else 'Removed'
            msg = ('On the current site this URL only redirects elsewhere; the page on the right is new.'
                   if side == 'old' else 'In the integration build this URL now redirects elsewhere; the page is removed.')
            self.send_text(PLACEHOLDER.format(side=side, title=title, msg=msg), 'text/html; charset=utf-8', 200)
            return
        if not os.path.exists(fs):
            # try "foo" -> "foo.html"
            if os.path.exists(fs + '.html'):
                fs = fs + '.html'
            else:
                if rel.endswith('/') or rel.endswith('.html'):
                    title = 'Not on main' if side == 'old' else 'Removed'
                    msg = ('This page does not exist on the current site. Everything on the right is new.'
                           if side == 'old' else 'This page is removed in the integration build.')
                    self.send_text(PLACEHOLDER.format(side=side, title=title, msg=msg), 'text/html; charset=utf-8', 200)
                else:
                    self.send_error(404)
                return
        ctype = mimetypes.guess_type(fs)[0] or 'application/octet-stream'
        with open(fs, 'rb') as f:
            data = f.read()
        if ctype == 'text/html':
            data = rewrite_html(data.decode('utf-8', 'replace'), side).encode('utf-8')
            ctype = 'text/html; charset=utf-8'
        elif ctype == 'text/css':
            data = rewrite_css(data.decode('utf-8', 'replace'), side).encode('utf-8')
        self.send_response(200)
        self.send_header('Content-Type', ctype)
        self.send_header('Content-Length', str(len(data)))
        self.send_header('Cache-Control', 'no-store')
        self.end_headers()
        self.wfile.write(data)

    def redirect(self, to):
        self.send_response(302)
        self.send_header('Location', to)
        self.end_headers()

    def send_text(self, body, ctype, code=200):
        data = body.encode('utf-8')
        self.send_response(code)
        self.send_header('Content-Type', ctype)
        self.send_header('Content-Length', str(len(data)))
        self.send_header('Cache-Control', 'no-store')
        self.end_headers()
        self.wfile.write(data)


def is_redirect_stub(fs):
    try:
        if os.path.getsize(fs) > 4096:
            return False
        with open(fs, 'r', errors='replace') as f:
            return 'http-equiv="refresh"' in f.read()
    except OSError:
        return False


def resolve_page(base, path):
    """Return the file for a page path, or None if absent or a redirect stub."""
    fs = os.path.join(base, path.lstrip('/'))
    for cand in (os.path.join(fs, 'index.html'), fs, fs.rstrip('/') + '.html'):
        if os.path.isfile(cand):
            return None if is_redirect_stub(cand) else cand
    return None


def page_exists(base, path):
    return resolve_page(base, path) is not None


def load_pages(args):
    paths = []
    for line in open(args.pages):
        line = line.strip()
        if not line:
            continue
        line = re.sub(r'^https?://[^/]+', '', line)
        if not line.startswith('/'):
            line = '/' + line
        paths.append(line)
    # removed pages: html under old but not new, excluding blog/assets
    for root, dirs, files in os.walk(args.old):
        if 'index.html' in files:
            rel = '/' + os.path.relpath(root, args.old).replace(os.sep, '/') + '/'
            rel = rel.replace('/./', '/')
            if rel.startswith(('/blog', '/assets', '/docs/c/', '/docs/pebblekit', '/build', '/community/apps', '/community/libraries', '/community/tools', '/developer.')):
                continue
            if page_exists(args.old, rel) and not page_exists(args.new, rel) and rel not in paths:
                paths.append(rel)
    pages = []
    seen = set()
    for p in paths:
        if p in seen:
            continue
        seen.add(p)
        o, n = page_exists(args.old, p), page_exists(args.new, p)
        if not o and not n:
            continue
        status = 'CHANGED' if (o and n) else 'NEW' if n else 'REMOVED'
        pages.append({'path': p, 'status': status})
    # order: changed/new first in given order, removed at end
    pages.sort(key=lambda x: (x['status'] == 'REMOVED', x['path'] == '/'))
    return pages


def main():
    global ARGS, PAGES
    ap = argparse.ArgumentParser()
    ap.add_argument('--old', required=True)
    ap.add_argument('--new', required=True)
    ap.add_argument('--pages', required=True)
    ap.add_argument('--port', type=int, default=4001)
    ARGS = ap.parse_args()
    ARGS.old = os.path.abspath(ARGS.old)
    ARGS.new = os.path.abspath(ARGS.new)
    PAGES = load_pages(ARGS)
    print('pages:', len(PAGES), 'changed:', sum(p['status'] == 'CHANGED' for p in PAGES),
          'new:', sum(p['status'] == 'NEW' for p in PAGES), 'removed:', sum(p['status'] == 'REMOVED' for p in PAGES))
    srv = ThreadingHTTPServer(('127.0.0.1', ARGS.port), Handler)
    print('http://localhost:%d/' % ARGS.port)
    srv.serve_forever()


if __name__ == '__main__':
    main()
