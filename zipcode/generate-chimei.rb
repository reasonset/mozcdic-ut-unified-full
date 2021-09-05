#!/usr/bin/ruby
# -*- coding:utf-8 -*-

require 'nkf'


# ==============================================================================
# generate_chimei
# ==============================================================================

def generate_chimei
	# 品詞IDを取得
	file = File.new("../mozc/id.def", "r")
		id = file.read.split("\n")
	file.close

	id = id.grep(/\ 名詞,固有名詞,地域,一般,\*,\*,\*/)
	id = id[0].split(" ")[0]

	dicfile = File.new($filename, "r")
		lines = dicfile.read.split("\n")
	dicfile.close

	# 半角数字をカタカナ読みに変換する配列を作成
	d1 = []
	d2 = []

	d1 = ["", "いち", "に", "さん", "よん", "ご", "ろく", "なな", "はち", "きゅう"]
	d2 = ["じゅう", "にじゅう", "さんじゅう", "よんじゅう", "ごじゅう"]

	5.times do |p|
		10.times do |q|
			d1[((p + 1) * 10) + q] = d2[p] + d1[q]
		end
	end

	dicfile = File.new($dicname, "w")

	lines.length.times do |i|
		s = lines[i].gsub("\"", "")
		s = s.split(",")

		# 並びの例
		# s[3], s[4], s[5], s[6], s[7], s[8]
		# "トヤマケン","タカオカシ","ミハラマチ","富山県","高岡市","美原町"

		# 読みをカタカナからひらがなに
		# 「tr('ァ-ヴ', 'ぁ-ゔ')」よりnkfのほうが速い
		s[3] = NKF.nkf("--hiragana -w -W", s[3])
		s[4] = NKF.nkf("--hiragana -w -W", s[4])
		s[5] = NKF.nkf("--hiragana -w -W", s[5])

		# 読みの中黒を取る
		s[5] = s[5].gsub("・", "")

		# 市を出力
		# 3文字以上の読みを収録
		if s[4].length >= 3
			t = [s[4], id, id, "9000", s[7]]
			dicfile.puts t.join("	")
		end

		# 町域が収録対象かどうか調べる
		machi = 1

		# 読みに含まれる数字を集めたものが60以上の場合は除外
		# 59以下の場合はカタカナに変換
		p = s[5].scan(/\d/).join.to_i

		if p >= 60
			machi = 0

		elsif p >= 1 &&
		p <= 59
			# 町域の読みにある数字をカタカナに変換
			d1.length.times do |p|
				# 59から順に1までカタカナに変換
				s[5] = s[5].gsub((d1.length - (p + 1)).to_s, \
					d1[d1.length - (p + 1)])
			end			
		end

		# 「3456-11」「OAPたわー」などの読みは除外
		if s[5].index(/[A-Z,-]/) != nil
			machi = 0
		end

		# 「34階」などの階数表記は除外
		# [半角数字]{1回以上当てはまる}階
		if s[8].index(/[0-9]{1,}階/) != nil
			machi = 0
		end

		# 町域を出力
		if machi == 1 &&
		# 3文字以上の読みを収録
		s[5].length >= 3
			t = [s[5], id, id, "9000", s[8]]
			dicfile.puts t.join("	")
		end

		# 市+町域（町域の読みが2文字以下でもOK）を出力
		if machi == 1
			t = [s[4..5].join, id, id, "9000", s[7..8].join]
			dicfile.puts t.join("	")
		end
	end

	dicfile.close

	# 重複項目を削除
	dicfile = File.new($dicname, "r")
		lines = dicfile.read.split("\n")
	dicfile.close

	lines = lines.sort

	dicfile = File.new($dicname, "w")

	lines.length.times do |i|
		if lines[i] != lines[i - 1]
			dicfile.puts lines[i]
		end
	end

	dicfile.close
end


# ==============================================================================
# main
# ==============================================================================

$filename = "KEN_ALL.CSV.fixed"
$dicname = "mozcdic-chimei.txt"
generate_chimei
