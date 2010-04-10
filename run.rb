require 'rubygems'
require 'scrobbler'
require 'vkontakte'


system "mkdir result"

tag = Scrobbler::Tag.new('bachata')
tag.top_tracks[0..5].each do |track|
  tracker = Vkontakte::Tracker.new
  track_url = tracker.find("#{track.artist} - #{track.name}") rescue ""
  system "aria2c #{track_url} -c -o result/#{Regexp.escape("#{track.artist} - #{track.name}.mp3")}"
end
