/**
 * Himalayas Remote Jobs RSS feed — Node.js example.
 *
 * Docs: https://himalayas.app/docs/remote-jobs-rss
 *
 * Usage:
 *   npm install rss-parser
 *   node examples/node.js                  # parse the live feed
 *   node examples/node.js sample-feed.xml  # parse the bundled sample
 *
 * Requires Node 18+ for the built-in fetch. No API key or authentication needed.
 */

const fs = require('node:fs/promises');
const Parser = require('rss-parser');

const FEED_URL = 'https://himalayas.app/jobs/rss';

// rss-parser passes unknown elements through under their literal tag name, so
// the himalayasJobs: fields are mapped here. `keepArray` matters for the
// restriction fields, which repeat once per country or timezone.
const parser = new Parser({
  customFields: {
    feed: [['himalayasJobs:lastBuildDate', 'himalayasLastBuildDate']],
    item: [
      ['himalayasJobs:companyName', 'companyName'],
      ['himalayasJobs:companyLogo', 'companyLogo'],
      ['himalayasJobs:locationRestriction', 'locationRestrictions', { keepArray: true }],
      ['himalayasJobs:timezoneRestriction', 'timezoneRestrictions', { keepArray: true }],
      ['himalayasJobs:expiryDate', 'expiryDate'],
      ['media:content', 'media'],
    ],
  },
});

async function loadFeed(source) {
  if (source) {
    return parser.parseString(await fs.readFile(source, 'utf8'));
  }

  const response = await fetch(FEED_URL, {
    headers: { 'User-Agent': 'himalayas-rss-example/1.0' },
  });
  if (!response.ok) throw new Error(`HTTP ${response.status} fetching ${FEED_URL}`);
  return parser.parseString(await response.text());
}

/** Normalize one item into a flat job object. */
function toJob(item) {
  return {
    title: item.title,
    // Plain-text excerpt. The full HTML description is in content:encoded,
    // which rss-parser exposes as `content`.
    excerpt: item.contentSnippet ?? item.summary,
    descriptionHtml: item['content:encoded'] ?? item.content,
    url: item.link,
    // Stable across rebuilds — deduplicate on this.
    guid: item.guid,
    published: item.isoDate ? new Date(item.isoDate) : null,
    categories: item.categories ?? [],
    companyName: item.companyName,
    companyLogo: item.companyLogo,
    // An empty array means the role is open worldwide.
    locationRestrictions: item.locationRestrictions ?? [],
    timezoneRestrictions: item.timezoneRestrictions ?? [],
    expires: item.expiryDate ? new Date(item.expiryDate) : null,
  };
}

async function main() {
  const feed = await loadFeed(process.argv[2]);

  console.log(feed.title);
  console.log(`last built: ${feed.lastBuildDate}`);
  // The feed rebuilds every 24 hours and advertises ttl in minutes.
  console.log(`ttl: ${feed.ttl} minutes\n`);

  const jobs = feed.items.map(toJob);
  console.log(`${jobs.length} jobs in the feed\n`);

  for (const job of jobs.slice(0, 10)) {
    const where = job.locationRestrictions.join(', ') || 'Worldwide';
    console.log(`  ${job.title} — ${job.companyName}`);
    console.log(`    ${where}`);
    console.log(`    ${job.url}`);
  }

  // Only keep jobs that haven't expired yet.
  const now = new Date();
  const live = jobs.filter((job) => !job.expires || job.expires > now);
  console.log(`\n${live.length} of ${jobs.length} jobs are still open`);

  // Track guids you've already processed to avoid handling a job twice
  // across daily polls.
  const seen = new Set(jobs.map((job) => job.guid));
  console.log(`${seen.size} unique guids`);
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
