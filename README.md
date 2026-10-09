# [developer.repebble.com][site]

[![Build static site](https://github.com/coredevices/sdk-docs/actions/workflows/build.yml/badge.svg)](https://github.com/coredevices/sdk-docs/actions/workflows/build.yml)

This is the repository for the [Pebble Developer website][site].

The website is built using [Jekyll](http://jekyllrb.com) with some plugins that
provide custom functionality.

For anyone who wants to contribute to the content of the site, you should find
the information in one of the sections below.

* [Blog Posts](#blog-posts)
* [Markdown](#markdown)
* [Landing Page Features](#landing-page-features)
* [Colors](#colors)

## Getting Started

### Option 1: Build with Docker

The repository ships a `Dockerfile` with the pinned Ruby and the gems
installed. Build the image once, then run Jekyll from it:

```
docker build -t rebble-dev .

docker run --rm -it -p 4000:4000 -v "$PWD":/site -w /site rebble-dev \
  bundle exec jekyll serve --host 0.0.0.0 --port 4000
```

Then open http://localhost:4000. With [just](https://github.com/casey/just)
installed, `just docker-dev` runs the same command, and `just docker-build`
writes the static site to `__public__/`.

### Option 2: Install natively (without Docker)

The `Gemfile` pins the Ruby version to the one in `.ruby-version` (3.3.8).
`bundle install` fails on any other Ruby, so install that version with a
version manager such as `rbenv` or `mise`, or use Docker.

Once you have cloned the project you will need to run `bundle install` to
install the Ruby dependencies. If you do not have [bundler](http://bundler.io/)
installed you will need to run `[sudo] gem install bundler` first.

You should also do `cp .env.sample .env` and edit the newly created `.env` file
with the appropriate values. Take a look at the
[Environment Variables documentation](/docs/environment.md) for more details.

To start the Jekyll web server, run `bundle exec jekyll serve`.

## C API Reference

The C API reference under `/docs/c/` is generated from Doxygen XML, not from
Markdown in this repository. The Docker image sets `SKIP_DOCS=true`, so a local
build skips the reference and `/docs/c/` is empty. This is expected.

To build the reference locally:

1. Generate the Doxygen output for emery. The `gendocs-c` job in
   `.github/workflows/build.yml` has the exact commands; it checks out
   [coredevices/pebbleos](https://github.com/coredevices/pebbleos) at the tag
   in `EMERY_SDK_VERSION` and produces `build/sdk/emery/doxygen_sdk`.
2. Copy that directory to `emery/doxygen_sdk/` in the repository root, next to
   the committed `aplite/doxygen_sdk/` and `basalt/doxygen_sdk/`.
3. Build with `SKIP_DOCS=false`, for example
   `docker run --rm -e SKIP_DOCS=false -v "$PWD":/site -w /site rebble-dev bundle exec jekyll build`.

The PebbleKit Android and iOS references are downloaded from `DOCS_URL` at
build time and are also skipped locally.

## JS Documentation

The PebbleKit JS documentation is generated with the
[documentation.js](documentation.js.org) framework. The documentation tool
creates `source/_data/jsdocs-pkjs.json` from the JSDoc comments in the
[js-docs](/js-docs) folder.

To install documentation.js, run `npm install -g documentation`

To regenerate the JSON file, run `./scripts/generate-js-docs.sh`

## Blog Posts

### Setting up a new author
Add your name to the `source/_data/authors.yml` so the blog knows who you are!

```
blogUsername:
  name: First Last
  photo: https://example.com/you.png
```

### Creating a new blog post
Add a Markdown file in `source/_posts/` with a filename in following the
format: `YYYY-MM-DD-Title-of-the-blog-most.md`.

Start the file with a block of YAML metadata:

```
---
title: Parlez-vous Pebble? Sprechen sie Pebble? ¿Hablas Pebble?
author: blogUsername
tags:
- Freshly Baked
---
```

You should pick one tag from this list:

* Freshly Baked - Posts announcing or talking about new features
* Beautiful Code - Posts about writing better code
* "#makeawesomehappen" - Hackathons/events/etc
* At the Pub - Guest Blog Posts (presumably written at a pub)
* Down the Rabbit Hole - How Pebble works 'on the inside'
* CloudPebble - Posts about CloudPebble
* Timeline - Posts about Timeline

### Setting the post's preview text

The blog's homepage will automatically generate a 'preview' of your blog post. It does this by finding the first set of 3 consecutive blank lines, and using everything before those lines as the preview.

You should aim to have your preview be 1-2 paragraphs, and end with a hook that causes the reader to want to click the 'Read More' link.

## Markdown

There is a [Markdown styleguide and additional syntax cheatsheat][markdown]
you should use if you are writing any Markdown for the site. That includes all
blog posts and guides.

## Landing Page Features

The landing page of the website contains a slideshow (powered by [slick][slick]).
The contents of the slideshow, or 'features' as we call them, are generated
from the features data file found at `source/_data/features.yaml`.

There are two main types of features, images and videos.

### Image Feature

```yaml
- title: Want to make your apps more internationally friendly?
  url: /guides/publishing-tools/i18n-guide/
  background_image: /images/landing-page/i18n-guide.png
  button_text: Read our brand new guide to find out how
  button_fg: black
  button_bg: yellow
  duration: 5000
```

It should be relatively clear what each of the fields is for. For the
`button_fg` and `button_bg` options, check out the [colors](#colors) section
for the available choices.

The `background_image` can either be a local asset file or an image on an
external web server.

**Please Remember:** The landing page will see a lot of traffic so you
should strive to keep image sizes small, while still maintaing relatively large
dimensions. Run the images through minifying tools, such as
[TinyPNG][tinypng] or [TinyJPG][tinyjpg], before commiting them to the site.

### Video Feature

```yaml
- title: Send a Smile with Android Actionable Notifications
  url: /blog/2014/12/19/Leverage-Android-Actionable-Notifications/
  background_image: /images/landing-page/actionable-notifications.png
  video:
    url: https://s3.amazonaws.com/developer.getpebble.com/videos/actionable-notifications.mp4
  button_text: Learn how to supercharge Your Android Apps
  button_fg: white
  button_bg: green
  duration: 5000
```

To prevent massively bloating the size of this repository, we are hosting all
videos externally on S3. If you do not have permission to upload videos to our
S3 bucket, you will need to ask someone who does!

In order to enable to videos to play across all of the browsers + platforms,
you will need to provided the video in MP4, OGV and WEBM formats.
There is a script provided in the scripts folder to do the automatic conversion
from MP4, and to export the first frame of the video as a PNG used as a
placeholder while the video loads.

```sh
./scripts/video-encode.sh PATH_TO_MP4
```

If you run the script as above, it will create an OGV, WEBM and PNG file in the same folder as the MP4. The PNG file should go in the `/assets/images/landing-page/` folder, and the three video files should be uploaded to S3.

## Colors

Buttons and Alerts come are available in several different color options, with
both foreground and background modifier classes to give you maximum control.

The available colors:

* white
* green
* blue
* red
* purple
* yellow
* orange
* lightblue
* dark-red

To set the background, use `--bg-<COLOR>` modifier. To set the foreground (i.e)
the text color, use `--fg-<COLOR>`.

## Troubleshooting

Trouble building the developer site? Read the [Troubleshooting](/docs/troubleshooting.md) page for some possible solutions.

[site]: https://developer.repebble.com
[markdown]: ./docs/markdown.md
[slick]: http://kenwheeler.github.io/slick/
[tinypng]: https://tinypng.com/
[tinyjpg]: https://tinyjpg.com/

## Comparing two builds

`scripts/compare_builds.py` serves two built sites side by side with synced
scrolling and block-level change highlighting, for reviewing a large set of
changes against the current site:

```
python3 scripts/compare_builds.py --old /path/to/main/__public__ --new __public__ --pages pages.txt --port 4001
```

Without `--pages`, every page whose text differs between the two builds is
listed, plus pages present in only one build (new or removed). Open
http://localhost:4001/ and step through the pages with the arrows or the
`n`/`p`/`j` keys.

`--static DIR` writes the comparison as a plain directory instead of serving
it. Pull request builds do this and upload the result as the `site-compare`
artifact; unzip it and serve the directory at the root of any static server
(`python3 -m http.server`) to review the pull request page by page.
