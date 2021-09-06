#!/usr/bin/ruby
# -*- coding:utf-8 -*-


# ==============================================================================
# modify_cannadic
# ==============================================================================

def modify_cannadic
	# 品詞IDを取得
	file = File.new("../mozc/id.def", "r")
		id = file.read.split("\n")
	file.close

	id_t35 = id.grep(/\ 名詞,一般,\*,\*,\*,\*,\*/)
	id_t35 = id_t35[0].split(" ")[0]

	id_cn = id.grep(/\ 名詞,固有名詞,地域,一般,\*,\*,\*/)
	id_cn = id_cn[0].split(" ")[0]

	file = File.new($filename, "r")
		lines = file.read.encode("UTF-8", "EUC-JP")
		lines = lines.split("\n")
	file.close

	dicfile = File.new($dicname, "w")

	lines.length.times do |i|
		s = lines[i].chomp.split(" ")

		# あきびん #T35*202 空き瓶 空瓶 #T35*151 空きビン 空ビン #T35*150 空きびん
		yomi = s[0]

		# 読みがひらがなだけで構成されているか確認
		if yomi != yomi.scan(/[ぁ-ゔー]/).join
			next
		end

		hinsi = ""

		(s.length - 1).times do |c|
			# cannadicの品詞を取得
			if s[c + 1].index("#") == 0
				hinsi = s[c + 1]
				next
			end

			hyouki = s[c + 1]

			# 読みが2文字以下の場合と表記が1文字の場合は除外
			if yomi.length < 3 || hyouki.length < 2 || 
			# 表記が英数字のみの場合は除外
			hyouki.length == hyouki.bytesize
				next
			end

			# alt-cannadicのコスト値は大きいほど優先度が高い
			cost = 7000 - hinsi.split("*")[1].to_i

			# 人名のIDは "名詞,一般,*,*,*,*,*" にする。
			# "名詞,固有名詞,人名,一般,*,*" は優先度が低く、
			# "名詞,固有名詞,一般,*,*,*" の「明石屋さんま」が優先されてしまう。
			# "名詞,固有名詞,一般,*,*,*" にするのは避ける。フィルタリング対象なので
			if hinsi.index("#T3") == 0 ||
			hinsi.index("#T0") == 0 ||
			hinsi.index("#JN") == 0 ||
			hinsi.index("#KK") == 0
				id = id_t35
			elsif hinsi.index("#CN") == 0
				id = id_cn
			else
				next
			end

			dicfile.puts yomi + "	" + id + "	" + id + "	" + cost.to_s + "	" + hyouki
		end
	end

	dicfile.close
end


# ==============================================================================
# main
# ==============================================================================

$filename = "gcanna.ctd"
$dicname = "mozcdic-altcanna.txt"
modify_cannadic

$filename = "g_fname.ctd"
$dicname = "mozcdic-altcanna-jinmei.txt"
modify_cannadic

`rm -rf alt-cannadic-110208/`
`rm -f *.ctd`

