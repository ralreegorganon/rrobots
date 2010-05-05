require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "rrobots"
    gem.summary = "gemified version of rrobots"
    gem.description = "gemified version of rrobots"
    gem.email = "jasonedwardjones@gmail.com"
    gem.homepage = "http://github.com/ralreegorganon/rrobots"
    gem.authors = ["Jason Jones"]
    
    gem.executables = ["rrobots", "tournament"]
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "rrobots #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
