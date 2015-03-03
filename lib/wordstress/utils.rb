module Wordstress
  class Utils

    def self.url_to_target(url)
      uri = URI.parse(url)
      "#{uri.scheme}://#{uri.host}#{uri.request_uri.gsub("/wordstress", "")}" if uri.port == 80
      "#{uri.scheme}://#{uri.host}:#{uri.port}#{uri.request_uri.gsub("/wordstress", "")}" unless uri.port == 80
    end
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
