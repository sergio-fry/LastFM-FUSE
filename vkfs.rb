require 'net/http'
require 'open-uri'
require 'fusefs'
require 'fileutils'
require 'vkontakte'

require 'rubygems'
require 'scrobbler'
require 'rubygems'
require 'dm-more'

module LastFM
  module FUSE

    class Tag
      include DataMapper::Resource

      property :id,         Serial
      property :name,      String, :required => true, :unique => true

      has n, :tracks

      def load_tracks
        number = 0
        Scrobbler::Tag.new(name).top_tracks[0..20].each do |lastfm_track|
          number = number + 1
          Thread.new do
            track = Track.new(:tag_id => id, :artist => lastfm_track.artist, :name => lastfm_track.name, :file_name => "%02d. #{lastfm_track.artist} - #{lastfm_track.name}.mp3" % number)
            track.save
            track.load rescue track.destroy!
          end
        end
      end
    end

    class Track
      include DataMapper::Resource

      property :id,         Serial
      property :artist,      String, :required => true
      property :name,      String, :required => true
      property :file_name,      String, :required => true
      property :loaded,      Boolean, :default => false
      belongs_to :tag

      before :destroy do
        File.delete("#{Dir.data_path}/tracks/#{id}")
      end

      def content
        IO.read("#{Dir.data_path}/tracks/#{id}")
      end

      def size
        if loaded && File.file?("#{Dir.data_path}/tracks/#{id}")
          File.size("#{Dir.data_path}/tracks/#{id}")
        else
          0
        end
      end

      def url
        @url ||= Vkontakte::Tracker.new.find("#{artist} - #{name}")
        @url
      end

      def load
        f = File.new("#{Dir.data_path}/tracks/#{id}", "w")
        f.write(Net::HTTP.get_response(URI.parse(url)).body)
        self.loaded = true
        save
      end

    end

    
    class Dir
      def initialize params = {}
        @@data_path = File.expand_path(params[:data_path])
        FileUtils.mkdir_p(@@data_path)
        FileUtils.mkdir_p(@@data_path + "/tracks")
        @@database_path = @@data_path + "/database.sqlite3"

        DataMapper::Logger.new($stdout, :debug)
        DataMapper.setup(:default, "sqlite3:#{@@database_path}")


        unless File.file? @@database_path
          Tag.auto_migrate!
          Track.auto_migrate!
        end
      end

      def self.data_path
        @@data_path
      end

      def contents(path)
        parts = path.split('/')
        parts.shift
        case parts[0]
        when 'Artists'
          [] if parts.size == 1
        when 'Tags'
          if parts.size == 1
            Tag.all.map(&:name)
          elsif parts.size == 2
            Tag.first(:name => parts[1]).tracks.all(:loaded => true).map(&:file_name)
          else
            []
          end
        when nil
          ['Tags', 'Artists']
        else
          []
        end
      end

      def directory?(path)
        parts = path.split('/')
        parts.shift
        case parts[0]
        when 'Artists'
          if parts.size == 1
            true
          else
            false
          end
        when 'Tags'
          if parts.size == 1
            true
          elsif parts.size == 2
            p "DDDDDDDDDDDDDDDDDDDDDD"
            #!Tag.find(:name => parts[1]).nil?
            true
          else
            false
          end
        else
          false
        end
      end

      def file?(path)
        parts = path.split('/')
        parts.shift
        case parts[0]
        when 'Artists'
          false
        when 'Tags'
          if parts.size == 3
            Tag.first(:name => parts[1]).tracks.all(:loaded => true).map(&:file_name).include?(parts[2])
          else
            false
          end
        else
          false
        end
      end

      def read_file(path)
        parts = path.split('/')
        parts.shift
        case parts[0]
        when 'Tags'
          if parts.size == 3
            Tag.first(:name => parts[1]).tracks.first(:file_name => parts[2]).content
          else
            ''
          end
        else
          ''
        end
      end

      def size(path)
        parts = path.split('/')
        parts.shift
        case parts[0]
        when 'Tags'
          if parts.size == 3
            Tag.first(:name => parts[1]).tracks.first(:file_name => parts[2]).size
          else
            0
          end
        else
          0
        end
      end

      def can_mkdir?(path)
        parts = path.split('/')
        parts.shift
        case parts[0]
        when 'Tags'
          true if parts.size == 2
        else
          false
        end
      end

      def can_rmdir?(path)
        parts = path.split('/')
        parts.shift
        case parts[0]
        when 'Tags'
          true if parts.size == 2
        else
          false
        end
      end


      def rmdir(path)
        parts = path.split('/')
        parts.shift
        case parts[0]
        when 'Tags'
          tag = Tag.first(:name => parts[1])
          tag.tracks.each{|t| t.destroy}
          tag.destroy
        else
        end
      end

      def mkdir(path)
        parts = path.split('/')
        parts.shift
        case parts[0]
        when 'Tags'
          tag = Tag.new(:name => parts[1])
          if tag.save
            Thread.abort_on_exception = true
            Thread.new do
              tag.load_tracks
              tag.save
            end
          end
        else
        end
      end
    end
  end
end

hellodir = LastFM::FUSE::Dir.new(:data_path => "/tmp/lastfm")
FuseFS.set_root( hellodir )

# Mount under a directory given on the command line.
FuseFS.mount_under ARGV.shift
FuseFS.run

