require 'net/http'
require 'open-uri'
require 'fusefs'
require 'vkontakte'

require 'rubygems'
require 'scrobbler'

module LastFM
  module FUSE

    class Track
      attr_reader :artist, :name
      def initialize(artist, name)
        @artist = artist
        @name = name
      end

      def file_name
        "#{@artist} - #{@name}.mp3"
      end

      def content
        Net::HTTP.get_response(URI.parse(url)).body
      end

      def size
        unless @size
          response = nil
          uri = URI.parse(url)
          Net::HTTP.start(uri.host, uri.port) {|http| response = http.head(uri.path)}
          @size = response.content_length
        end

        @size 
      end

      def url
        @url ||= Vkontakte::Tracker.new.find("#{@artist} - #{@name}")
        @url
      end
    end

    class Dir
      def initialize
        @tracks = {}
        tag = Scrobbler::Tag.new('disco')
        tag.top_tracks[0..50].each do |lastfm_track|
          track = Track.new(lastfm_track.artist, lastfm_track.name)
          @tracks[track.file_name] = track
        end
      end

      def contents(path)
        @tracks.keys
      end

      def file?(path)
        @tracks.has_key?(path.split('/').last)
      end

      def read_file(path)
        @tracks[path.split('/').last].content
      end

      def size(path)
        @tracks[path.split('/').last].size
      end
    end
  end
end

hellodir = LastFM::FUSE::Dir.new
FuseFS.set_root( hellodir )

# Mount under a directory given on the command line.
FuseFS.mount_under ARGV.shift
FuseFS.run

