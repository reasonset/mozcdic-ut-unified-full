#!/usr/bin/ruby
# -*- coding:utf-8 -*-

require 'kconv'
require 'nkf'


# ==============================================================================
# modify_nicoime
# ==============================================================================

def modify_nicoime
	# 品詞IDを取得
	file = File.new("../mozc/id.def", "r")
		id = file.read.split("\n")
	file.close

	id = id.grep(/\ 名詞,一般,\*,\*,\*,\*,\*/)
	id = id[0].split(" ")[0]

	file = File.new($filename, "r")
		lines = file.read.toutf8.split("\n")
	file.close

	dicfile = File.new($dicname, "w")

	lines.length.times do |i|
		# 全角英数を半角に変換
		lines[i] = NKF.nkf("-m0Z1 -W -w", lines[i])

		# せとこうじ	瀬戸康史	固有名詞
		s = lines[i].split("	")

		# 要素が2個以下の場合は除外
		if s.length < 3
			next
		end

		yomi = s[0]
		hyouki = s[1]

		# 読みの文字数が表記の3倍を超える場合は除外
		# あぁえくすくらめーしょんあんだーばーくえすちょん	0	0	7000	あぁ!_?
		if yomi.length > hyouki.length * 3
			next
		end

		# 読みが3文字以下の場合は除外
		if yomi.length < 4 ||
		# 読みが「ー」「ん」で始まる場合は除外
		yomi[0].tr("ーん", "") == ""
			next
		end

		yomi = yomi.gsub("ヴ", "ゔ")
		# 読みがひらがなだけで構成されているか確認
		if yomi != yomi.scan(/[ぁ-ゔー]/).join
			next
		end

		# 表記が2文字以下の場合は除外
		if hyouki.length < 3 ||
		# 表記が10文字以上の場合は除外
		hyouki.length > 9 || 
		# 表記が英数字のみの場合は除外
		hyouki.length == hyouki.bytesize
			next
		end

		# 表記がカタカナのみの場合に読みが表記と異なる場合は除外
		# ゔるたゔぁ	0	0	7000	モルダウ
		if hyouki == hyouki.scan(/[ァ-ヴー・=]/).join &&
		yomi.tr("・=", "") != NKF.nkf("--hiragana -w -W", hyouki).tr("・=", "")
			next
		end

		dicfile.puts yomi + "	" + id + "	" + id + "	7000	" + hyouki
	end

	dicfile.close
end


# ==============================================================================
# main
# ==============================================================================

$filename = "nicoime_msime.txt"
$dicname = "mozcdic-nicoime.txt"

modify_nicoime

`rm -f nicoime_*.txt`

