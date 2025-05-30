require "erb"
require "rake"
require "pry-byebug"
require_relative "lib/skyfeeds"

desc "Generate eclipses HTML file"
task :default do
  Skyfeeds::EclipsesProcessor.run
end
