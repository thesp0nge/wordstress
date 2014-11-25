require 'net/http'

module Wordstress
  class Site

    attr_reader :version, :scanning_mode, :wp_vuln_json, :plugins, :themes

    def initialize(options={:target=>"http://localhost", :scanning_mode=>:gentleman})
      begin
        @uri      = URI(options[:target])
        @raw_name = options[:target]
        @valid    = true
      rescue
        @valid = false
      end
      @scanning_mode = options[:scanning_mode]

      @robots_txt   = get(@raw_name + "/robots.txt")
      @readme_html  = get(@raw_name + "/readme.html")
      @homepage     = get(@raw_name)
      @version      = detect_version
      @online       = true

      @wp_vuln_json = get_wp_vulnerabilities  unless @version[:version] == "0.0.0"
      @wp_vuln_json = Hash.new.to_json        if @version[:version] == "0.0.0"

      @plugins      = find_plugins
      @themes       = find_themes
    end

    def get_wp_vulnerabilities
      begin
        return get_https("https://wpvulndb.com/api/v1/wordpresses/#{version_pad(@version[:version])}").body
      rescue => e
        $logger.err e.message
        @online = false
        return ""
      end
    end

    def version_pad(version)
      # 3.2.1 => 321
      # 4.0 => 400
      return version.gsub('.', '')      if version.split('.').count == 3
      return version.gsub('.', '')+'0'  if version.split('.').count == 2
    end

    def detect_version

      #
      # 1. trying to detect wordpress version from homepage body meta generator
      # tag

      v_meta = ""
      doc = Nokogiri::HTML(@homepage.body)
      doc.xpath("//meta[@name='generator']/@content").each do |attr|
        v_meta = attr.value.split(' ')[1]
      end

      #
      # 2. trying to detect wordpress version from readme.html in the root
      # directory

      v_readme = ""
      doc = Nokogiri::HTML(@readme_html.body)
      v_readme = doc.at_css('h1').children.last.text.chop.lstrip.split(' ')[1]

      v_rss = ""
      rss_doc = Nokogiri::HTML(@homepage.body)
      rss = Nokogiri::HTML(get(rss_doc.css('link[type="application/rss+xml"]').first.attr('href')).body)

      v_rss= rss.css('generator').text.split('=')[1]

      return {:version => v_meta, :accuracy => 1.0} if v_meta == v_readme && v_meta == v_rss
      return {:version => v_meta, :accuracy => 0.8} if v_meta == v_readme || v_meta == v_rss

      # we failed detecting wordpress version
      return {:version => "0.0.0", :accuracy => 0}
    end

    def get(page)
      return get_http(page)   if @uri.scheme == "http"
      return get_https(page)  if @uri.scheme == "https"
    end

    def is_valid?
      return @valid
    end
    def online?
      return @online
    end

    def find_themes
      return find_themes_gentleman if @scanning_mode == :gentleman
      return []
    end
    def find_plugins
      return find_plugins_gentleman if @scanning_mode == :gentleman
      return []
    end

    private
    def find_themes_gentleman 
      ret = []
      doc = Nokogiri::HTML(@homepage.body)
      doc.css('link').each do |link|
        if link.attr('href').include?("wp-content/themes")
        theme = theme_name(link.attr('href')) 
        ret << theme if ret.index(theme).nil?
        end
      end
      ret
    end

    def theme_name(url)
      url.match(/\/wp-content\/themes\/(\w)+/)[0].split('/').last
    end
    def find_plugins_gentleman
      doc = Nokogiri::HTML(@homepage.body)
      doc.css('link')

    end

    def get_http(page)
      uri = URI.parse(page)
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Get.new(uri.request_uri)
      return http.request(request)
    end
    def get_https(page)
      uri = URI.parse(page)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri.request_uri)
      return http.request(request)

    end
  end
end
