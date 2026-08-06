<?php
/**
 * Himalayas Remote Jobs RSS feed — PHP example.
 *
 * Docs: https://himalayas.app/docs/remote-jobs-rss
 *
 * Usage:
 *   php examples/php.php                  # parse the live feed
 *   php examples/php.php sample-feed.xml  # parse the bundled sample
 *
 * Requires the simplexml extension. No API key or authentication needed.
 */

const FEED_URL = 'https://himalayas.app/jobs/rss';
const HIMALAYAS_NS = 'https://himalayas.app/ns/jobs';
const MEDIA_NS = 'http://search.yahoo.com/mrss/';
const CONTENT_NS = 'http://purl.org/rss/1.0/modules/content/';

function load_feed(?string $source): SimpleXMLElement
{
    if ($source !== null) {
        $xml = file_get_contents($source);
    } else {
        $context = stream_context_create([
            'http' => ['header' => "User-Agent: himalayas-rss-example/1.0\r\n", 'timeout' => 30],
        ]);
        $xml = file_get_contents(FEED_URL, false, $context);
    }

    if ($xml === false) {
        throw new RuntimeException('Could not read the feed');
    }

    $feed = simplexml_load_string($xml);
    if ($feed === false) {
        throw new RuntimeException('Feed is not well-formed XML');
    }

    return $feed;
}

/** Map one <item> onto a flat array, including the himalayasJobs: fields. */
function parse_item(SimpleXMLElement $item): array
{
    $himalayas = $item->children(HIMALAYAS_NS);
    $media = $item->children(MEDIA_NS);
    $content = $item->children(CONTENT_NS);

    $logo = null;
    if (isset($media->content)) {
        $logo = (string) $media->content->attributes()['url'];
    }

    return [
        'title' => (string) $item->title,
        // Plain-text excerpt. The full HTML description is in content:encoded.
        'excerpt' => (string) $item->description,
        'description_html' => isset($content->encoded) ? (string) $content->encoded : null,
        'url' => (string) $item->link,
        // Stable across rebuilds — deduplicate on this.
        'guid' => (string) $item->guid,
        'published' => strtotime((string) $item->pubDate) ?: null,
        'categories' => array_map('strval', iterator_to_array($item->category, false)),
        'company_name' => (string) $himalayas->companyName,
        'company_logo' => $logo,
        // An empty array means the role is open worldwide.
        'location_restrictions' => array_map(
            'strval',
            iterator_to_array($himalayas->locationRestriction, false)
        ),
        'timezone_restrictions' => array_map(
            'strval',
            iterator_to_array($himalayas->timezoneRestriction, false)
        ),
        'expires' => strtotime((string) $himalayas->expiryDate) ?: null,
    ];
}

$feed = load_feed($argv[1] ?? null);
$channel = $feed->channel;

printf("%s\n", (string) $channel->title);
printf("last built: %s\n", (string) $channel->lastBuildDate);
// The feed rebuilds every 24 hours and advertises ttl in minutes.
printf("ttl: %s minutes\n\n", (string) $channel->ttl);

$jobs = array_map('parse_item', iterator_to_array($channel->item, false));
printf("%d jobs in the feed\n\n", count($jobs));

foreach (array_slice($jobs, 0, 10) as $job) {
    $where = implode(', ', $job['location_restrictions']) ?: 'Worldwide';
    printf("  %s — %s\n", $job['title'], $job['company_name']);
    printf("    %s\n", $where);
    printf("    %s\n", $job['url']);
}

// Only keep jobs that haven't expired yet.
$now = time();
$live = array_filter($jobs, fn (array $job) => $job['expires'] === null || $job['expires'] > $now);
printf("\n%d of %d jobs are still open\n", count($live), count($jobs));

// Track guids you've already processed to avoid handling a job twice
// across daily polls.
$seen = array_unique(array_column($jobs, 'guid'));
printf("%d unique guids\n", count($seen));
