#!/usr/bin/env sh
# Feeds a built page to lychee with every <script> element reduced to a link
# to its src (or removed when it is inline). lychee's HTML extractor stops at
# the inline Rollbar snippet in <head>, so without this it sees no link in
# <body>. Script src URLs stay checkable.
exec perl -0pe 's#<script\b([^>]*)>.*?</script>#my $a = $1; $a =~ /\bsrc=(["\x27])(.*?)\1/ ? qq{<a href="$2"></a>} : ""#gse' "$1"
