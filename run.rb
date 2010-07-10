require 'rubygems'
require 'scrobbler'
require 'vkontakte'

tag_name = ARGV[0]

system "mkdir -p #{tag_name}"

tag = Scrobbler::Tag.new(tag_name)
i = 0
tag.top_tracks[0..49].each do |track|
  i = i + 1
  tracker = Vkontakte::Tracker.new
  track_url = tracker.find("#{track.artist} - #{track.name}" % i) rescue ""

  Thread.new do
    system "aria2c #{track_url} -c -o #{tag_name}/#{Regexp.escape("%03d. #{track.artist} - #{track.name}.mp3" % i)}"
  end
end
