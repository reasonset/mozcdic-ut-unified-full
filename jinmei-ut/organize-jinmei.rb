#!/usr/bin/ruby
# -*- coding:utf-8 -*-

require 'nkf'


# ==============================================================================
# organize_jinmei
# ==============================================================================

def organize_jinmei
	file = File.new($filename, "r")
		lines = file.read.split("\n")
	file.close

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
		# 読みが2文字以下の場合は除外
		yomi.length < 3 ||
		# 読みにひらがな以外のものがあれば除外
		yomi != yomi.scan(/[ぁ-ゔー]/).join
			lines[i] = nil
			next
		end

		lines[i] =  yomi + "	0	0	6000	" + hyouki
	end

	# nilと重複エントリを除外
	lines = lines.compact.uniq.sort

	dicfile = File.new($dicname, "w")
		dicfile.puts lines
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
	$dicname = $filename + ".organized"

	organize_jinmei
end

