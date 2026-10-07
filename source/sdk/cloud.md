---
layout: sdk/markdown
title: Use CloudPebble
permalink: /sdk/cloud/
menu_section: sdk
menu_subsection: cloud
generate_toc: true
scripts:
  - sdk/index
---

CloudPebble is the fastest way to get started building Pebble apps and watchfaces - no installation required! It runs entirely in your browser.

<a href="https://cloudpebble.repebble.com" class="btn btn--fg-lightblue btn--bg-white">Go to CloudPebble</a>

## What's included

CloudPebble is a browser-based IDE with the Pebble SDK built in. Write code,
compile, and install apps on your watch or the emulator from your browser.

- **Code editor** with code completion, syntax error checking, and inline API documentation
- **Built-in compiler** - one-click build with errors linked to source lines
- **Emulator** - run your app on a virtual Pebble watch in the browser or on a server
- **On-device install** - install on your watch through the Pebble mobile app
- **Resource management** - manage images, fonts, and data files through a graphical interface
- **GitHub integration** - import from, pull from and push to GitHub repositories
- **Package support** - add dependencies from the npm package registry
- **Publishing** - submit apps to the Pebble appstore from the IDE

## Signing in

CloudPebble uses your Pebble account, the same account as the Pebble mobile
app. Click **Log in with your Pebble account** and sign in with Google, GitHub
or Apple. The account is also used for the Developer Connection and for
publishing, so no further sign-in is needed for those.

## Project types

The **Create New Project** dialog offers three project types:

- **Pebble C SDK** - the primary language for Pebble apps and watchfaces. Builds for every platform.
- **JavaScript SDK (beta)** - [Alloy](/guides/alloy/), a JavaScript framework based on the Moddable SDK, with the Piu UI framework for component-based layouts and the Poco renderer for custom graphics. This is the default type. Alloy projects build for Pebble Time 2 (emery) and Pebble Round 2 (gabbro) only; the other platforms are not offered in the project settings.
- **Pebble Package** - a reusable library of C code, JavaScript and resources that other projects can depend on. See the [Pebble Packages guides](/guides/pebble-packages/).

The **Template** list fills a new project with a sample app, an empty project, or one of the SDK demos. JavaScript SDK projects have their own template list.

Project settings such as the app kind, target platforms, UUID, capabilities
and message keys are edited in the **Settings** pane. CloudPebble generates
`package.json` from these settings; the file itself cannot be edited.

## Importing a project

Click **Import** on the project list to bring in an existing project:

- **Upload Zip** - a zip file containing a standard Pebble project with its `package.json` or `appinfo.json`.
- **Import from GitHub** - enter the repository URL and optionally a branch. Public repositories need no GitHub sign-in. Tick **Use as Git remote** to keep the project linked for pull and push, which does need the **GitHub Repo Sync** link in your account settings.

A link of the form `https://cloudpebble.repebble.com/ide/import/github/<user>/<repo>` opens the import dialog prefilled, and `https://cloudpebble.repebble.com/ide/gist/<gist id>` creates a project from a GitHub gist. Use these to share a project from a README.

## Building and running

**Build & Run** in the sidebar compiles the project. Under **Run On**, pick
**Emulator** and one of the seven platforms, or **Phone** to install on a
connected watch through the
[Developer Connection](/guides/tools-and-resources/developer-connection/).
**View app logs** streams the app's log output and **Screenshot** saves an
image of the watch display.

The emulator can run in two places. The **Emulator** option in your account
settings chooses between **In browser (fast, no server)** and **Cloud (server
QEMU)**. The in-browser emulator starts faster and supports all platforms,
screenshots, app logs and the sensor controls. It always uses your computer's
clock, so the time cannot be changed, and audio only plays for emery, flint
and gabbro. The cloud emulator is the default.

## Timeline

The **Timeline (Preview)** pane inserts a timeline pin into the emulator.
Paste the pin JSON, which needs `id`, `time` and `layout`, and click
**Insert pin**. **Delete pin** removes it again. Pins can only be sent to the
emulator, not to a watch. See the
[Pin Structure](/guides/pebble-timeline/pin-structure/) guide for the format.

## Publishing

The **Publish** pane submits a C or JavaScript SDK project to the Pebble
appstore using the most recent successful build. It captures screenshots from
the emulator or accepts uploads, and creates either a new listing or a new
release of an existing app. Read
[Publishing an App](/guides/appstore-publishing/publishing-an-app/) for the
details.

## Getting started

1. Go to [cloudpebble.repebble.com](https://cloudpebble.repebble.com) and sign in
2. Create a new project and choose your project type
3. Write your code and click the compile button to build
4. Test in the built-in emulator, or install on your watch via the [Pebble mobile app](https://repebble.com/app)

## Learn more

- [Build a watchface with JavaScript (Alloy)](/tutorials/alloy-watchface-tutorial/) - step-by-step tutorial
- [Build a watchface with C](/tutorials/watchface-tutorial/) - step-by-step tutorial
- [Example apps](/examples) - browse example projects
- [Alloy guides](/guides/alloy/) - in-depth guides for JavaScript development with Alloy, including Moddable example apps
