# Himalayas Remote Jobs RSS feed — Ruby example.
#
# Docs: https://himalayas.app/docs/remote-jobs-rss
#
# Usage:
#   ruby examples/ruby.rb                  # parse the live feed
#   ruby examples/ruby.rb sample-feed.xml  # parse the bundled sample
#
# Uses only the standard library. No API key or authentication is required.

require 'net/http'
require 'rexml/document'
require 'time'
require 'uri'

FEED_URL = 'https://himalayas.app/jobs/rss'.freeze

# REXML matches namespaced elements by prefix as written in the document, so the
# himalayasJobs: fields are addressed directly by their qualified name.
def load_feed(source = nil)
  xml =
    if source
      File.read(source)
    else
      uri = URI(FEED_URL)
      response = Net::HTTP.get_response(uri, 'User-Agent' => 'himalayas-rss-example/1.0')
      raise "HTTP #{response.code} fetching #{uri}" unless response.is_a?(Net::HTTPSuccess)

      response.body
    end

  REXML::Document.new(xml)
end

# Map one <item> onto a flat hash, including the himalayasJobs: fields.
def parse_item(item)
  {
    title: text_of(item, 'title'),
    # Plain-text excerpt. The full HTML description is in content:encoded.
    excerpt: text_of(item, 'description'),
    description_html: text_of(item, 'content:encoded'),
    url: text_of(item, 'link'),
    # Stable across rebuilds — deduplicate on this.
    guid: text_of(item, 'guid'),
    published: parse_time(text_of(item, 'pubDate')),
    categories: item.get_elements('category').map { |e| e.text.to_s },
    company_name: text_of(item, 'himalayasJobs:companyName'),
    company_logo: item.elements['media:content']&.attributes&.[]('url'),
    # An empty array means the role is open worldwide.
    location_restrictions: item.get_elements('himalayasJobs:locationRestriction').map { |e| e.text.to_s },
    timezone_restrictions: item.get_elements('himalayasJobs:timezoneRestriction').map { |e| e.text.to_s },
    expires: parse_time(text_of(item, 'himalayasJobs:expiryDate'))
  }
end

def text_of(element, path)
  element.elements[path]&.text
end

# RSS dates are RFC 822, e.g. 'Thu, 06 Aug 2026 02:38:22 GMT'.
def parse_time(value)
  value && Time.rfc2822(value)
rescue ArgumentError
  nil
end

document = load_feed(ARGV[0])
channel = document.elements['rss/channel']

puts text_of(channel, 'title')
puts "last built: #{text_of(channel, 'lastBuildDate')}"
# The feed rebuilds every 24 hours and advertises ttl in minutes.
puts "ttl: #{text_of(channel, 'ttl')} minutes\n\n"

jobs = channel.get_elements('item').map { |item| parse_item(item) }
puts "#{jobs.size} jobs in the feed\n\n"

jobs.first(10).each do |job|
  where = job[:location_restrictions].empty? ? 'Worldwide' : job[:location_restrictions].join(', ')
  puts "  #{job[:title]} — #{job[:company_name]}"
  puts "    #{where}"
  puts "    #{job[:url]}"
end

# Only keep jobs that haven't expired yet.
now = Time.now
live = jobs.reject { |job| job[:expires] && job[:expires] <= now }
puts "\n#{live.size} of #{jobs.size} jobs are still open"

# Track guids you've already processed to avoid handling a job twice
# across daily polls.
puts "#{jobs.map { |job| job[:guid] }.uniq.size} unique guids"
