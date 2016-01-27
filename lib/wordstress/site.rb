require 'net/http'
require 'terminal-table'

module Wordstress
  class Site

    attr_reader :version, :scanning_mode, :wp_vuln, :plugins, :themes
    attr_accessor :theme_vulns, :plugin_vulns, :online

    def initialize(options={:target=>"http://localhost", :scanning_mode=>:gentleman, :whitebox=>{}, :basic_auth=>{:user=>"", :pwd=>""}, :output_dir=>"./"})
      @target     = options[:target]
      begin
        @uri      = URI(options[:target])
        @raw_name = options[:target]
        @valid    = true
      rescue
        @valid = false
      end
      @scanning_mode    = options[:scanning_mode]

      @basic_auth_user  = options[:basic_auth][:user]
      @basic_auth_pwd   = options[:basic_auth][:pwd]
      @output_dir       = options[:output_dir]

      @start_time       = Time.now
      @end_time         = Time.now # I hate init variables to nil...

      unless scanning_mode == :whitebox

        @robots_txt   = get(@raw_name + "/robots.txt")
        @readme_html  = get(@raw_name + "/readme.html")
        @homepage     = get(@raw_name)
        @version      = detect_version(@homepage, false)
      else
        @wordstress_page  = get("#{options[:whitebox][:url]}?wordstress-key=#{options[:whitebox][:key]}") if options[:scanning_mode] == :whitebox
        @version          = detect_version(@wordstress_page, true)
      end

      @online       = true

      @wp_vuln = get_wp_vulnerabilities  unless @version[:version] == "0.0.0"
      @wp_vuln = JSON.parse("{}")        if @version[:version] == "0.0.0"

      @plugins      = find_plugins
      @themes       = find_themes
      @theme_vulns  = []
      @plugin_vulns = []
    end

    def stop_scan
      @end_time = Time.now
    end

    def get_plugin_vulnerabilities(theme)
      begin
        json= get_https("https://wpvulndb.com/api/v1/plugins/#{theme}").body
        return JSON.parse("{\"plugin\":{\"vulnerabilities\":[]}}") if json.include?"The page you were looking for doesn't exist (404)"
        return JSON.parse(json)
      rescue => e
        $logger.err e.message
        @online = false unless e.message.include?"403"
        return JSON.parse("{}")
      end
    end

    def get_theme_vulnerabilities(theme)
      begin
        json=get_https("https://wpvulndb.com/api/v1/themes/#{theme}").body
        return JSON.parse("{\"theme\":{\"vulnerabilities\":[]}}") if json.include?"The page you were looking for doesn't exist (404)"
        return JSON.parse(json)
      rescue => e
        $logger.err e.message
        @online = false unless e.message.include?"403"
        return JSON.parse("{}")
      end
    end

    def get_wp_vulnerabilities
      begin
        page= get_https("https://wpvulndb.com/api/v1/wordpresses/#{version_pad(@version[:version])}")
        return JSON.parse(page.body) unless page.class == Net::HTTPNotFound
        return JSON.parse("{\"wordpress\":{\"vulnerabilities\":[]}}") if page.class == Net::HTTPNotFound
      rescue => e
        $logger.err e.message
        @online = false unless e.message.include?"403"
        return JSON.parse("{}")
      end
    end

    def version_pad(version)
      return version.gsub('.', '')      #if version.split('.').count == 3
      # return version.gsub('.', '')+'0'  if version.split('.').count == 2
    end

    def detect_version(page, whitebox=false)
      detect_version_blackbox(page) unless whitebox
      detect_version_whitebox(page) if whitebox
    end

    def detect_version_whitebox(page)
      v_meta = '0.0.0'
      doc = Nokogiri::HTML(page.body)
      doc.css('#wp_version').each do |link|
        v_meta = link.text
      end

      return {:version => v_meta, :accuracy => 1.0}
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

    def ascii_report
      # 0_Executive summary
      rows = []
      rows << ['Wordstress version', Wordstress::VERSION]
      rows << ['Scan started',@start_time]
      rows << ['Scan duration', "#{(@end_time - @start_time).round(3)} sec"]
      rows << ['Target', @target]
      rows << ['Wordpress version', version[:version]]
      unless @online
        rows << ['Scan status', 'During scan wordstress went offline. Results are incomplete / unreliable. Please make sure you are connected to the Internet']
      else
        rows << ['Scan status', 'Scan completed successfully']
      end
      table = Terminal::Table.new :title=>'Scan summary', :rows => rows
      puts table

      return table unless @online
      # 1_vulnerability summary
      rows = []
      rows << ['Wordpress version', @wp_vuln["wordpress"]["vulnerabilities"].count]
      rows << ['Plugins installed', @plugin_vulns.count]
      rows << ['Themes installed', @theme_vulns.count]

      table = Terminal::Table.new :title=>'Vulnerabilities found', :rows => rows
      puts table

      # 2_vulnerabilities detail

      if @wp_vuln["wordpress"]["vulnerabilities"].count != 0

        rows = []
        @wp_vuln["wordpress"]["vulnerabilities"].each do |v|
          rows << [v[:title], v[:cve], v[:url], v[:fixed_in]]
          rows << :separator
        end
        table = Terminal::Table.new :title=>"Vulnerabilities in Wordpress version #{version[:version]}", :headings=>['Issue', 'CVE', 'Url', 'Fixed in version'], :rows=>rows
        puts table
      end

      if @plugin_vulns.count != 0
        rows = []
        @plugin_vulns.each do |v|
          rows << [v[:title], v[:cve], v[:detected], v[:fixed_in]]
          rows << :separator
        end
        table = Terminal::Table.new :title=>"Vulnerabilities in installed plugins", :headings=>['Issue', 'CVE', 'Detected version', 'Fixed version'], :rows=>rows
        puts table
      end

      if @theme_vulns.count != 0

        rows = []
        @theme_vulns.each do |v|
          rows << [v[:title], v[:cve], v[:detected], v[:fixed_in]]
          rows << :separator
        end
        table = Terminal::Table.new :title=>"Vulnerabilities in installed themes", :headings=>['Issue', 'CVE', 'Detected version', 'Fixed in version'], :rows=>rows
        puts table
      end





      # File.open(File.join(@output_dir, "report.txt"), 'w') do |file|

      # file.puts("target: #{@target}")
      # file.puts("wordpress version: #{version[:version]}")
      # file.puts("themes found: #{@themes.count}")
        # file.puts("plugins found: #{@plugins.count}")
        # file.puts("Vulnerabilities in wordpress")
        # @wp_vuln["wordpress"]["vulnerabilities"].each do |v|
          # file.puts "#{v[:title]} - fixed in #{v[:fixed_in]}"
        # end
        # file.puts("Vulnerabilities in themes")
        # @theme_vulns.each do |v|
          # file.puts "#{v[:title]} - fixed in #{v[:fixed_in]}"
        # end
        # file.puts("Vulnerabilities in plugins")
        # @plugins_vulns.each do |v|
          # file.puts "#{v[:title]} - fixed in #{v[:fixed_in]}"
        # end
      # end
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
        $logger.debug "redirected to #{location}"
        get_http(location, use_ssl)
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
