#!/usr/bin/ruby
# -*- coding:utf-8 -*-

require 'nkf'


# ==============================================================================
# modify_edict2
# ==============================================================================

def modify_edict2
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
		# 全角スペースで始まるエントリを除外
		if lines[i][0] == "　" ||
		# 名詞のみを収録
		lines[i].index(" /(n") == nil
			next
		end

		s = lines[i].split(" /(n")[0]
		# 全角英数を半角に変換
		s = NKF.nkf("-m0Z1 -W -w", s)

		# 表記と読みに分ける。表記または読みが複数あるときはそれぞれ最初のものを採用する
		# 脇見(P);わき見;傍視 [わきみ(P);ぼうし(傍視)] /
		if s.index(" [") != nil
			s = s.split(" [")
			yomi = s[1].split(";")[0]
			yomi = yomi.sub("]", "")
			hyouki = s[0].split(";")[0]
		# カタカナ語には読みがないので表記から読みを作る
		# ブラスバンド(P);ブラス・バンド /(n) brass band/
		else
			hyouki = s.split(";")[0]
			yomi = hyouki
		end

		hyouki = hyouki.split("(")[0]
		yomi = yomi.split("(")[0]
		yomi = yomi.tr(" ・=", "")
		yomi = NKF.nkf("--hiragana -w -W", yomi)

		# 読みがひらがなだけで構成されているか確認
		if yomi != yomi.scan(/[ぁ-ゔー]/).join
			next
		end

		# 読みが2文字以下の場合と表記が1文字の場合は除外
		if yomi.length < 3 || hyouki.length < 2 || 
		# 表記が英数字のみの場合は除外
		hyouki.length == hyouki.bytesize
			next
		end

		dicfile.puts yomi + "	" + id + "	" + id + "	6000	" + hyouki

		# 表記がカタカナのみの場合は英訳表記を作る
		# アクセスログ;アクセス・ログ /(n) {comp} access log/
		if hyouki != hyouki.scan(/[ァ-ヴー ・=]/).join
			next
		end

		hyouki_en = lines[i].split("/")[1]
		hyouki_en = hyouki_en.split(") ")[-1]

		if hyouki_en.index("} ") != nil
			hyouki_en = hyouki_en.split("} ")[1]
		end

		hyouki_en = hyouki_en.split(" (")[0]

		# 英訳がnilの場合は除外
		if hyouki_en == nil ||
		# 4語以上の英訳は除外
		hyouki_en.split(" ").length > 3 ||
		hyouki_en.index("(") != nil ||
		hyouki_en.index("{") != nil
			next
		end

		# ひらがな表記を先に加える。
		# 「もんすたーぺあれんつ」より「over-demanding parents」が先に来るのは不自然なので
		dicfile.puts yomi + "	" + id + "	" + id + "	6100	" + yomi
		dicfile.puts yomi + "	" + id + "	" + id + "	6200	" + hyouki_en
		hyouki_en = nil
	end

	dicfile.close
end


# ==============================================================================
# main
# ==============================================================================

$filename = "edict2"
$dicname = "mozcdic-edict2.txt"

modify_edict2

`rm -f edict2`

