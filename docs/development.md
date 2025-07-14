# Pebble Developer Site &middot; Development Guide

## Handlebars Templates

In order to reduce the size of the JS of the site, we are now pre-compiling
the Handlebars templates and just using the runtime Handlebars library.

If you change, add or remove from the templates, you just recompile them
into the file at `/source/assets/js/templates.js`.

There is a bash script at `/scripts/update-templates.sh` that you can use to
generate this file.
