require 'rubygems'
require 'scrobbler'
require 'vkontakte'


system "mkdir result"

tag = Scrobbler::Tag.new('blues rock')
tag.top_tracks[0..50].each do |track|
  tracker = Vkontakte::Tracker.new
  track_url = tracker.find("#{track.artist} - #{track.name}")
  system "aria2c #{track_url} -o result/#{Regexp.escape("#{track.artist} - #{track.name}.mp3")}"
end
