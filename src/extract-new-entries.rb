#!/usr/bin/ruby
# -*- coding:utf-8 -*-


# ==============================================================================
# extract_new_entries
# ==============================================================================

def extract_new_entries
	file = File.new("../mozc/mozcdic.txt", "r")
		mozcdic = file.read.split("\n")
	file.close

	# mozc辞書の並びを変えてマークをつける
	# (変更前) げんかん	1823	1823	5278	玄関
	# (変更後) げんかん	玄関	*1823	1823	5278

	mozcdic.length.times do |i|
		s = mozcdic[i].split("	")
		s = [s[0], s[4], "*" + s[1], s[2], s[3]]
		mozcdic[i] = s.join("	")
	end

	file = File.new($filename, "r")
		utdic = file.read.split("\n")
	file.close

	# ut辞書の並びを変える
	# (変更前) げんかん	1617	1617	7178	厳寒
	# (変更後) げんかん	厳寒	1617	1617	7178

	utdic.length.times do |i|
		s = utdic[i].split("	")
		s = [s[0], s[4], s[1], s[2], s[3]]
		utdic[i] = s.join("	")
	end

	lines = mozcdic + utdic
	mozcdic = []
	utdic = []
	lines = lines.sort

	# この時点での並び。mozc辞書が先になる
	# げんかん	玄関	*1823	1823	5278
	# げんかん	厳寒	1617	1617	7178

	dicfile = File.new($dicname, "w")

	lines.length.times do |i|
		s1 = lines[i].split("	")
		s2 = lines[i - 1].split("	")

		# mozc辞書はスキップ
		if s1[2][0] == "*"
			next
		# mozc辞書と「読み+表記+左文脈ID」が重複するut辞書はスキップ
		elsif s2[2][0] == "*" && s1[0..2] == s2[0..2]
			next
		# ut辞書内で「読み+表記」が重複する場合はスキップ
		elsif s2[2][0] != "*" && s1[0..1] == s2[0..1]
			next
		end

		s1 = [s1[0], s1[2], s1[3], s1[4], s1[1]]
		dicfile.puts s1.join("	")
	end

	dicfile.close
end


# ==============================================================================
# main
# ==============================================================================

targetfiles = ARGV

if ARGV == []
	puts "Usage: ruby script.rb [FILE]"
	exit
end

targetfiles.length.times do |i|
	$filename = targetfiles[i]
	$dicname = $filename + ".extracted"

	extract_new_entries
end
