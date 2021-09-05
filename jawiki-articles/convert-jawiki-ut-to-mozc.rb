#!/usr/bin/ruby
# -*- coding:utf-8 -*-

require 'nkf'


# ==============================================================================
# convert_jawiki_ut_to_mozc
# ==============================================================================

def convert_jawiki_ut_to_mozc
	file = File.new("../mozc/id.def", "r")
		id = file.read.split("\n")
	file.close

	id = id.grep(/\ 名詞,固有名詞,一般,\*,\*,\*,\*/)
	id = id[0].split(" ")[0]

	file = File.new($filename, "r")
		lines = file.read.split("\n")
	file.close

	dicfile = File.new($dicname, "w")

	lines.length.times do |i|
		# せいぶつがく	0	0	6000	生物学
		s = lines[i]
		s = s.split("	")
		s = [s[0], id, id, s[3], s[4]]
		dicfile.puts s.join("	")
	end

	dicfile.close
end


# ==============================================================================
# main
# ==============================================================================

$filename = "jawiki-ut.txt"
$dicname = "mozcdic-jawiki.txt"

if FileTest.exist?("jawiki-ut.txt") == false
	`ruby get-entries-from-jawiki-articles.rb`
end

convert_jawiki_ut_to_mozc

