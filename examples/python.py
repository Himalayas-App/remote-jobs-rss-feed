"""Himalayas Remote Jobs RSS feed — Python example.

Docs: https://himalayas.app/docs/remote-jobs-rss

Usage:
    python3 examples/python.py            # parse the live feed
    python3 examples/python.py sample-feed.xml   # parse the bundled sample

Uses only the standard library. No API key or authentication is required.
"""

import sys
import urllib.request
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from email.utils import parsedate_to_datetime

FEED_URL = "https://himalayas.app/jobs/rss"

# Namespaces declared on the feed's root <rss> element.
NS = {
    "himalayasJobs": "https://himalayas.app/ns/jobs",
    "media": "http://search.yahoo.com/mrss/",
    "content": "http://purl.org/rss/1.0/modules/content/",
    "atom": "http://www.w3.org/2005/Atom",
}


def load_feed(source: str | None = None) -> ET.Element:
    """Parse the feed from a local path, or fetch it from himalayas.app."""
    if source:
        return ET.parse(source).getroot()

    request = urllib.request.Request(
        FEED_URL, headers={"User-Agent": "himalayas-rss-example/1.0"}
    )
    with urllib.request.urlopen(request, timeout=30) as response:
        return ET.fromstring(response.read())


def parse_item(item: ET.Element) -> dict:
    """Map one <item> onto a flat dict, including the himalayasJobs: fields."""
    logo = item.find("media:content", NS)

    return {
        "title": item.findtext("title"),
        # Plain-text excerpt. The full HTML description is in content:encoded.
        "excerpt": item.findtext("description"),
        "url": item.findtext("link"),
        # Stable across rebuilds — deduplicate on this.
        "guid": item.findtext("guid"),
        "published": parse_date(item.findtext("pubDate")),
        "categories": [el.text for el in item.findall("category")],
        "description_html": item.findtext("content:encoded", namespaces=NS),
        "company_name": item.findtext("himalayasJobs:companyName", namespaces=NS),
        "company_logo": logo.get("url") if logo is not None else None,
        # Empty list means the role is open worldwide.
        "location_restrictions": [
            el.text for el in item.findall("himalayasJobs:locationRestriction", NS)
        ],
        "timezone_restrictions": [
            el.text for el in item.findall("himalayasJobs:timezoneRestriction", NS)
        ],
        "expires": parse_date(item.findtext("himalayasJobs:expiryDate", namespaces=NS)),
    }


def parse_date(value: str | None) -> datetime | None:
    """RSS dates are RFC 822, e.g. 'Thu, 06 Aug 2026 02:38:22 GMT'."""
    return parsedate_to_datetime(value) if value else None


if __name__ == "__main__":
    root = load_feed(sys.argv[1] if len(sys.argv) > 1 else None)
    channel = root.find("channel")

    built = parse_date(channel.findtext("lastBuildDate"))
    print(f"{channel.findtext('title')}")
    print(f"last built: {built}")
    # The feed rebuilds every 24 hours and advertises ttl in minutes.
    print(f"ttl: {channel.findtext('ttl')} minutes\n")

    jobs = [parse_item(item) for item in channel.findall("item")]
    print(f"{len(jobs)} jobs in the feed\n")

    for job in jobs[:10]:
        where = ", ".join(job["location_restrictions"]) or "Worldwide"
        print(f"  {job['title']} — {job['company_name']}")
        print(f"    {where}")
        print(f"    {job['url']}")

    # Only keep jobs that haven't expired yet.
    now = datetime.now(timezone.utc)
    live = [job for job in jobs if job["expires"] is None or job["expires"] > now]
    print(f"\n{len(live)} of {len(jobs)} jobs are still open")

    # Track guids you've already processed to avoid handling a job twice
    # across daily polls.
    seen = {job["guid"] for job in jobs}
    print(f"{len(seen)} unique guids")
