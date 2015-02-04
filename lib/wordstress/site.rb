require 'net/http'

module Wordstress
  class Site

    attr_reader :version, :scanning_mode, :wp_vuln_json, :plugins, :themes, :themes_vuln_json

    def initialize(options={:target=>"http://localhost", :scanning_mode=>:gentleman, :whitebox=>{}, :basic_auth=>{:user=>"", :pwd=>""}})
      begin
        @uri      = URI(options[:target])
        @raw_name = options[:target]
        @valid    = true
      rescue
        @valid = false
      end
      @scanning_mode = options[:scanning_mode]

      @basic_auth_user = options[:basic_auth][:user]
      @basic_auth_pwd = options[:basic_auth][:pwd]


      unless scanning_mode == :whitebox

        @robots_txt   = get(@raw_name + "/robots.txt")
        @readme_html  = get(@raw_name + "/readme.html")
        @homepage     = get(@raw_name)
        @version      = detect_version(@homepage, false)
      else
        @wordstress_page = get("#{options[:whitebox][:url]}?wordstress-key=#{options[:whitebox][:key]}") if options[:scanning_mode] == :whitebox
        @version      = detect_version(@wordstress_page, true)
      end

      @online       = true

      @wp_vuln_json = get_wp_vulnerabilities  unless @version[:version] == "0.0.0"
      @wp_vuln_json = Hash.new.to_json        if @version[:version] == "0.0.0"

      @plugins      = find_plugins
      @themes       = find_themes
    end

    def get_themes_vulnerabilities
      vuln = []
      @themes.each do |t|
        vuln << {:theme=>t, :vulns=>get_theme_vulnerabilities(t)}
      end
    end

    def get_plugin_vulnerabilities(theme)
      begin
        json= get_https("https://wpvulndb.com/api/v1/plugins/#{theme}").body
        return JSON.parse("{}") if json.include?"The page you were looking for doesn't exist (404)"
        return JSON.parse(json)
      rescue => e
        $logger.err e.message
        @online = false
        return JSON.parse("{}")
      end
    end

    def get_theme_vulnerabilities(theme)
      begin
        json=get_https("https://wpvulndb.com/api/v1/themes/#{theme}").body
        return JSON.parse("{}") if json.include?"The page you were looking for doesn't exist (404)"
        return {}.to_json if json.include?"The page you were looking for doesn't exist (404)"
        return JSON.parse(json)
      rescue => e
        $logger.err e.message
        @online = false
        return JSON.parse("{}")
      end
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

    def detect_version(page, whitebox=false)
      detect_version_blackbox(page) unless whitebox
      detect_version_whitebox(page) if whitebox
    end

    # FIXME: this routine will change. 
    # For plugin 0.6, blog version will be available in the wordstress page
    # with the function get_bloginfo
    # (http://codex.wordpress.org/Function_Reference/get_bloginfo)
    #
    def detect_version_whitebox(page)

      v_meta = ""
      doc = Nokogiri::HTML(page.body)
      doc.xpath("//meta[@name='generator']/@content").each do |attr|
        v_meta = attr.value.split(' ')[1]
      end

      v_rss = ""
      rss_doc = Nokogiri::HTML(page.body)
      begin
        rss = Nokogiri::HTML(get(rss_doc.css('link[type="application/rss+xml"]').first.attr('href')).body) unless l.nil?
        v_rss= rss.css('generator').text.split('=')[1]
      rescue => e
        v_rss = "0.0.0"
      end


      return {:version => v_meta, :accuracy => 1.0} if v_meta == v_rss
      return {:version => v_meta, :accuracy => 0.4} if v_meta != v_rss

      # we failed detecting wordpress version
      return {:version => "0.0.0", :accuracy => 0}


    end

    def detect_version_blackbox(page)

      #
      # 1. trying to detect wordpress version from homepage body meta generator
      # tag

      v_meta = ""
      doc = Nokogiri::HTML(page.body)
      doc.xpath("//meta[@name='generator']/@content").each do |attr|
        v_meta = attr.value.split(' ')[1]
      end

      #
      # 2. trying to detect wordpress version from readme.html in the root
      # directory
      #
      # Not available if scanning 

      unless whitebox
        v_readme = ""
        doc = Nokogiri::HTML(@readme_html.body)
        v_readme = doc.at_css('h1').children.last.text.chop.lstrip.split(' ')[1]
      end

      #
      # 3. Detect from RSS link
      #
      v_rss = ""
      rss_doc = Nokogiri::HTML(page.body)
      begin
        rss = Nokogiri::HTML(get(rss_doc.css('link[type="application/rss+xml"]').first.attr('href')).body) unless l.nil?
        v_rss= rss.css('generator').text.split('=')[1]
      rescue => e
        v_rss = "0.0.0"
      end


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
      return find_themes_gentleman  if @scanning_mode == :gentleman
      return find_themes_whitebox if @scanning_mode == :whitebox
      return []
    end
    def find_plugins
      return find_plugins_gentleman if @scanning_mode == :gentleman
      return find_plugins_whitebox if @scanning_mode == :whitebox

      # bruteforce check must start with error page discovery.
      # the idea is to send 2 random plugin names (e.g. 2 sha256 of time seed)
      # and see how webserver answers and then understand if we can rely on a
      # pattern for the error page.
      return []
    end

    private
    def is_already_detected?(array, name)
      a = array.detect {|elem| elem[:name] == name }
      return false if array.empty?
      return (!a.nil?)
    end

    def find_plugins_whitebox
      ret = []
      doc = Nokogiri::HTML(@wordstress_page.body)
      doc.css('#all_plugin').each do |link|
        l=link.text.split(',')
        ret << {:name=>l[2].split('/')[0], :version=>l[1], :status=>l[3]} unless is_already_detected?(ret, l[2])
      end
      ret
    end
    def find_themes_whitebox
      ret = []
      doc = Nokogiri::HTML(@wordstress_page.body)
      doc.css('#all_theme').each do |link|
        l=link.text.split(',')
        ret << {:name=>l[2], :version=>l[1], :status=>l[3]} unless is_already_detected?(ret, l[2])
      end
      ret
    end

    def find_themes_gentleman
      ret = []
      doc = Nokogiri::HTML(@homepage.body)
      doc.css('link').each do |link|
        if link.attr('href').include?("wp-content/themes")
        theme = theme_name(link.attr('href'))
        ret << {:name=>theme, :version=>""} unless is_already_detected?(ret, theme)
        end
      end
      ret
    end

    def theme_name(url)
      url.match(/\/wp-content\/themes\/(\w)+/)[0].split('/').last
    end
    def plugin_name(url)
      url.match(/\/wp-content\/plugins\/(\w)+/)[0].split('/').last
    end

    def find_plugins_gentleman
      ret = []
      doc = Nokogiri::HTML(@homepage.body)
      doc.css('script').each do |link|
        if ! link.attr('src').nil?
          if link.attr('src').include?("wp-content/plugins")
          plugin = plugin_name(link.attr('src'))
          ret << {:name=>plugin, :version=>"", :status=>"active"} unless is_already_detected?(ret, plugin)
          end
        end
      end
      doc.css('link').each do |link|
        if link.attr('href').include?("wp-content/plugins")
        plugin = plugin_name(link.attr('href'))
        ret << plugin if ret.index(plugin).nil?
        end

      end

      ret
    end

    def get_http(page, use_ssl=false)
      uri = URI(page)
      req = Net::HTTP::Get.new(uri)
      req.basic_auth @basic_auth_user, @basic_auth_pwd unless @basic_auth_user == ""


      http = Net::HTTP.new(uri.hostname, uri.port)
      http.use_ssl = use_ssl

      res = http.start {|h|
        h.request(req)
      }
      case res
      when Net::HTTPSuccess then
        return res
      when Net::HTTPRedirection then
        location = res['location']
        $logger.warn "redirected to #{location}"
        get_http(location)
      when Net::HTTPNotFound
        return res
      else
        return res.value
      end
    end

    def get_https(page)
      get_http(page, true)
    end
  end
end
