#!/usr/bin/ruby
# -*- coding:utf-8 -*-

require 'parallel'
require 'bzip2/ffi'
require 'nkf'

# Wikipediaの記事は「タイトル（読み）」が冒頭に書かれていることが多い
# これを手がかりに表記と読みのペアを取得する
#
#    <title>生物学</title>
#    <ns>0</ns>
#    <id>57</id>
#    <revision>
#      <id>81180990</id>
#      <parentid>79962619</parentid>
#      <timestamp>2021-01-04T11:40:47Z</timestamp>
#      <contributor>
#        <username>MathXplore</username>
#        <id>1247297</id>
#      </contributor>
#      <minor />
#      <comment>/* 関連項目 */</comment>
#      <model>wikitext</model>
#      <format>text/x-wiki</format>
#      <text bytes="39506" xml:space="preserve">{{複数の問題
#| 出典の明記 = 2018年11月12日 (月) 08:46 (UTC)
#| 参照方法 = 2018年11月12日 (月) 08:46 (UTC)
#}}
#'''生物学'''（せいぶつがく、{{Lang-en-short|biology}}、

def getYomiHyouki

	# ==============================================================================
	# タイトルから表記を作る
	# ==============================================================================

	# タイトルと記事を取得
	title = $article.split("</title>")[0]
	title = title.split("<title>")[1]

	$article = $article.split(' xml:space="preserve">')[1]

	if $article == nil
		return
	end

	# 全角英数を半角に変換してUTF-8で出力
	# -m0 MIME の解読を一切しない
	# -Z1 全角空白を ASCII の空白に変換
	# -W 入力に UTF-8 を仮定する
	# -w UTF-8 を出力する(BOMなし)
	hyouki = NKF.nkf("-m0Z1 -W -w", title)

	# 「 (」の前を表記にする
	# 田中瞳 (アナウンサー)
	hyouki = hyouki.split(' (')[0]

	# 表記が英数字のみの場合はスキップ
	if hyouki.length == hyouki.bytesize ||
	# 表記が26文字以上の場合はスキップ。候補ウィンドウが大きくなりすぎる
	hyouki[25] != nil ||
	# 内部用のページをスキップ
	hyouki.index("(曖昧さ回避)") != nil ||
	hyouki.index("Wikipedia:") != nil ||
	hyouki.index("ファイル:") != nil ||
	hyouki.index("Portal:") != nil ||
	hyouki.index("Help:") != nil ||
	hyouki.index("Template:") != nil ||
	hyouki.index("Category:") != nil ||
	hyouki.index("プロジェクト:") != nil ||
	# 表記にスペースがある場合はスキップ
	# 読みを検索する前に記事のスペースを削除するので、残してもマッチしない
	# '''皆藤 愛子'''<ref>一部のプロフィールが</ref>(かいとう あいこ、[[1984年]]
	hyouki.index(" ") != nil ||
	# 表記に「、」がある場合はスキップ
	# 記事の「、」で読みを切るので、残してもマッチしない
	hyouki.index("、") != nil
		return
	end

	# 句読点など読みにならない文字を削除したhyouki2を作る
	hyouki2 = hyouki.tr('!?=:・。', '')

	# hyouki2が1文字の場合はスキップ
	if hyouki2[1] == nil ||
	# hyouki2が英数字のみの場合はスキップ
	hyouki2.length == hyouki2.bytesize ||
	# hyouki2が数字を3個以上含む場合はスキップ
	# 国道120号, 3月26日
	hyouki2.scan(/\d/)[2] != nil
		return
	end

	# hyouki2がひらがなとカタカナだけの場合は、読みをhyouki2から作る
	# さいたまスーパーアリーナ
	if hyouki2 == hyouki2.scan(/[ぁ-ゔァ-ヴー]/).join
		# hyouki2が2文字以下の場合は読みも2文字以下になるのでスキップ
		if hyouki2[2] == nil
			return
		end

		yomi = NKF.nkf("--hiragana -w -W", hyouki2)
		yomi = yomi.tr("ゐゑ", "いえ")

		# 他のプロセスによる書き込みをロック
		$dicfile.flock(File::LOCK_EX)
		$dicfile.puts yomi + "	0	0	6000	" + hyouki
		$dicfile.flock(File::LOCK_UN)
		return
	end

	# ==============================================================================
	# 記事を必要な部分に絞る
	# ==============================================================================

	lines = $article

	# 冒頭のテンプレート「{{ }}」を削除
	if lines[0..1] == "{{"
		# 冒頭の連続したテンプレートを1つにまとめる
		lines = lines.gsub("}}\n{{", "")
		# 冒頭のテンプレートを削除
		lines = lines.split("}}")[1..-1].join("}}")
	end

	lines = lines.split("\n")

	# 記事を最大200行にする
	if lines[200] != nil
		lines = lines[0..199]
	end

	# ==============================================================================
	# 記事から読みを作る
	# ==============================================================================

	lines.length.times do |i|
		s = lines[i]

		# 全角英数を半角に変換してUTF-8で出力
		s = NKF.nkf("-m0Z1 -W -w", s)

		# 「<ref 」から「</ref>」までを削除
		# '''皆藤 愛子'''<ref>一部のプロフィールが</ref>(かいとう あいこ、[[1984年]]
		# '''大倉 忠義'''（おおくら ただよし<ref name="oricon"></ref>、[[1985年]]
		if s.index("&lt;ref") != nil
			s = s.sub(/&lt;ref.*?&lt;\/ref&gt;/, "")
		end

		# スペースと「'"「」『』」を削除
		# '''皆藤 愛子'''(かいとう あいこ、[[1984年]]
		s = s.tr(" '\"「」『』", "")

		# 「表記(読み」を検索
		yomi = s.split(hyouki + '(')[1]

		if yomi == nil
			next
		end

		yomi = yomi.split(')')[0]

		if yomi == nil
			next
		end

		# 読みを「[[」で切る
		# ないとうときひろ[[1963年]]
		yomi = yomi.split("[[")[0]

		if yomi == nil
			next
		end

		# 読みを「、」で切る
		# かいとうあいこ、[[1984年]]
		yomi = yomi.split("、")[0]

		if yomi == nil
			next
		end

		# 読みの不要な部分を削除
		yomi = yomi.tr('!?=・。', '')

		# 読みが2文字以下の場合はスキップ
		if yomi[2] == nil ||
		# 読みの文字数が表記の3倍を超える場合はスキップ
		yomi.length > hyouki.length * 3 ||
		# 読みが全てカタカナの場合はスキップ
		# ミュージシャン一覧(グループ)
		yomi == yomi.scan(/[ァ-ヴー]/).join ||
		# 読みが「ー」で始まる場合はスキップ
		yomi[0] == "ー"
			next
		end

		# 読みのカタカナをひらがなに変換
		yomi = NKF.nkf("--hiragana -w -W", yomi)
		yomi = yomi.tr("ゐゑ", "いえ")

		# 読みにひらがな以外のものがある場合はスキップ
		if yomi != yomi.scan(/[ぁ-ゔー]/).join
			next
		end

		# 表記の記号を変換
		hyouki = hyouki.gsub('&amp;', '&')
		hyouki = hyouki.gsub('&quot;', '"')

		$dicfile.flock(File::LOCK_EX)
		$dicfile.puts yomi + "	0	0	6000	" + hyouki
		$dicfile.flock(File::LOCK_UN)
		return
	end
end

# ==============================================================================
# main
# ==============================================================================

jawiki = "jawiki-latest-pages-articles.xml.bz2"
mozcdic = "jawiki-ut.txt"

reader = Bzip2::FFI::Reader.open(jawiki)
$dicfile = File.new(mozcdic, "w")
core_num = `grep cpu.cores /proc/cpuinfo`.chomp.split(": ")[-1].to_i - 1
article_part = ""

puts "Reading..."

while articles = reader.read(500000000)
	articles = articles.split("  </page>")
	articles[0] = article_part + articles[0]

	# 途中で切れた記事をキープ
	article_part = articles[-1]

	puts "Writing..."

	Parallel.map(articles, in_processes: core_num) do |s|
		$article = s
		getYomiHyouki
	end

	puts "Reading..."
end

reader.close
$dicfile.close

# 重複エントリを削除
file = File.new(mozcdic, "r")
		lines = file.read.split("\n")
file.close

lines = lines.uniq.sort

file = File.new(mozcdic, "w")
		file.puts lines
file.close
