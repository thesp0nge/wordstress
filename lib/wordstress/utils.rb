module Wordstress
  class Utils
    def self.help

      puts "wordstress v#{Wordstress::VERSION} (http://wordstress.org)"

      puts "Usage: wordstress [options] url"
      printf "\nExamples:\n"
      puts "\t$ wordstress -k d4a34e43b5d74c822830b5c4690eccbb621aa372 http://mywordpressblog.com"
      puts "\t$ wordstress -k d4a34e43b5d74c822830b5c4690eccbb621aa372 -B basic_user:basic_password http://mywordpressblog.com"
      puts "\t$ wordstress -k d4a34e43b5d74c822830b5c4690eccbb621aa372 -T -P http://mywordpressblog.com"
      printf "\n   -k, --key\t\t\t\tuses the key to access wordstress plugin content on target website"
      printf "\n   -B, --basic-auth user:pwd\t\tuses 'user' and 'pwd' as basic auth credentials to target website"
      printf "\n   -s, --store\t\t\t\tStores output report in text file\n"
      printf "\n   -o, --output\t\t\t\tOutput type, one of (json|nagios|tabular). Default is tabular\n"
      printf "\n\nPlugins and themes specific flags\n"
      printf "\n   -T, --fetch-all-themes-vulns\t\tretrieves vulnerabilities also for inactive themes"
      printf "\n   -P, --fetch-all-plugins-vulns\tretrieves vulnerabilities also for inactive plugins"
      printf "\n\nService flags\n"
      printf "\n   -D, --debug\t\t\t\tenters dawn debug mode"
      printf "\n   -v, --version\t\t\tshows version information"
      printf "\n   -h, --help\t\t\t\tshows this help\n"

      true
  end

  def self.url_to_target(url)
    uri = URI.parse(url)
    "#{uri.scheme}://#{uri.host}#{uri.request_uri.gsub("/wordstress", "")}" if uri.port == 80
    "#{uri.scheme}://#{uri.host}:#{uri.port}#{uri.request_uri.gsub("/wordstress", "")}" unless uri.port == 80
  end

  # Transform a given URL into a directory name to be used to store data
  def self.target_to_dirname(target)
    uri = URI.parse(target)
    # Due to not throwing an exception on invalid URL's checking is needed
    if !uri.respond_to?(:request_uri)
      raise 'Invalid wordstress URL'
    end

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
