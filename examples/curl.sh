#!/usr/bin/env bash
# Himalayas Remote Jobs RSS feed — curl + xmllint examples
# Docs: https://himalayas.app/docs/remote-jobs-rss
#
# Usage:
#   bash examples/curl.sh                  # fetch and parse the live feed
#   bash examples/curl.sh sample-feed.xml  # parse the bundled sample instead
#
# Requires: curl, xmllint (libxml2 — preinstalled on macOS and most Linux distros)

set -euo pipefail

FEED_URL="https://himalayas.app/jobs/rss"
HIMALAYAS_NS="https://himalayas.app/ns/jobs"

if [[ $# -ge 1 ]]; then
  FEED="$1"
  echo "==> Reading $FEED"
else
  FEED="$(mktemp)"
  trap 'rm -f "$FEED"' EXIT
  echo "==> Fetching $FEED_URL"
  curl -sS -A 'himalayas-rss-example/1.0' "$FEED_URL" -o "$FEED"
fi

echo
echo "==> Feed is well-formed XML"
xmllint --noout "$FEED" && echo "  valid"

echo
echo "==> Feed metadata"
echo "  title: $(xmllint --xpath 'string(/rss/channel/title)' "$FEED")"
echo "  built: $(xmllint --xpath 'string(/rss/channel/lastBuildDate)' "$FEED")"
echo "  ttl:   $(xmllint --xpath 'string(/rss/channel/ttl)' "$FEED") minutes"
echo "  jobs:  $(xmllint --xpath 'count(/rss/channel/item)' "$FEED")"

echo
echo "==> Latest job titles"
# Titles are wrapped in CDATA, which xmllint prints verbatim — strip it.
xmllint --xpath '/rss/channel/item[position() <= 10]/title/text()' "$FEED" \
  | sed 's/<!\[CDATA\[//; s/\]\]>//; s/^/  /'

echo
echo "==> Apply links"
xmllint --xpath '/rss/channel/item[position() <= 5]/link/text()' "$FEED" \
  | sed 's/^/  /'

# Elements in the himalayasJobs: namespace need the prefix bound before you can
# select them. `xmllint --xpath` has no flag for that, so use the shell mode.
echo
echo "==> Hiring companies (himalayasJobs: namespace)"
xmllint --shell "$FEED" <<XMLLINT | sed -n 's/^    content=/  /p'
setns hj=$HIMALAYAS_NS
xpath /rss/channel/item[position() <= 5]/hj:companyName/text()
XMLLINT

echo
echo "==> Location restrictions on the first job (empty means worldwide)"
xmllint --shell "$FEED" <<XMLLINT | sed -n 's/^    content=/  /p'
setns hj=$HIMALAYAS_NS
xpath /rss/channel/item[1]/hj:locationRestriction/text()
XMLLINT
