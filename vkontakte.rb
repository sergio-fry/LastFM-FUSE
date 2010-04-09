require 'net/http'
require 'open-uri'
require 'digest/md5'

require 'rubygems'
require 'hpricot'

module Vkontakte
  class Tracker
    def initialize
      @app_id = 1850196
      @secret_key = 'nk0n6I6vjQ'
      @user_id = 76347967
    end


    def find q
      path = "http://api.vk.com/api.php?api_id=%s&count=200&v=2.0&method=audio.search&sig=%s&test_mode=1&q=%s" % [@app_id, make_sig('audio.search', q), URI.escape(q)]

      doc = open(path) { |f| Hpricot(f) }
      mp3_url = (doc/:response/:audio/:url).first.inner_text
      mp3_url
    end

    private
    def make_sig(method, query)
      str = "%sapi_id=%scount=200method=%sq=%stest_mode=1v=2.0%s" % [@user_id, @app_id, method, query, @secret_key]
      Digest::MD5.hexdigest(str)
    end

  end
end
