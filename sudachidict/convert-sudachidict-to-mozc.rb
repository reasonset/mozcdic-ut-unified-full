#!/usr/bin/ruby
# -*- coding:utf-8 -*-

require 'nkf'


# ==============================================================================
# convert_sudachidict_to_mozc
# ==============================================================================

def convert_sudachidict_to_mozc
	# mecab-user-dict-seedを読み込む
	file = File.new($filename, "r")
		lines = file.read.split("\n")
	file.close

	l2 = []
	p = 0

	# sudachidictのエントリから読みと表記を取得
	lines.length.times do |i|
		# https://github.com/WorksApplications/Sudachi/blob/develop/docs/user_dict.md
		# 見出し (TRIE 用),左連接ID,右連接ID,コスト,見出し (解析結果表示用),\
		# 品詞1,品詞2,品詞3,品詞4,品詞 (活用型),品詞 (活用形),\
		# 読み,正規化表記,辞書形ID,分割タイプ,A単位分割情報,B単位分割情報,※未使用

		# little glee monster,4785,4785,5000,Little Glee Monster,名詞,固有名詞,一般,*,*,*,\
		# リトルグリーモンスター,Little Glee Monster,*,A,*,*,*,*
		# モーニング娘,5144,5142,10320,モーニング娘,名詞,固有名詞,一般,*,*,*,\
		# モーニングムスメ,モーニング娘。,*,C,*,*,*,*
		# 新型コロナウィルス,5145,5144,13856,新型コロナウィルス,名詞,普通名詞,一般,*,*,*,\
		# シンガタコロナウィルス,新型コロナウイルス,*,C,*,*,*,*
		# アイアンマイケル,5144,4788,9652,アイアンマイケル,名詞,固有名詞,人名,一般,*,*,\
		# アイアンマイケル,アイアン・マイケル,*,C,*,*,*,*

		s = lines[i].split(",")
		yomi = s[11]
		yomi = yomi.tr("=・", "")
		hyouki = s[4]

		# 英数字のみの見出しを補正
		if hyouki.length == hyouki.bytesize && hyouki.downcase == s[0].downcase
			s[0] = hyouki
		end

		# 見出しが正規化表記と異なる場合は除外
		if hyouki != s[0] ||
		# 名詞以外を除外
		s[5] != "名詞" ||
		# 地名を除外。地名は郵便番号辞書から生成する
		s[7] == "地名" ||
		# 下の名前を除外
		s[8] == "名" ||
		# 読みが2文字以下のものを除外
		yomi.length < 3 ||
		# 1文字の表記を除外
		hyouki.length < 2 ||
		# 表記が20文字を超える場合は除外
		hyouki.length > 20 ||
		# 読みにカタカナ以外のものがあれば除外
		yomi != yomi.scan(/[ァ-ヴー]/).join ||
		yomi.index('ヶ') != nil ||
		# 会社を除外
		hyouki.index("合資会社") != nil ||
		hyouki.index("事務所") != nil ||
		hyouki.index("コーポレーション") != nil ||
		hyouki.index("ホールディングス") != nil
			next
		end

		# 表記の全角カンマを半角に変換
		hyouki = hyouki.gsub("，", ", ")
		if hyouki[-1] == " "
			hyouki = hyouki[0..-2]
		end

		hyoukitmp = hyouki.tr("・=", "")

		# 読みの文字数より表記の文字数が多いものを除外
		# ミョウジョウ 明星食品株式会社
		# 英数字を考慮してbytesizeで計算する
		# ミスターチルドレン Mr.Children
		if yomi.length < (hyoukitmp.bytesize / 3) ||
		# 読みの文字数が表記の文字数の4倍以上のものを除外
		# 多少の不具合が出るかもしれないが割り切る
		# アカシショウガッコウアカイシショウガッコウ 明石小学校
		yomi.length >= hyoukitmp.length * 4
			next
		end

		# [読み, 表記, コスト] の順に並べる
		# 計算時間を減らすためidは1つにする
		l2[p] = [yomi, hyouki, s[3].to_i]
		p = p + 1
	end

	lines = l2.sort
	l2 = []

	# 品詞IDを取得
	file = File.new("../mozc/id.def", "r")
		id = file.read.split("\n")
	file.close

	id = id.grep(/\ 名詞,固有名詞,一般,\*,\*,\*,\*/)
	id = id[0].split(" ")[0]

	# Mozc形式で書き出す
	dicfile = File.new($dicname, "w")

	lines.length.times do |i|
		s1 = lines[i]
		s2 = lines[i - 1]

		# [読み..表記]が重複するエントリを除外
		if s1[0..1] == s2[0..1]
			next
		end

		# 読みのカタカナをひらがなに変換
		# 「tr('ァ-ヴ', 'ぁ-ゔ')」よりnkfのほうが速い
		yomi = NKF.nkf("--hiragana -w -W", s1[0])
		yomi = yomi.tr('ゐゑ', 'いえ')

		# コストがマイナスの場合は8000にする
		if s1[2] < 0
			s1[2] = 8000
		end

		# コストが10000を超える場合は10000にする
		if s1[2] > 10000
			s1[2] = 10000
		end

		# コストを 6000 < cost < 7000 に調整する
		s1[2] = 6000 + (s1[2] / 10)

		# [読み,id,id,コスト,表記] の順に並べる
		t = [yomi, id, id, s1[2].to_s, s1[1]]
		dicfile.puts t.join("	")
	end

	dicfile.close
end


# ==============================================================================
# main
# ==============================================================================

$filename = "core_lex.csv"
$dicname = "mozcdic-sudachidict-core.txt"
convert_sudachidict_to_mozc

$filename = "notcore_lex.csv"
$dicname = "mozcdic-sudachidict-notcore.txt"
convert_sudachidict_to_mozc
