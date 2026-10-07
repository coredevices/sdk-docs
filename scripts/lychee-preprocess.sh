#!/usr/bin/env sh
# Feeds a built page to lychee without its <script> blocks. lychee's HTML
# extractor stops at the inline Rollbar snippet in <head>, so without this it
# sees no link in <body>. Script URLs are not checked as a result.
exec perl -0pe 's#<script\b[^>]*>.*?</script>##gs' "$1"
