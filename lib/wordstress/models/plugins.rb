require 'data_mapper'
require 'dm-sqlite-adapter'

module Wordstress
  module Models

    class PluginInfo
      include DataMapper::Resource

      property :id,           Serial
      property :revision,     Integer
      property :created_at,   DateTime, :default=>DateTime.now
      property :updated_at,   DateTime, :default=>DateTime.now
    end

    class Plugin
      include DataMapper::Resource

      property :id,           Serial
      property :name,         String
      property :link,         String
      property :created_at,   DateTime, :default=>DateTime.now
      property :updated_at,   DateTime, :default=>DateTime.now
    end

    class Plugins

      def initialize(options={:dbname=>"plugins.db"})
        DataMapper.setup(:default, "sqlite3://#{File.join(Dir.pwd, options[:dbname])}")
        DataMapper.finalize
        DataMapper.auto_migrate!
      end

      def import_from_file(filename)
        doc = Nokogiri::HTML(File.read(filename))
        title = doc.at_css('title').children.text

        return nil unless title.include?"Revision"
        revision = title.split("Revision ")[1].split(':')[0].to_i
        links = doc.xpath('//li//a')

        puts "Plugin SVN revision is: #{revision}"
        puts "#{links.count} plugins found"

        i = PluginInfo.new
        i.revision = revision
        i.save

        links.each do |link|
          p = Plugin.new
          p.name = link.text.chop
          p.link = 'https://plugins.svn.wordpress.org/'+link.attr('href')
          p.save

        end
      end

    end
  end
end
