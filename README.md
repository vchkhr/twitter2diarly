# twitter2diarly

Import Twitter (X) Archive to the Diarly app.

The script converts the Twitter archive to a CSV file for
importing into the Diarly app.

It also skips retweets and mentions, and groups tweets with the same date,
separating them with a standard time block from the Diarly app.

# Requirements

Ruby 2.7.7 or higher is required to run this script.

The code is tested on macOS with ruby-2.7.7 [ arm64 ]

# Steps to follow

By default, the script will ignore tweets that start with mentions and retweets.
To change this behavior, follow the "Settings" section.

Note: Skip steps 1-4 if you already downloaded the .zip archive from Twitter.

1. Open Twitter, select "Settings", "Your account", and
"Download an archive of your data".

2. Press "Download archive".
Verify identity with email or text message.

3. Press "Request archive".
Twitter with email you when the archive will be ready.

4. When the archive is ready, press "Download archive".

5. Unzip the archive and move its content to the `archive` folder in this
project, so you will have the following structure:

```
archive
  assets
  data
  Your archive.html
convert.rb
README.md
```

6. Run the script with `ruby convert.rb`.

7. If everything is correct, the `result.csv` file will be generated.

8. Open Diarly app, go to "File", "Import" and "CSV".
Select the generated `result.csv` file in this project folder.

9. Click "Import". If you don't see all tweets imported in the app
after a few seconds, restart the Diarly app.

# Settings

After updating the settings re-run the script with `ruby convert.rb`.

## Do not skip tweets that start with mentions

To not skip your tweets that start with `@`,
update the `skip_mentions` line in the `convert.rb` to:

```ruby
skip_mentions: false,
```

## Do not skip retweets

To not skip retweets, update the `skip_retweets` line in the `convert.rb` to:

```ruby
skip_retweets: false,
```
