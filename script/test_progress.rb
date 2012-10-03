#! /bin/env ruby
require File.expand_path('../../config/boot.rb', __FILE__)

require 'ansi'

total_l = 100000
#pbar = ProgressBar.new(File.basename(uri.request_uri), total_l)
pbar = ANSI::Progressbar.new("blah", total_l, STDOUT)
pbar.transfer_mode

(1..total_l).step(1000) do |i|
  sleep(0.1)
  pbar.set(i)
end
