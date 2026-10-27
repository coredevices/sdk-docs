#!/usr/bin/env python3
# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Import the PebbleOS firmware documentation into the developer site.

Given a checkout of github.com/coredevices/pebbleos, this script:

* runs Doxygen with the repository's ``docs/_doxygen/Doxyfile.rtd`` and copies the HTML
  output to ``source/pebbleos/apidoc/``;
* runs the Sphinx JSON builder on ``docs/`` and writes one Jekyll page per
  document under ``source/pebbleos/docs/<path>/index.html``, with the
  resolved HTML body and front matter for the ``pebbleos/default`` layout;
* writes a redirect page for every old URL in ``pbl_redirects``;
* copies the images Sphinx collected to ``source/pebbleos/docs/images/``, and
  the playground's WebAssembly firmware builds to
  ``source/pebbleos/docs/playground-build/``;
* writes ``source/_data/pebbleos.json`` with the sidebar navigation (taken
  from the toctrees in ``docs/index.md``, grouped by caption like the Read the
  Docs sidebar) and the PebbleOS commit it was
  generated from.

Nothing is written into the pebbleos checkout. Run it with the Python
environment that has ``docs/requirements.txt`` installed, and with
``doxygen`` on the PATH. The playground also needs what the firmware build
needs (see ``docs/_scripts/pbl_playground_setup_rtd.sh`` in pebbleos), or
``--skip-playground``:

    python3 scripts/import_pebbleos_docs.py /path/to/pebbleos .

The second argument is the sdk-docs checkout (or any directory with the same
``source/`` layout, which CI uploads as an artifact).
"""

import argparse
import html
import json
import os
import pickle
import posixpath
import re
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from html.parser import HTMLParser

SITE_PREFIX = '/pebbleos/docs/'
APIDOC_PREFIX = '/pebbleos/apidoc/'
# Sphinx's _playground/ output; Jekyll skips directories starting with "_".
PLAYGROUND_URL = SITE_PREFIX + 'playground-build/'
HUB_URL = '/pebbleos/'
# Pinned in pebbleos/.readthedocs.yaml (doxygen-awesome-css v2.4.2).
AWESOME_CSS_REPO = 'https://github.com/jothepro/doxygen-awesome-css.git'
AWESOME_CSS_COMMIT = 'd52eafe3e9303399fda15661f3d7bb8fe3d7eabc'
SKIPPED_DOCS = {'index', 'genindex', 'search'}


def log(message):
    print(f'[pebbleos-docs] {message}', flush=True)


def run(command, **kwargs):
    log(' '.join(command))
    subprocess.run(command, check=True, **kwargs)


# --- URL mapping -------------------------------------------------------------

def doc_url(docname):
    """Site URL for a Sphinx document name."""
    if docname == 'index':
        return HUB_URL
    if docname.endswith('/index'):
        docname = docname[:-len('/index')]
    return f'{SITE_PREFIX}{docname}/'


def doc_base(docname):
    """Directory the Sphinx JSON builder resolves a document's links from.

    The JSON builder emits dirhtml-style targets (``../pbl/``, ``asterix/``),
    relative to ``<docname>/`` with ``index`` collapsed.
    """
    if docname == 'index':
        return ''
    if docname.endswith('/index'):
        return docname[:-len('index')]
    return docname + '/'


def rewrite_target(docname, target):
    """Rewrite one href/src value from a Sphinx body to a site URL."""
    if re.match(r'^[a-zA-Z][a-zA-Z0-9+.-]*:', target) or target.startswith(('#', '/')):
        return target
    path, sep, fragment = target.partition('#')
    if not path:
        return target
    # The {apidoc} role writes html-builder paths (../ per path segment of
    # the docname), not the dirhtml-style ones the rest of the body uses.
    apidoc = re.match(r'^(?:\.\./)*apidoc/(.*)$', path)
    if apidoc:
        return APIDOC_PREFIX + apidoc.group(1) + sep + fragment
    resolved = posixpath.normpath(posixpath.join(doc_base(docname), path))
    if resolved == '.':
        resolved = ''
    if path.endswith('/') or resolved == '':
        new = HUB_URL if resolved == '' else f'{SITE_PREFIX}{resolved}/'
    elif resolved.startswith('_images/'):
        new = SITE_PREFIX + 'images/' + resolved[len('_images/'):]
    elif resolved.startswith('apidoc/'):
        new = APIDOC_PREFIX + resolved[len('apidoc/'):]
    else:
        log(f'warning: {docname}: unrecognised link target {target!r} left as is')
        return target
    return new + sep + fragment


def rewrite_body(docname, body):
    def repl(match):
        return f'{match.group(1)}="{rewrite_target(docname, match.group(2))}"'
    body = re.sub(r'\b(href|src)="([^"]*)"', repl, body)
    # The playground's script gets the builds' location as a relative string.
    return re.sub(r'"(?:\.\./)*_playground/"', f'"{PLAYGROUND_URL}"', body)


def selftest():
    assert doc_url('development/qemu') == '/pebbleos/docs/development/qemu/'
    assert doc_url('boards/index') == '/pebbleos/docs/boards/'
    assert doc_url('index') == '/pebbleos/'
    assert rewrite_target('development/qemu', '../pbl/') == '/pebbleos/docs/development/pbl/'
    assert rewrite_target('development/building_fw', '../../boards/') == '/pebbleos/docs/boards/'
    assert rewrite_target('boards/index', 'asterix/#programming') == '/pebbleos/docs/boards/asterix/#programming'
    assert rewrite_target('architecture/index', '../apidoc/index.html') == '/pebbleos/apidoc/index.html'
    assert rewrite_target('subsystems/bluetooth', '../apidoc/d3/ddb/g.html') == '/pebbleos/apidoc/d3/ddb/g.html'
    assert rewrite_target('architecture/activity/index', '../../_images/a.png') == '/pebbleos/docs/images/a.png'
    assert rewrite_target('reference/index', '../') == '/pebbleos/'
    assert rewrite_target('development/qemu', 'https://example.com/x') == 'https://example.com/x'
    assert rewrite_target('development/qemu', '#run') == '#run'
    assert external_url('https://pebbleos.readthedocs.io/en/latest/apidoc/index.html') == '/pebbleos/apidoc/index.html'
    assert external_url('https://example.com/x') == 'https://example.com/x'
    assert rewrite_body('playground', 'const base = "_playground/";') == \
        'const base = "/pebbleos/docs/playground-build/";'


# --- Sphinx output -----------------------------------------------------------

class TocParser(HTMLParser):
    """Turn Sphinx's local ``toc`` HTML into [[id, title, level], ...]."""

    def __init__(self):
        super().__init__()
        self.entries = []
        self.level = 0
        self.current = None

    def handle_starttag(self, tag, attrs):
        if tag == 'ul':
            self.level += 1
        elif tag == 'a':
            href = dict(attrs).get('href', '')
            self.current = [href.lstrip('#'), '', self.level]

    def handle_endtag(self, tag):
        if tag == 'ul':
            self.level -= 1
        elif tag == 'a' and self.current:
            self.current[1] = self.current[1].strip()
            self.entries.append(self.current)
            self.current = None

    def handle_data(self, data):
        if self.current:
            self.current[1] += data


def page_toc(toc_html):
    parser = TocParser()
    parser.feed(toc_html)
    # The first entry is the page title itself (level 1); the layout prints
    # that already. Shift the rest up so sections start at level 1.
    entries = [[i, t, level - 1] for i, t, level in parser.entries if level > 1 and i]
    return entries if len(entries) > 1 else []


def strip_title(body):
    """Drop the body's own <h1> (the layout renders the page title) and the
    pilcrow anchors Sphinx adds after headings."""
    body = re.sub(r'<h1>.*?</h1>\s*', '', body, count=1, flags=re.S)
    return re.sub(r'<a class="headerlink"[^>]*>¶</a>', '', body)


def escape_liquid(body):
    """Keep Jekyll's Liquid from interpreting braces in the imported HTML."""
    return body.replace('{{', '&#123;&#123;').replace('{%', '&#123;%')


def external_url(url):
    """Point links to the Read the Docs API reference at the copy on this site."""
    match = re.match(r'^https://pebbleos\.readthedocs\.io/[^/]+/[^/]+/apidoc/(.*)$', url)
    return APIDOC_PREFIX + match.group(1) if match else url


def nav_groups(env):
    """Sidebar groups from the toctrees in docs/index.md, as on Read the Docs.

    Each caption (Development, System, ...) is a group listing its entries;
    each entry lists the pages of its own toctree. Returns the groups and,
    per document, its group slug and the URL of the entry it falls under.
    """
    from sphinx import addnodes

    includes = env.toctree_includes
    titles = {name: node.astext() for name, node in env.titles.items()}
    groups = []
    place = {}

    def claim(name, slug, parent, shown):
        # shown: the sidebar entry that stands for this page, the page itself
        # down to the entries' children, their ancestor below that.
        if name in place:
            return
        place[name] = (slug, parent, shown)
        for child in includes.get(name, []):
            claim(child, slug, parent, doc_url(child) if shown == parent else shown)

    for node in env.tocs['index'].findall(addnodes.toctree):
        caption = re.sub(r'^[^\w]+', '', node.get('caption') or '').strip()
        if not caption:
            continue
        slug = re.sub(r'[^a-z0-9]+', '-', caption.lower()).strip('-')
        pages = []
        for title, name in node['entries']:
            if name in titles:
                url = doc_url(name)
                claim(name, slug, url, url)
                pages.append({
                    'title': title or titles[name],
                    'url': url,
                    'children': [{'title': titles[child], 'url': doc_url(child)}
                                 for child in includes.get(name, []) if child in titles],
                })
            elif re.match(r'^https?://', name):
                pages.append({'title': title or name, 'url': external_url(name), 'external': True})
        if pages:
            groups.append({'slug': slug, 'title': caption, 'url': pages[0]['url'], 'pages': pages})
    return groups, place


def front_matter(data):
    lines = ['---']
    for key, value in data.items():
        # JSON scalars and arrays are valid YAML.
        lines.append(f'{key}: {json.dumps(value)}')
    lines.append('---')
    return '\n'.join(lines) + '\n'


def write_pages(json_dir, out_docs, sha):
    with open(os.path.join(json_dir, 'environment.pickle'), 'rb') as handle:
        env = pickle.load(handle)
    groups, place = nav_groups(env)

    count = 0
    for docname in sorted(env.all_docs):
        if docname in SKIPPED_DOCS:
            continue
        with open(os.path.join(json_dir, docname + '.fjson'), encoding='utf-8') as handle:
            page = json.load(handle)
        group, parent, shown = place.get(docname, (None, None, None))
        if group is None:
            log(f'warning: {docname} is not reachable from docs/index.md toctrees')
        url = doc_url(docname)
        data = {
            'layout': 'pebbleos/default',
            # Sphinx gives titles as HTML (``<code>`` for ``pbl build``).
            'title': html.unescape(re.sub(r'<[^>]+>', '', page['title'])),
            'permalink': url,
            'pebbleos_group': group,
            'pebbleos_parent': parent,
            'pebbleos_active': shown,
            'menu_subsection': group,
            'pebbleos_source': page['current_page_name'] + page['page_source_suffix'],
            'pebbleos_sha': sha,
            'search_index': True,
            'search_html': True,
            'search_group': 'PebbleOS',
        }
        toc = page_toc(page.get('toc') or '')
        if toc:
            data['pebbleos_toc'] = toc
        body = escape_liquid(rewrite_body(docname, strip_title(page['body'])))
        target = os.path.join(out_docs, url[len(SITE_PREFIX):], 'index.html')
        os.makedirs(os.path.dirname(target), exist_ok=True)
        with open(target, 'w', encoding='utf-8') as handle:
            handle.write(front_matter(data))
            handle.write(body)
        if 'id="__kconfig-search"' in body:
            # kconfig.mjs fetches kconfig.json next to the page; the layout
            # loads the script and its styles from there too.
            for name in ('kconfig.json', '_static/kconfig.mjs', '_static/kconfig.css'):
                shutil.copy2(os.path.join(json_dir, name), os.path.dirname(target))
        count += 1
    log(f'wrote {count} pages')

    # Pages that moved (pbl_redirects in docs/conf.py) keep their old URL.
    redirects = getattr(env.config, 'pbl_redirects', None) or {}
    for old, new in redirects.items():
        target = os.path.join(out_docs, doc_url(old)[len(SITE_PREFIX):], 'index.html')
        if os.path.exists(target) or new not in env.all_docs:
            continue
        os.makedirs(os.path.dirname(target), exist_ok=True)
        with open(target, 'w', encoding='utf-8') as handle:
            handle.write(front_matter({'layout': 'utils/redirect_permanent',
                                       'redirect_to': doc_url(new)}))
    log(f'wrote {len(redirects)} redirects')
    return groups


# --- Doxygen -----------------------------------------------------------------

def build_apidoc(checkout, work):
    css_dir = os.path.join(work, 'doxygen-awesome-css')
    run(['git', 'clone', '-q', AWESOME_CSS_REPO, css_dir])
    run(['git', '-C', css_dir, 'checkout', '-q', AWESOME_CSS_COMMIT])

    out = os.path.join(work, 'doxygen')
    # Doxyfile.rtd includes Doxyfile; doxygen crashes on nested @INCLUDE
    # from a third file, so concatenate the two and append the overrides.
    doxygen_dir = os.path.join(checkout, 'docs', '_doxygen')
    with open(os.path.join(doxygen_dir, 'Doxyfile'), encoding='utf-8') as handle:
        config = handle.read()
    with open(os.path.join(doxygen_dir, 'Doxyfile.rtd'), encoding='utf-8') as handle:
        config += ''.join(line for line in handle if not line.startswith('@INCLUDE'))
    config += '\n'.join([
        '',
        f'OUTPUT_DIRECTORY = {out}',
        'HTML_EXTRA_STYLESHEET = ' + ' '.join([
            os.path.join(css_dir, 'doxygen-awesome.css'),
            os.path.join(css_dir, 'doxygen-awesome-sidebar-only.css'),
            os.path.join(doxygen_dir, 'pebble.css'),
        ]),
        'GENERATE_TAGFILE =',
        # Read the Docs fails its own build on warnings; the site build does not.
        'WARN_AS_ERROR = NO',
        '',
    ])
    config_path = os.path.join(work, 'Doxyfile')
    with open(config_path, 'w', encoding='utf-8') as handle:
        handle.write(config)
    # Doxyfile.rtd takes the version from PBL_DOCS_VERSION, as docs/conf.py
    # takes it from git describe.
    version = subprocess.check_output(['git', 'describe'], cwd=checkout, text=True).strip()
    run(['doxygen', config_path], cwd=checkout,
        env={**os.environ, 'PBL_DOCS_VERSION': version})
    return os.path.join(out, 'apidoc')


# --- Main --------------------------------------------------------------------

def replace_tree(src, dst):
    if os.path.isdir(dst):
        shutil.rmtree(dst)
    shutil.copytree(src, dst)


def main():
    selftest()
    parser = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    parser.add_argument('checkout', help='pebbleos checkout')
    parser.add_argument('site', help='sdk-docs checkout, or a staging directory')
    parser.add_argument('--sha', help='PebbleOS commit to record (default: git rev-parse HEAD)')
    parser.add_argument('--skip-apidoc', action='store_true', help='do not run Doxygen')
    parser.add_argument('--skip-playground', action='store_true',
                        help='do not build the firmware for the playground page')
    args = parser.parse_args()

    checkout = os.path.abspath(args.checkout)
    sha = args.sha
    if not sha:
        result = subprocess.run(['git', '-C', checkout, 'rev-parse', 'HEAD'],
                                capture_output=True, text=True)
        sha = result.stdout.strip() if result.returncode == 0 else 'unknown'
    log(f'Generated from PebbleOS {sha}')

    out_docs = os.path.join(args.site, 'source', 'pebbleos', 'docs')
    out_apidoc = os.path.join(args.site, 'source', 'pebbleos', 'apidoc')
    out_data = os.path.join(args.site, 'source', '_data', 'pebbleos.json')

    work = tempfile.mkdtemp(prefix='pebbleos-docs-')
    try:
        json_dir = os.path.join(work, 'json')
        run([sys.executable, '-m', 'sphinx', '-q', '-b', 'json',
             # The book theme's page hooks fail under the JSON builder, and
             # only the bodies are used here.
             '-D', 'html_theme=basic',
             # The playground page embeds WebAssembly builds of the firmware,
             # which need CMake, Ninja and Emscripten. Build them outside the
             # checkout.
             '-D', f'pbl_playground={0 if args.skip_playground else 1}',
             '-D', f'pbl_playground_build_dir={os.path.join(work, "playground")}',
             '-d', os.path.join(work, 'doctrees'),
             os.path.join(checkout, 'docs'), json_dir])

        if os.path.isdir(out_docs):
            shutil.rmtree(out_docs)
        groups = write_pages(json_dir, out_docs, sha)
        if os.path.isdir(os.path.join(json_dir, '_images')):
            replace_tree(os.path.join(json_dir, '_images'), os.path.join(out_docs, 'images'))
        if os.path.isdir(os.path.join(json_dir, '_playground')):
            replace_tree(os.path.join(json_dir, '_playground'),
                         os.path.join(out_docs, PLAYGROUND_URL[len(SITE_PREFIX):]))

        if not args.skip_apidoc:
            replace_tree(build_apidoc(checkout, work), out_apidoc)

        os.makedirs(os.path.dirname(out_data), exist_ok=True)
        with open(out_data, 'w', encoding='utf-8') as handle:
            json.dump({
                'sha': sha,
                'short_sha': sha[:9],
                'generated': datetime.now(timezone.utc).strftime('%Y-%m-%d'),
                'groups': groups,
            }, handle, indent=2)
        log(f'wrote {out_data}')
    finally:
        shutil.rmtree(work, ignore_errors=True)


if __name__ == '__main__':
    main()
