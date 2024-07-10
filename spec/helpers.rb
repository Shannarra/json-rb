require 'pry'

Dir.children('src').each do |file|
  require_relative "../src/#{file}"
end

module Helpers
  # TODO: add helpers if needed
end
