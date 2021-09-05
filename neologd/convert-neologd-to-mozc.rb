#!/usr/bin/ruby
# -*- coding:utf-8 -*-

require 'nkf'


# ==============================================================================
# convert_neologd_to_mozc
# ==============================================================================

def convert_neologd_to_mozc
	# mecab-user-dict-seedを読み込む
	file = File.new($filename, "r")
		lines = file.read.split("\n")
	file.close

	l2 = []
	p = 0

	# neologdのエントリから読みと表記を取得
	lines.length.times do |i|
		# 表層形,左文脈ID,右文脈ID,コスト,品詞1,品詞2,品詞3,品詞4,品詞5,品詞6,\
		# 原形,読み,発音
		# little glee monster,1289,1289,2098,名詞,固有名詞,人名,一般,*,*,\
		# Little Glee Monster,リトルグリーモンスター,リトルグリーモンスター
		# リトルグリーモンスター,1288,1288,-1677,名詞,固有名詞,一般,*,*,*,\
		# Little Glee Monster,リトルグリーモンスター,リトルグリーモンスター
		# 新型コロナウィルス,1288,1288,4808,名詞,固有名詞,一般,*,*,*,\
		# 新型コロナウィルス,シンガタコロナウィルス,シンガタコロナウィルス
		# 新型コロナウイルス,1288,1288,4404,名詞,固有名詞,一般,*,*,*,\
		# 新型コロナウイルス,シンガタコロナウイルス,シンガタコロナウイルス

		s = lines[i].split(",")
		yomi = s[11]
		hyouki = s[10]

		# 表層形が原形と異なる場合は除外
		if hyouki != s[0] ||
		# 名詞以外は除外
		s[4] != "名詞" ||
		# 地域名を除外。地域名は郵便番号辞書から生成する
		s[6] == "地域" ||
		# 下の名前を除外
		s[7] == "名" ||
		# 読みが2文字以下のものを除外
		yomi.length < 3 ||
		# 1文字の表記を除外
		hyouki.length < 2 ||
		# 表記が20文字を超える場合は除外
		hyouki.length > 20 ||
		# 数字を2個以上含む表記を除外
		# 「712円」「第1231話」などキリがない
		hyouki.scan(/\d/).length > 1
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
	idfile = File.new("../mozc/id.def", "r")
		id = idfile.read.split("\n")
	idfile.close

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

require 'open-uri'
url = "https://github.com/neologd/mecab-ipadic-neologd/tree/master/seed"
neologdver = URI.open(url).read.split("mecab-user-dict-seed.")[1]
neologdver = neologdver.split(".csv.xz")[0]

`wget -nc https://github.com/neologd/mecab-ipadic-neologd/raw/master/seed/mecab-user-dict-seed.#{neologdver}.csv.xz`
`7z x -aos mecab-user-dict-seed.#{neologdver}.csv.xz`
$filename = "mecab-user-dict-seed.#{neologdver}.csv"
$dicname = "mozcdic-neologd.txt"

convert_neologd_to_mozc

