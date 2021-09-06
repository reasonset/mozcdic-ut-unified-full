#!/usr/bin/ruby
# -*- coding:utf-8 -*-

require 'zlib'


# ==============================================================================
# count_jawiki_titles
# ==============================================================================

def count_jawiki_titles
	file = File.open($filename)
	gz = Zlib::GzipReader.new(file) 
	titles = gz.read.split("\n")
	gz.close

	titles.length.times do |i|
		# "BEST_(三浦大知のアルバム)" を
		# "三浦大知のアルバム)" に変更。
		# 「三浦大知」を前方一致検索できるようにする
		titles[i] = titles[i].split("_(")[-1]

		# 3文字未満の表記は多すぎるので除外
		if titles[i].length < 3
			titles[i] = nil
			next
		end

		# "_" を " " に置き換え
		# THE_BEATLES
		titles[i] = titles[i].gsub("_", " ")
	end

	titles = titles.compact.sort

	dicfile = File.new($dicname, "w")

	t_length = titles.length

	t_length.times do |i|
		# 重複エントリをスキップ
		if titles[i] == titles[i - 1]
			next
		end

		c = 1

		# 前方一致する限りカウントし続ける
		while (i + c) < t_length && titles[i + c].index(titles[i]) == 0
			c = c + 1
		end

		dicfile.puts "jawikititles	0	0	" + c.to_s + "	" + titles[i]
	end

	dicfile.close
end


# ==============================================================================
# main
# ==============================================================================

$filename = "jawiki-latest-all-titles-in-ns0.gz"
$dicname = "jawiki-latest-all-titles-in-ns0.counts"

count_jawiki_titles

`rm -f jawiki-latest-all-titles-in-ns0`

