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

"""Import the developer-facing Markdown from the Pebble mobile app repository.

Given a checkout of github.com/coredevices/mobileapp, this script writes one
Jekyll page for each document listed in ``PAGES`` below, with front matter
for the site and the Markdown body adjusted so the site renders it:

* the document's own title heading is dropped (the layout prints the page
  title), and the remaining headings are moved down one level when the
  document uses top-level headings for its sections;
* relative links become links to the file in the repository at the imported
  commit;
* fenced code languages the site's highlighter does not know are mapped;
* a note at the top says where the page comes from.

Nothing is written into the mobileapp checkout:

    python3 scripts/import_mobileapp_docs.py /path/to/mobileapp .

The second argument is the sdk-docs checkout (or any directory with the same
``source/`` layout, which CI uploads as an artifact).
"""

import argparse
import json
import os
import posixpath
import re
import subprocess
import sys

REPO = 'https://github.com/coredevices/mobileapp'

# (path in mobileapp, path under source/, front matter)
PAGES = [
    (
        'test-apps/plugins.md',
        '_guides/plugins/preview.md',
        {
            'title': 'Pebble Plugins Preview',
            'description': 'What plugins are, how to try the preview in the '
                           'Pebble mobile app, how a watchapp reads plugin '
                           'data from PebbleKit JS, and how to write a plugin.',
            'guide_group': 'plugins',
            'permalink': '/guides/plugins/preview/',
            'menu': True,
            'generate_toc': True,
        },
    ),
    (
        'experimental/src/commonMain/kotlin/coredevices/ring/external/'
        'indexwebhook/INDEX_WEBHOOK_API.md',
        'index-01/webhooks.md',
        {
            'layout': 'index-01',
            'title': 'Webhooks',
            'description': 'The HTTP request the Pebble mobile app sends for '
                           'each Index 01 recording, and how to verify its '
                           'signature.',
            'permalink': '/index-01/webhooks/',
            'generate_toc': True,
            'search_index': True,
            'search_group': 'Index 01',
        },
    ),
]

# Fence languages that Pygments has no lexer for.
LANGUAGES = {'jsonc': 'json', 'js': 'javascript'}

LINK_RE = re.compile(r'(?<!!)\[([^\]]*)\]\(([^)\s]+)\)')
FENCE_RE = re.compile(r'^```(\w*)\s*$', re.M)


def log(message):
    print(message, file=sys.stderr)


def git_sha(checkout):
    return subprocess.run(['git', '-C', checkout, 'rev-parse', 'HEAD'],
                          check=True, capture_output=True,
                          text=True).stdout.strip()


def split_fences(text):
    """Alternate (is_code, chunk) so prose rewrites skip code blocks."""
    chunks = []
    code = False
    buf = []
    for line in text.splitlines(keepends=True):
        if line.startswith('```'):
            if code:
                buf.append(line)
                chunks.append((True, ''.join(buf)))
                buf = []
                code = False
                continue
            chunks.append((False, ''.join(buf)))
            buf = [line]
            code = True
            continue
        buf.append(line)
    chunks.append((code, ''.join(buf)))
    return chunks


def rewrite_prose(text, source_path, sha):
    base = posixpath.dirname(source_path)

    def link(match):
        label, target = match.groups()
        if re.match(r'^[a-z]+:', target) or target.startswith(('#', '/')):
            return match.group(0)
        path = posixpath.normpath(posixpath.join(base, target))
        return f'[{label}]({REPO}/blob/{sha}/{path})'

    return LINK_RE.sub(link, text)


def convert(body, source_path, sha):
    lines = body.splitlines()
    # Drop the title heading and any blank lines after it.
    if lines and lines[0].startswith('# '):
        lines = lines[1:]
        while lines and not lines[0].strip():
            lines = lines[1:]
    body = '\n'.join(lines) + '\n'

    chunks = split_fences(body)
    prose = ''.join(chunk for code, chunk in chunks if not code)
    demote = re.search(r'^# ', prose, re.M) is not None

    out = []
    for code, chunk in chunks:
        if code:
            out.append(FENCE_RE.sub(
                lambda m: '```' + LANGUAGES.get(m.group(1), m.group(1) or 'text'),
                chunk, count=1))
            continue
        if demote:
            chunk = re.sub(r'^(#{1,5}) ', r'#\1 ', chunk, flags=re.M)
        out.append(rewrite_prose(chunk, source_path, sha))
    return ''.join(out)


def front_matter(data):
    lines = ['---']
    for key, value in data.items():
        lines.append(f'{key}: {json.dumps(value)}')
    lines.append('---')
    return '\n'.join(lines) + '\n'


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('checkout', help='mobileapp checkout')
    parser.add_argument('site', help='sdk-docs checkout or output directory')
    args = parser.parse_args()

    sha = git_sha(args.checkout)
    log(f'Generated from mobileapp {sha}')
    for source_path, target_path, data in PAGES:
        with open(os.path.join(args.checkout, source_path),
                  encoding='utf-8') as handle:
            body = handle.read()
        data = dict(data, mobileapp_source=source_path, mobileapp_sha=sha)
        note = (
            f'{{% alert notice %}}\n'
            f'This page is generated from '
            f'[`{posixpath.basename(source_path)}`]'
            f'({REPO}/blob/{sha}/{source_path}) in the '
            f'[Pebble mobile app repository]({REPO}) at commit '
            f'[{sha[:9]}]({REPO}/commit/{sha}). Relative paths refer to that '
            f'directory. Changes belong in that repository.\n'
            f'{{% endalert %}}\n\n'
        )
        target = os.path.join(args.site, 'source', target_path)
        os.makedirs(os.path.dirname(target), exist_ok=True)
        with open(target, 'w', encoding='utf-8') as handle:
            handle.write(front_matter(data))
            handle.write(note)
            handle.write('{% raw %}\n')
            handle.write(convert(body, source_path, sha))
            handle.write('{% endraw %}\n')
        log(f'wrote {target_path}')


if __name__ == '__main__':
    main()
