require 'time'
require 'json'
require 'csv'

class InvalidFileFormatError < StandardError; end

CONFIG = {
  tweets: {
    with_mentions: true,
    with_mentions_at_start: false,
    retweets: false,
    with_media: true,
    skip_media: false
  },
  result_file: 'result.csv',
  tweets_file: 'archive/data/tweets.js',
  tweets_file_prefix_to_remove: 'window.YTD.tweets.part0 = '
}

def read_tweets_file
  unless File.exist?(CONFIG[:tweets_file])
    raise InvalidFileFormatError,
      "File not found: #{CONFIG[:tweets_file]}.
        Read the README.md for instructions on how to download your Twitter archive."
  end

  tweets = File.read(CONFIG[:tweets_file])

  unless tweets.start_with?(CONFIG[:tweets_file_prefix_to_remove])
    raise InvalidFileFormatError,
    'Invalid file format. First 100 characters: ' + tweets[0..100]
  end

  begin
    JSON.parse(tweets.split(CONFIG[:tweets_file_prefix_to_remove])[1])
  rescue JSON::ParserError
    raise InvalidFileFormatError,
    'Invalid JSON format. First 100 characters: ' + tweets[0..100]
  end
end

def parse_tweets(tweets)
  tweets_config = CONFIG[:tweets]
  tweets_parsed = {}

  tweets.each do |tweet|
    text = tweet['tweet']['full_text'].strip
    next if !tweets_config[:with_mentions] && text.include?('@')
    next if !tweets_config[:with_mentions_at_start] && text[0] == '@'
    next if !tweets_config[:retweets] && text.start_with?('RT @')

    media = tweet['tweet']['entities']['media'] || []
    if media.any?
      next unless tweets_config[:with_media]

      unless tweets_config[:skip_media]
        media.each do |m|
          text << "\n![#{m['media_url_https']}](#{m['media_url_https']})"
        end
      end
    end

    date = Date.parse(tweet['tweet']['created_at']).strftime('%d.%m.%Y')
    time = Time.parse(tweet['tweet']['created_at']).strftime('%R')

    tweets_parsed[date] = {} unless tweets_parsed.key?(date)
    tweets_parsed[date][time] = text
  end

  tweets_parsed
end

def format_results(tweets)
  tweets.map do |date, entries|
    [
      date,
      entries.map { |time, text| "********\n*#{time}*\n\n#{text}" }.join("\n\n")
    ]
  end
end

def export_to_csv(tweets)
  CSV.open(CONFIG[:result_file], 'w') do |csv|
    tweets.each do |row|
      csv << [row[0], row[1].gsub('          ', '')]
    end
  end
end

print "Start converting tweets.\n\n"

tweets = read_tweets_file
tweets_parsed = parse_tweets(tweets)
tweets_formatted = format_results(tweets_parsed)
export_to_csv(tweets_formatted)

print "Finished converting tweets.
  Results are in #{CONFIG[:result_file]}.
  Now import them into the Diarly app.\n"
