#!/usr/bin/ruby
# -*- coding:utf-8 -*-

require 'nkf'


# ==============================================================================
# modify_skkdic
# ==============================================================================

def modify_skkdic
	# 品詞IDを取得
	file = File.new("../mozc/id.def", "r")
		id = file.read.split("\n")
	file.close

	id = id.grep(/\ 名詞,一般,\*,\*,\*,\*,\*/)
	id = id[0].split(" ")[0]

	file = File.new($filename, "r")
		lines = file.read.encode("UTF-8", "EUC-JP")
		lines = lines.split("\n")
	file.close

	dicfile = File.new($dicname, "w")

	lines.length.times do |i|
		# 全角英数を半角に変換
		lines[i] = NKF.nkf("-m0Z1 -W -w", lines[i])

		# わりふr /割り振/割振/
		# いずみ /泉/和泉;地名,大阪/出水;地名,鹿児島/
		s = lines[i].split(" /")
		yomi = s[0]

		# 読みが3文字以下の場合は除外
		if yomi.length < 4 ||
		# 読みに活用形がある場合は除外
		yomi.bytesize != yomi.length * 3
			next
		end

		hyouki = s[1].split("/")

		hyouki.length.times do |c|
			hyouki[c] = hyouki[c].split(";")[0]

			# 表記に優先度をつける
			cost = 7000 + (10 * c)

			# 表記が2文字以下の場合は除外
			if hyouki[c].length < 3 ||
			# 表記が英数字のみの場合は除外
			hyouki[c].length == hyouki[c].bytesize
				next
			end

 			# 2個目以降の表記が前のものと重複している場合は除外
			# ＩＣカード/ICカード/
			if c > 0 && hyouki[c] == hyouki[c - 1]
				next
			end

			dicfile.puts yomi + "	" + id + "	" + id + "	" + cost.to_s + "	" + hyouki[c]
		end
	end

	dicfile.close
end


# ==============================================================================
# main
# ==============================================================================

$filename = "SKK-JISYO.L"
$dicname = "mozcdic-skkdic.txt"

modify_skkdic

`rm -f SKK-JISYO.L`

