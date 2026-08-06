# Remote Jobs RSS Feed — free XML feed of the latest remote jobs

[![Feed](https://img.shields.io/badge/feed-100%20latest%20jobs-2563eb)](https://himalayas.app/jobs/rss)
[![Auth](https://img.shields.io/badge/auth-none%20required-16a34a)](https://himalayas.app/rss)
[![Format](https://img.shields.io/badge/format-RSS%202.0%20%2B%20XML-6b21a8)](https://himalayas.app/jobs/rss)
[![JSON API](https://img.shields.io/badge/also-JSON%20API-f97316)](https://github.com/Himalayas-App/remote-jobs-api)

The **Himalayas Remote Jobs RSS feed** publishes the 100 most recent remote and work-from-home job listings as standard RSS 2.0 XML. Subscribe in any feed reader, pipe it into an automation, or use it to backfill a remote job board.

No API key. No sign-up. Just a URL.

```
https://himalayas.app/jobs/rss
```

```bash
curl -sS https://himalayas.app/jobs/rss | xmllint --format - | head -40
```

- **Docs:** https://himalayas.app/docs/remote-jobs-rss
- **Sample feed:** [`sample-feed.xml`](sample-feed.xml) — two real items, trimmed
- **Code examples:** [`examples/`](examples) — curl, Python, Node.js, PHP, Ruby
- **JSON API:** https://github.com/Himalayas-App/remote-jobs-api
- **MCP server:** https://github.com/Himalayas-App/himalayas-mcp

---

## Contents

- [Subscribe in a feed reader](#subscribe-in-a-feed-reader)
- [Feed structure](#feed-structure)
- [Channel fields](#channel-fields)
- [Item fields](#item-fields)
- [The himalayasJobs namespace](#the-himalayasjobs-namespace)
- [Example item](#example-item)
- [Code examples](#code-examples)
- [Automations](#automations)
- [Update frequency and caching](#update-frequency-and-caching)
- [Feed vs API vs MCP](#feed-vs-api-vs-mcp)
- [Attribution and terms of use](#attribution-and-terms-of-use)
- [FAQ](#faq)

---

## Subscribe in a feed reader

Add this URL to any RSS reader — Feedly, Inoreader, NewsBlur, NetNewsWire, Reeder, Thunderbird, or anything else that speaks RSS:

```
https://himalayas.app/jobs/rss
```

New remote jobs appear automatically as they're posted.

---

## Feed structure

Standard RSS 2.0, with a few Himalayas-specific fields in a custom namespace.

```
rss (version 2.0)
└── channel
    ├── title, description, link, image, language, copyright, ttl
    ├── lastBuildDate, pubDate
    ├── atom:link (self)
    ├── himalayasJobs:lastBuildDate
    └── item × 100
        ├── title, description, link, guid, pubDate
        ├── category × n
        ├── content:encoded  (full HTML description)
        ├── media:content    (company logo)
        └── himalayasJobs:companyName, companyLogo,
            locationRestriction × n, timezoneRestriction × n, expiryDate
```

Declared namespaces:

| Prefix | URI |
| --- | --- |
| `content` | `http://purl.org/rss/1.0/modules/content/` |
| `dc` | `http://purl.org/dc/elements/1.1/` |
| `atom` | `http://www.w3.org/2005/Atom` |
| `media` | `http://search.yahoo.com/mrss/` |
| `himalayasJobs` | `https://himalayas.app/ns/jobs` |

Bind the `himalayasJobs` and `media` prefixes to those URIs in your parser to select the custom fields — see [`examples/`](examples) for a working version in five languages.

---

## Channel fields

| Element | Description |
| --- | --- |
| `title` | `Remote jobs from Himalayas` |
| `description` | Feed description |
| `link` | https://himalayas.app/jobs |
| `image` | Feed logo |
| `language` | `en` |
| `copyright` | Himalayas Remote Jobs Pty Ltd |
| `ttl` | `1440` minutes — the feed refreshes daily, so don't poll more often |
| `lastBuildDate` | RFC 822 timestamp of the last rebuild |
| `pubDate` | RFC 822 timestamp of the last data refresh |
| `atom:link` | Self-reference to the feed URL |
| `himalayasJobs:lastBuildDate` | Same as `lastBuildDate`, in the Himalayas namespace |

---

## Item fields

Each `<item>` is one remote job listing.

| Element | Description |
| --- | --- |
| `title` | Job title |
| `description` | Plain-text excerpt — the first few sentences of the job description |
| `link` | URL of the job listing on Himalayas |
| `guid` | Stable unique identifier (`isPermaLink="true"`) — **deduplicate on this** |
| `pubDate` | RFC 822 publication timestamp |
| `category` | Job category — repeated, one element per category |
| `content:encoded` | Full job description as HTML, in a CDATA block |
| `media:content` | Company logo, as `url` + `medium="image"` attributes |

---

## The himalayasJobs namespace

Fields specific to job listings, not covered by standard RSS:

| Element | Repeats | Description |
| --- | --- | --- |
| `himalayasJobs:companyName` | no | Name of the hiring company |
| `himalayasJobs:companyLogo` | no | URL of the company logo |
| `himalayasJobs:locationRestriction` | yes | A country the candidate must be located in |
| `himalayasJobs:timezoneRestriction` | yes | A UTC offset the candidate must be within |
| `himalayasJobs:expiryDate` | no | RFC 822 timestamp when the listing expires |

A job with no `locationRestriction` elements is open worldwide.

> Most RSS libraries expose unknown namespaced elements through a raw-element escape hatch — see [`examples/`](examples) for how to read them in each language. Generic readers will simply ignore them.

---

## Example item

Abbreviated from [`sample-feed.xml`](sample-feed.xml):

```xml
<item>
    <title><![CDATA[Senior React Native Developer]]></title>
    <description><![CDATA[Are you a talented Senior Developer looking for a remote job…]]></description>
    <link>https://himalayas.app/companies/lemon-io/jobs/senior-react-native-developer</link>
    <guid isPermaLink="true">https://himalayas.app/companies/lemon-io/jobs/senior-react-native-developer</guid>
    <category><![CDATA[React-Native-Developer]]></category>
    <category><![CDATA[Senior-React-Native-Engineer]]></category>
    <pubDate>Thu, 06 Aug 2026 02:38:22 GMT</pubDate>
    <media:content url="https://cdn-images.himalayas.app/hcc9f71g0twhi03ly6463ehgjpeb" medium="image"/>
    <himalayasJobs:companyName>lemon.io</himalayasJobs:companyName>
    <himalayasJobs:companyLogo>https://cdn-images.himalayas.app/hcc9f71g0twhi03ly6463ehgjpeb</himalayasJobs:companyLogo>
    <himalayasJobs:locationRestriction>United States</himalayasJobs:locationRestriction>
    <himalayasJobs:locationRestriction>Canada</himalayasJobs:locationRestriction>
    <himalayasJobs:timezoneRestriction>-5</himalayasJobs:timezoneRestriction>
    <content:encoded><![CDATA[<p>Are you a talented Senior Developer…</p>]]></content:encoded>
    <himalayasJobs:expiryDate>Sat, 05 Sep 2026 02:38:21 GMT</himalayasJobs:expiryDate>
</item>
```

---

## Code examples

Runnable scripts live in [`examples/`](examples). Each parses the feed and prints the latest jobs, including the custom `himalayasJobs:` fields.

| Language | File | Run |
| --- | --- | --- |
| curl / shell | [`examples/curl.sh`](examples/curl.sh) | `bash examples/curl.sh` |
| Python | [`examples/python.py`](examples/python.py) | `python3 examples/python.py` |
| Node.js | [`examples/node.js`](examples/node.js) | `node examples/node.js` |
| PHP | [`examples/php.php`](examples/php.php) | `php examples/php.php` |
| Ruby | [`examples/ruby.rb`](examples/ruby.rb) | `ruby examples/ruby.rb` |

### Python

```python
import xml.etree.ElementTree as ET
import urllib.request

NS = {
    "himalayasJobs": "https://himalayas.app/ns/jobs",
    "media": "http://search.yahoo.com/mrss/",
    "content": "http://purl.org/rss/1.0/modules/content/",
}

with urllib.request.urlopen("https://himalayas.app/jobs/rss") as response:
    root = ET.fromstring(response.read())

for item in root.findall("./channel/item"):
    title = item.findtext("title")
    company = item.findtext("himalayasJobs:companyName", namespaces=NS)
    countries = [el.text for el in item.findall("himalayasJobs:locationRestriction", NS)]
    print(f"{title} — {company} ({', '.join(countries) or 'Worldwide'})")
```

### Node.js

```js
import Parser from 'rss-parser';

const parser = new Parser({
  customFields: {
    item: [
      ['himalayasJobs:companyName', 'companyName'],
      ['himalayasJobs:locationRestriction', 'locationRestrictions', { keepArray: true }],
    ],
  },
});

const feed = await parser.parseURL('https://himalayas.app/jobs/rss');
for (const item of feed.items) {
  console.log(`${item.title} — ${item.companyName}`);
}
```

---

## Automations

The feed works anywhere RSS does, with no code:

- **Slack** — `/feed subscribe https://himalayas.app/jobs/rss` posts new jobs into a channel.
- **Zapier / Make / n8n** — use the "New Item in Feed" RSS trigger to route jobs into a spreadsheet, database, or CRM.
- **IFTTT** — the RSS trigger can email, tweet, or push a notification for each new job.
- **Discord** — most RSS bots accept the feed URL directly.

Since the feed rebuilds once a day, set any polling interval to daily. Anything faster just burns quota.

---

## Update frequency and caching

The feed is cached and rebuilt **every 24 hours**, and it advertises `<ttl>1440</ttl>` (minutes) to say so. Polling more often returns identical bytes.

If you need faster or more granular access:

- The [JSON API](https://github.com/Himalayas-App/remote-jobs-api) has the same 24-hour cache but supports pagination and filtering.
- The [MCP server](https://github.com/Himalayas-App/himalayas-mcp) queries live data in real time.

---

## Feed vs API vs MCP

| | RSS feed | JSON API | MCP server |
| --- | --- | --- | --- |
| **Format** | RSS 2.0 XML | JSON | MCP tools |
| **Coverage** | Latest 100 jobs | All 95,000+ jobs | All jobs |
| **Pagination** | No | Yes (20 per request) | Yes |
| **Filtering** | No | Keyword, country, seniority, employment type, company, timezone | Yes, plus companies, salaries, applications |
| **Freshness** | Every 24 hours | Every 24 hours | Real time |
| **Auth** | None | None | None |
| **Best for** | Feed readers, monitoring, no-code automations | Apps, databases, backfilling a job board | AI assistants — Claude, ChatGPT, Cursor, Windsurf |

There's also an [embeddable widget](https://himalayas.app/free-remote-jobs-widget) if you just want live listings on a web page.

---

## Attribution and terms of use

The feed is free to use, including commercially. In return we ask that you:

- **Link back** to the job's URL on [himalayas.app](https://himalayas.app) — use the item's `link` or `guid`.
- **Credit Himalayas** as the source of the data wherever you display it.
- **Do not resubmit** Himalayas listings to third-party job aggregators, including but not limited to Jooble, Neuvoo, Google Jobs, and LinkedIn Jobs.

The example code in this repository is MIT licensed — see [LICENSE](LICENSE). The job data itself is provided under the attribution terms above.

---

## FAQ

### What is the Himalayas RSS feed URL?

`https://himalayas.app/jobs/rss` — paste it into any feed reader.

### Is the RSS feed free?

Yes, including for commercial use, subject to the [attribution requirements](#attribution-and-terms-of-use). No API key or sign-up.

### How many jobs are in the feed?

The 100 most recently published remote jobs. As new jobs are posted, older ones drop out. For the full catalogue of 95,000+ jobs, use the [JSON API](https://github.com/Himalayas-App/remote-jobs-api).

### How often does the feed update?

Every 24 hours. The feed advertises `ttl=1440` minutes — configure your reader or automation to match.

### Can I filter the feed by category, keyword, or location?

Not currently. The feed returns the latest 100 jobs unfiltered. For filtered results, use the [JSON API](https://github.com/Himalayas-App/remote-jobs-api) — it supports keyword, country, seniority, employment type, company, and timezone filters — or the [MCP server](https://github.com/Himalayas-App/himalayas-mcp).

### Is there a JSON Feed version?

Not yet. For structured JSON, use the [JSON API](https://github.com/Himalayas-App/remote-jobs-api).

### What format is the feed — RSS or Atom?

The body is RSS 2.0 with an `atom:link` self-reference. Note that the response is served with a `Content-Type` of `application/atom+xml`; the document itself is `<rss version="2.0">`. Feed readers handle this fine, but if you're validating strictly, parse it as RSS 2.0.

### How do I read the himalayasJobs fields in my RSS library?

Most libraries have a hook for custom or unknown elements — `customFields` in `rss-parser`, raw XML access in `feedparser`, `SimpleXMLElement::children()` in PHP. See [`examples/`](examples) for a working version in each language.

### How do I avoid processing the same job twice?

Deduplicate on `guid`. It's stable across rebuilds and doubles as the job's canonical URL.

### Does a job with no location restrictions mean it's worldwide?

Yes. If an item has no `himalayasJobs:locationRestriction` elements, the role is open to candidates anywhere.

### What is the difference between the RSS feed and the JSON API?

Format and coverage. The RSS feed is XML and carries the latest 100 jobs with no pagination or filtering. The [JSON API](https://github.com/Himalayas-App/remote-jobs-api) is JSON and covers every job with pagination and filters. Both are free, unauthenticated, and refresh every 24 hours.

### Can I use the feed to backfill my own job board?

Yes — that's one of the main use cases. Link back to the original listing on Himalayas and credit Himalayas as the source.

---

## Support

- **Documentation:** https://himalayas.app/docs/remote-jobs-rss
- **Issues and questions:** [open an issue](https://github.com/Himalayas-App/remote-jobs-rss-feed/issues)
- **Email:** [hi@himalayas.app](mailto:hi@himalayas.app)

Built by [Himalayas](https://himalayas.app) — the remote job board with 95,000+ open remote jobs.
