require 'URI'

module Wordstress
  class Utils

    # Transform a given URL into a directory name to be used to store data
    def self.target_to_dirname(target)
      uri = URI.parse(target)
      path = uri.request_uri.split('/')
      blog_path = ""
      blog_path = "_#{path[1]}" if path.count >= 2
      return "#{uri.host}_#{uri.port}#{blog_path}"
    end

    def self.build_output_dir(root, target)
      attempt=0
      today=Time.now.strftime("%Y%m%d")

      while 1 do

        proposed = File.join(root, Wordstress::Utils.target_to_dirname(target), today)
        if attempt != 0
          proposed += "_#{attempt}"
        end

        return proposed unless Dir.exists?(proposed)
        attempt +=1 if Dir.exists?(proposed)
      end


    end

  end
end
