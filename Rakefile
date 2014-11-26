require "bundler/gem_tasks"

namespace :import do
  desc 'Import themes'
  task :themes, :name do |t,args|
    require 'wordstress/models/themes'
    name = args.name
    puts "reading themes from #{name}"
    t = Wordstress::Models::Themes.new({:dbname=>"themes.db"})
    t.import_from_file(name)
  end

  desc 'Import plugins'
  task :plugins, :name do |t, args|
    require 'wordstress/models/plugins'
    name = args.name
    puts "reading themes from #{name}"
    p = Wordstress::Models::Plugins.new({:dbname=>"plugins.db"})
    p.import_from_file(name)

  end
end

