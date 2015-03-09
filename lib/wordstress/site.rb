require 'net/http'
require 'terminal-table'

module Wordstress
  class Site

    attr_reader :version, :wp_vuln, :plugins, :themes
    attr_accessor :theme_vulns, :plugin_vulns, :online

    def initialize(options={:whitebox=>{:url=>"http://localhost/wordstress", :key=>""}, :basic_auth=>{:user=>"", :pwd=>""}, :output_dir=>"./"})
      begin
        @uri      = URI(options[:whitebox][:url])
        @valid    = true
      rescue
        @valid = false
      end
      @target = Wordstress::Utils.url_to_target(options[:whitebox][:url])

      @basic_auth_user  = options[:basic_auth][:user]
      @basic_auth_pwd   = options[:basic_auth][:pwd]
      @output_dir       = options[:output_dir]

      @start_time       = Time.now
      @end_time         = Time.now # I hate init variables to nil...

      @wordstress_page  = get("#{options[:whitebox][:url]}?wordstress-key=#{options[:whitebox][:key]}")
      @version          = detect_version(@wordstress_page)

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
        @online = false
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
        @online = false
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
        @online = false
        return JSON.parse("{}")
      end
    end

    def version_pad(version)
      return version.gsub('.', '')      #if version.split('.').count == 3
      # return version.gsub('.', '')+'0'  if version.split('.').count == 2
    end

    def detect_version(page)
      v_meta = '0.0.0'
      doc = Nokogiri::HTML(page.body)
      doc.css('#wp_version').each do |link|
        v_meta = link.text
      end

      return {:version => v_meta, :accuracy => 1.0}
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

    def find_plugins
      ret = []
      doc = Nokogiri::HTML(@wordstress_page.body)
      doc.css('#all_plugin').each do |link|
        l=link.text.split(',')
        ret << {:name=>l[2].split('/')[0], :version=>l[1], :status=>l[3]} unless is_already_detected?(ret, l[2])
      end
      ret
    end
    def find_themes
      ret = []
      doc = Nokogiri::HTML(@wordstress_page.body)
      doc.css('#all_theme').each do |link|
        l=link.text.split(',')
        ret << {:name=>l[2], :version=>l[1], :status=>l[3]} unless is_already_detected?(ret, l[2])
      end
      ret
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


    def theme_name(url)
      url.match(/\/wp-content\/themes\/(\w)+/)[0].split('/').last
    end
    def plugin_name(url)
      url.match(/\/wp-content\/plugins\/(\w)+/)[0].split('/').last
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
