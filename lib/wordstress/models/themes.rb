require 'data_mapper'
require 'dm-sqlite-adapter'

module Wordstress
  module Models

    class Info
      include DataMapper::Resource

      property :id,           Serial
      property :revision,     Integer
      property :created_at,   DateTime, :default=>DateTime.now
      property :updated_at,   DateTime, :default=>DateTime.now
    end

    class Theme
      include DataMapper::Resource

      property :id,           Serial
      property :name,         String
      property :link,         String
      property :created_at,   DateTime, :default=>DateTime.now
      property :updated_at,   DateTime, :default=>DateTime.now
    end

    class Themes

      def initialize(options={:dbname=>"themes.db"})
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


        puts "Theme SVN revision is: #{revision}"
        puts "#{links.count} themes found"

        i = Info.new
        i.revision = revision
        i.save

        links.each do |link|
          # puts "-> #{link.attr('href')} - #{link.text.chop}"
          t = Theme.new
          t.name = link.text.chop
          t.link = 'https://themes.svn.wordpress.org/'+link.attr('href')
          t.save

        end
      end

    end
  end
end
