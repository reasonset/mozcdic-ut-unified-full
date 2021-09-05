#!/usr/bin/ruby
# -*- coding:utf-8 -*-

require 'nkf'


# ==============================================================================
# modify_jinmei
# ==============================================================================

def modify_jinmei
	# 品詞IDを取得
	file = File.new("../mozc/id.def", "r")
		id = file.read.split("\n")
	file.close

	# 人名のIDは "名詞,一般,*,*,*,*,*" にする。
	# "名詞,固有名詞,人名,一般,*,*" は優先度が低く、
	# "名詞,固有名詞,一般,*,*,*" の「明石屋さんま」が優先されてしまう。
	# "名詞,固有名詞,一般,*,*,*" にするのは避ける。フィルタリング対象なので
	id = id.grep(/\ 名詞,一般,\*,\*,\*,\*,\*/)
	id = id[0].split(" ")[0]

	file = File.new($filename, "r")
		lines = file.read.split("\n")
	file.close

	l2 = []
	p = 0

	lines.length.times do |i|
		# 全角英数を半角に変換
		lines[i] = NKF.nkf("-m0Z1 -W -w", lines[i])

		s = lines[i].split("	")
		yomi = s[0]
		hyouki = s[-1]

		# 表記の最初が空白の場合は取る
		if hyouki[0] == " "
			hyouki = hyouki[1..-1]
		end

		# 表記の最後が空白の場合は取る
		if hyouki[-1] == " "
			hyouki = hyouki[0..-2]
		end

		# 表記がカタカナのみの場合は読みを表記から作る
		if hyouki == hyouki.scan(/[ァ-ヴー・=]/).join
			yomi = NKF.nkf("--hiragana -w -W", hyouki).tr("・=", "")
			yomi = yomi.tr("ゐゑ", "いえ")
		end

		# 表記がひらがなのみの場合は読みを表記から作る
		if hyouki == hyouki.scan(/[ぁ-ゔー・=]/).join
			yomi = hyouki.tr("・=", "")
			yomi = yomi.tr("ゐゑ", "いえ")
		end

		# 表記が25文字を超える場合は除外
		if hyouki.length > 25 ||
		# 表記が1文字の場合は除外
		hyouki.length < 2 ||
		# 表記が英数字のみの場合は除外
		hyouki.length == hyouki.bytesize ||
		# 読みが2文字以下の場合は除外
		yomi.length < 3 ||
		# 読みにひらがな以外のものがあれば除外
		yomi != yomi.scan(/[ぁ-ゔー]/).join
			lines[i] = nil
			next
		end

		lines[i] =  yomi + "	" + id + "	" + id + "	6000	" + hyouki

		# 読みに「ゔ」があるときは「ぶ」の読みを追加
		# すてぃーゔんすぴるばーぐ	0	0	6000	スティーヴン・スピルバーグ
		# すてぃーぶんすぴるばーぐ	0	0	6000	スティーヴン・スピルバーグ
		yomi2 = yomi.gsub("ゔぁ", "ば")
		yomi2 = yomi2.gsub("ゔぃ", "び")
		yomi2 = yomi2.gsub("ゔぇ", "べ")
		yomi2 = yomi2.gsub("ゔぉ", "ぼ")
		# 「ゔ」を最後にしないと「ゔぁ」が「ぶぁ」になる
		yomi2 = yomi2.gsub("ゔ", "ぶ")

		if yomi2 != yomi &&
		# 読みが5文字以上のときに追加
		yomi2.length > 4
			l2[p] = yomi2 + "	" + id + "	" + id + "	6000	" + hyouki
			p = p + 1
		end
	end

	lines = lines + l2
	l2 = []

	# nilと重複エントリを除外
	lines = lines.compact.uniq.sort

	dicfile = File.new($dicname, "w")
		dicfile.puts lines
	dicfile.close
end


# ==============================================================================
# main
# ==============================================================================

$filename = "jinmei-ut.txt"
$dicname = "mozcdic-jinmei-ut.txt"

modify_jinmei

