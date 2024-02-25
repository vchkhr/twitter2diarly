require 'time'
require 'json'
require 'csv'

class InvalidFileFormatError < StandardError; end

def read_config
  config = File.read('config.json')

  begin
    JSON.parse(config)
  rescue JSON::ParserError
    raise InvalidFileFormatError,
    'Invalid config file. Pull the repository to fix it.'
  end
end

def read_tweets_file
  unless File.exist?(CONFIG['tweets_file'])
    raise InvalidFileFormatError,
      "File not found: #{CONFIG['tweets_file']}.
        Read the README.md for instructions on how to
        download your Twitter archive."
  end

  tweets = File.read(CONFIG['tweets_file'])

  unless tweets.start_with?(CONFIG['tweets_file_prefix_to_remove'])
    raise InvalidFileFormatError,
    'Invalid file format. First 100 characters: ' + tweets[0..100]
  end

  begin
    JSON.parse(tweets.split(CONFIG['tweets_file_prefix_to_remove'])[1])
  rescue JSON::ParserError
    raise InvalidFileFormatError,
    'Invalid JSON format. First 100 characters: ' + tweets[0..100]
  end
end

def parse_tweets(tweets)
  tweets_config = CONFIG['tweets']
  tweets_parsed = {}

  tweets.each do |tweet|
    tweet = tweet['tweet']
    text = tweet['full_text'].strip

    next if !tweets_config['with_mentions'] && text.include?('@')
    next if !tweets_config['with_mentions_at_start'] && text[0] == '@'
    next if !tweets_config['retweets'] && text.start_with?('RT @')

    media = tweet.fetch('extended_entities', {}).fetch('media', [])
    if media.any?
      next unless tweets_config['with_media']

      if tweets_config['keep_media']
        media.each do |m|
          if m.key?('video_info')
            text << "\n![Video](#{m['video_info']['variants'].last['url']})"
          else
            text << "\n![Photo](#{m['media_url_https']})"
          end
        end
      end
    end

    date = Date.parse(tweet['created_at']).strftime('%d.%m.%Y')
    time = Time.parse(tweet['created_at']).strftime('%R')

    tweets_parsed[date] = {} unless tweets_parsed.key?(date)
    tweets_parsed[date][time] = text
  end

  tweets_parsed
end

def format_results(tweets)
  tweets.map do |date, entries|
    [
      date,
      entries.sort.map { |time, text| "********\n*#{time}*\n\n#{text}" }
        .join("\n\n")
    ]
  end
end

def export_to_csv(tweets)
  CSV.open(CONFIG['result_file'], 'w') do |csv|
    tweets.each do |row|
      csv << [row[0], row[1].gsub('          ', '')]
    end
  end
end

print "Start converting tweets.\n\n"

CONFIG = read_config
tweets = read_tweets_file
tweets_parsed = parse_tweets(tweets)
tweets_formatted = format_results(tweets_parsed)
export_to_csv(tweets_formatted)

print "Finished converting tweets.
  Results are in the #{CONFIG['result_file']} file.
  Now import them into the Diarly app by following the instructions in the
  README.md file.\n"
