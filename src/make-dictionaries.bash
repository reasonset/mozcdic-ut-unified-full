#!/usr/bin/env bash

UTDICDATE="20210822"

altcannadic="true"
edict="true"
jawikiarticles="true"
jinmeiut="true"
neologd="true"
nicoime="true"
skk="true"
sudachidict="true"


# ==============================================================================
# Make each dictionary
# ==============================================================================

function clean() {
dirs -c
echo ":: Cleaning up working directory ..."
find "$PWD" -name "mozcdic-ut.txt" -delete
find .. -maxdepth 1 -name "mozcdic-ut-*.txt" -delete
find .. -type f \( -name "*.zip" -o -name "*.gz" \) -delete
# find .. -type f -name "*.bz2" -delete
find ../mozc -type d -name "mozc-master" -exec rm -r '{}' \;
}

function get-mozc-dict-defs() {
echo ":: Fetching the latest mozc dictionary definitions ..."
pushd ../mozc &>/dev/null || exit
# https://stackoverflow.com/a/18194523
svn checkout https://github.com/google/mozc/trunk/src/data/dictionary_oss --quiet ;\
mv dictionary_oss/id.def "$PWD" ;\
cat dictionary_oss/dictionary*.txt > "$PWD/mozcdic.txt" ;\
rm -rf dictionary_oss
popd &>/dev/null || exit
}

function get-and-process-alt-cannadic() {
echo ":: Checking for revised canna dictionary file ..."
# acc = Academic Computer Club, Umeå University ウメオ, スウェーデン
# bfsu = 北京外国語大学 北京, 中国
# constant = Constant Hosting ピスカタウェイ, ニュージャージー州, 米国
# dotsrc = Dotsrc.org オールボー大学, オールボー, デンマーク
# gigenet = GigeNET シカゴ, イリノイ州, アメリカ合衆国
# ipconnect = IP-Connect LLC ヴィーンヌィツャ, ウクライナ
# jaist = 北陸先端科学技術大学院大学 石川、日本
# liquid = Liquid Telecom ナイロビ, ケニヤ
# nchc = National Center for High-performance Computing 新竹, 台湾
# osdn = OSDN 東京、日本
# plug = Purdue Linux Users Group ウエストラファイエット, インディアナ州, 米国
# rwthaachen = アーヘン工科大学 アーヘン, ドイツ
# tuna = 清華大学 TUNA 協会 北京, 中国
# xtom_hk = xTom Hong Kong Limited 香港, 中国
# xtom_us = xTom.com Inc. ロサンゼルス、カリフォルニア州、米国 
# ymu = 山形大学 山形, 日本
local _dicname="alt-cannadic"
local _mirror="jaist"
local _relid="50881"
local _reldate="110208"
local _redirurl="https://ja.osdn.net/frs/redir.php"
local _dicext=".tar.bz2"
local _url="$_redirurl?m=$_mirror&f=$_dicname%2F$_relid%2F$_dicname-$_reldate$_dicext"
local _sha256sum="d352f4f90fac02219043d9fe5829925215d4bb6173782430c78ccddd38094a98"
if [[ $altcannadic = "true" ]]; 
  then
    pushd "../$_dicname" &>/dev/null || exit
# https://stackoverflow.com/a/11856444
      if ! [ -f "$_dicname-$_reldate.tar.bz2" ];
        then 
            echo ":: File not found. Downloading ..."
            curl --output "$_dicname-$_reldate.tar.bz2" --location "$_url"
      fi
# https://unix.stackexchange.com/a/545866
# https://superuser.com/a/1468626
      if [[ $(sha256sum --check --status <(echo "$_sha256sum  $_dicname-$_reldate$_dicext") ; echo $?) = 1 ]];
        then
                    echo ":: Checksum failed, retrying ..."
                rm "$_dicname-$_reldate$_dicext"
                                        popd &>/dev/null || exit
          get-and-process-alt-cannadic
              else
                      echo ":: Processing revised canna dictionary file ..."
              find "$PWD" -type d -name "$_dicname-$_reldate" -exec rm -rf '{}' \;
              tar -xf "$_dicname-$_reldate$_dicext"
              find "$_dicname-$_reldate" -type f \( -name "gcanna.ctd" -o -name "g_fname.ctd" \) -exec mv --target-directory="$PWD" '{}' \;
                  ruby modify-cannadic.rb
          cat mozcdic-altcanna-jinmei.txt >> ../src/mozcdic-ut.txt
          cat mozcdic-altcanna.txt >> ../src/mozcdic-ut.txt
      fi
    popd &>/dev/null || exit
fi
} 

function get-and-process-edict() {
if [[ $edict = "true" ]]; 
  then
  echo ":: Checking for Jim Breen's EDICT2 file ..."
  pushd "../edict" &>/dev/null || exit
  find "$PWD" -type f -name "edict2" -delete
    if ! [ -f "edict2.gz" ];
        then
            echo ":: File not found. Downloading ..."
            curl --output "edict2.gz" --location "http://ftp.edrdg.org/pub/Nihongo/edict2.gz"
    fi
    echo ":: Processing Jim Breen's EDICT2 ..."
        gzip --decompress --keep edict2.gz
  ruby modify-edict2.rb
  cat mozcdic-edict2.txt >> ../src/mozcdic-ut.txt
        popd &>/dev/null || exit
fi
}

function get-and-process-jawiki-titles() {
local _titles_file="jawiki-latest-all-titles-in-ns0"
local _md5sum_file="jawiki-latest-md5sums.txt"
local _url="https://dumps.wikimedia.org/jawiki/latest"
local _titles_md5=$(sed '/all-titles-in-ns0\.gz/!d ; s/\ .*$//' <(curl --silent --location "$_url/$_md5sum_file"))
echo ":: Checking for Japanese Wikipedia all titles file ..."
pushd "../jawiki-all-titles" &>/dev/null || exit
find "$PWD" -type f -name "$_titles_file" -delete
if ! [ -f "$_titles_file.gz" ];
    then
        echo ":: File not found. Downloading ..."
        curl --output "$_titles_file.gz" --location "$_url/$_titles_file.gz"
fi
if [[ $(md5sum --check --status <(echo "$_titles_md5  $_titles_file.gz") ; echo $?) = 1 ]];
  then
          echo ":: Checksum failed, retrying ..."
          rm "$_titles_file.gz"
          popd &>/dev/null || exit
      get-and-process-jawiki-titles
        else
                echo ":: Processing Japanese Wikipedia all titles file ..."
        ruby count-jawiki-titles.rb
fi
popd &>/dev/null || exit
}

function get-and-process-jawiki-articles() {
local _articles_file="jawiki-latest-pages-articles.xml.bz2"
local _md5sum_file="jawiki-latest-md5sums.txt"
local _url="https://dumps.wikimedia.org/jawiki/latest"
local _articles_md5=$(sed '/pages-articles\.xml\.bz2/!d ; s/\ .*$//' <(curl --silent --location "$_url/$_md5sum_file"))
if [[ $jawikiarticles = "true" ]]; then
  echo ":: Checking for Japanese Wikipedia articles file ..."
  pushd "../jawiki-articles/" &>/dev/null || exit
    if ! [ -f "$_articles_file" ];
        then
            echo ":: File not found. Downloading ..."
            curl --output "$_articles_file" --location "$_url/$_articles_file"
        else
            echo ":: File found. Verifying file integrity ..."
    fi
    if [[ $(md5sum --check --status <(echo "$_articles_md5  $_articles_file") ; echo $?) = 1 ]];
      then
              echo ":: Checksum failed, retrying ..."
              #rm "$_articles_file"
                    popd &>/dev/null || exit
        get-and-process-jawiki-articles
                else
                        echo ":: Processing Japanese Wikipedia articles file for cost adjustments ..."
        ruby convert-jawiki-ut-to-mozc.rb
        ruby ../src/filter-entries.rb mozcdic-jawiki.txt
        cat mozcdic-jawiki.txt >> ../src/mozcdic-ut.txt
        fi
  popd &>/dev/null || exit
fi
}

function process-jinmei() {
if [[ $jinmeiut = "true" ]]; 
        then
                echo ":: Processing jinmei for Japanese names ..."
                pushd ../jinmei-ut &>/dev/null || exit
                ruby modify-jinmei-ut.rb
                cat mozcdic-jinmei-ut.txt >> ../src/mozcdic-ut.txt
                popd &>/dev/null || exit
fi
}

function get-and-process-neologd() {
local _url="https://github.com/neologd/mecab-ipadic-neologd/raw/master/seed"
local _file="mecab-user-dict-seed"
local _version="20200910"
local _file_suffix=".csv.xz"
if [[ $neologd = "true" ]]; then
  echo ":: Checking for Neologism dictionary file ..."
  pushd "../neologd" &>/dev/null || exit
        if ! [ -f "$_file.$_version$_file_suffix" ];
        then
            echo ":: File not found. Downloading ..."
            curl --output "$_file.$_version$_file_suffix" --location "$_url/$_file.$_version$_file_suffix"
        fi
        echo ":: Processing Neologism dictionary file ..."
  xz --decompress --keep "$_file.$_version$_file_suffix"
  ruby convert-neologd-to-mozc.rb
  ruby ../src/filter-entries.rb mozcdic-neologd.txt
  cat mozcdic-neologd.txt >> ../src/mozcdic-ut.txt
        popd &>/dev/null || exit
fi
}

function get-and-process-nicoime() {
local _filename="nicoime.zip"
local _url="http://public.s3.tkido.com.s3-website-ap-northeast-1.amazonaws.com"
if [[ $nicoime = "true" ]]; 
        then
  pushd "../nicoime" &>/dev/null || exit
        echo ":: Checking for niconico IME file ..."
        if ! [ -f "$_filename" ];
        then
            echo ":: File not found. Downloading ..."
                curl --output "$_filename" --location "$_url/$_filename"
        fi
        echo ":: Processing niconico IME file ..."
        find "$PWD" -type f -name "nicoime_*.txt" -delete
        unzip "$_filename"
        ruby modify-nicoime.rb
        cat mozcdic-nicoime.txt >> ../src/mozcdic-ut.txt
        find "$PWD" -type f -name "nicoime_*.txt" -delete
        popd &>/dev/null || exit
fi
}

function get-and-process-skk() {
local _filename="SKK-JISYO.L.gz"
local _url="http://openlab.jp/skk/dic"
if [[ $skk = "true" ]]; 
        then
        pushd "../skk" &>/dev/null || exit
        echo ":: Checking for Simple Kana to Kanji (SKK) dictionary file ..."
        if ! [ -f "$_filename" ];
        then
            echo ":: File not found. Downloading ..."
            curl --output "$_filename" --location "$_url/$_filename"
        fi
        echo ":: Processing Simple Kana to Kanji (SKK) dictionary file ..."
        find "$PWD" -type f -name "SKK-JISYO.L" -delete
        gzip --decompress --keep "$_filename"
        ruby modify-skkdic.rb
        cat mozcdic-skkdic.txt >> ../src/mozcdic-ut.txt
        popd &>/dev/null || exit
fi
}

function get-and-process-sudachidict() {
local _filename="core_lex.csv"
local
_url="https://github.com/WorksApplications/SudachiDict/raw/develop/src/main/text/"

if [[ $sudachidict = "true" ]]; 
        then
        pushd "../sudachidict" &>/dev/null || exit
        echo ":: Checking for Sudachi Dictionary files ..."
        if ! [ -f "$_filename" ];
        then
            echo "File: $_filename not found. Downloading ..."
            curl --output "$_filename" --location "$_url/$_filename"
        fi
        if ! [ -f "not$_filename" ];
        then
            echo "File: not$_filename not found. Downloading ..."
            curl --output "not$_filename" --location "$_url/not$_filename"
        fi
        echo ":: Processing Sudachi Dictionary files ..."
        ruby convert-sudachiduct-to-mozc.rb
        ruby ../src/filter-entries.rb mozcdic-sudachidict-*.txt
        cat mozcdic-sudachidict-*.txt >> ../src/mozcdic-ut.txt
        popd &>/dev/null || exit
fi
}

function fetch_and_process-Japan-postcode() {
local _filename="ken_all.zip"
local _url="https://www.post.japanpost.jp/zipcode/dl/kogaki/zip"
echo ":: Checking Japan postal codes file  ..."
pushd "../zipcode" &>/dev/null || exit
find "$PWD" -type f -name "KEN_ALL.CSV" -delete
        if ! [ -f "$_filename" ];
        then
            echo "File not found. Downloading ..."
                curl --output "$_filename" --location "$_url/$_filename"
  fi
echo ":: Processing Japan postal codes ..."
unzip "$_filename"
ruby fix-ken_all.rb
ruby generate-chimei.rb
cat mozcdic-chimei.txt >> ../src/mozcdic-ut.txt
find "$PWD" -type f -name "KEN_ALL.CSV" -delete
popd &>/dev/null || exit
}

function extract_new_entry_and_apply_jawiki_costs() {
cd ../src/


# ==============================================================================
# Extract new entries and apply jawiki costs
# ==============================================================================

ruby extract-new-entries.rb mozcdic-ut.txt
ruby apply-jawiki-costs.rb mozcdic-ut.txt.extracted

rm -f ../mozcdic*-ut-*.txt
mv mozcdic-ut.txt.extracted ../mozcdic-ut-$UTDICDATE.txt
}

function make_mozcdic-ut_pkg() {
# ==============================================================================
# Make a mozcdic-ut package
# ==============================================================================

cd ../../
rm -rf mozcdic-ut-$UTDICDATE
mkdir mozcdic-ut-$UTDICDATE
rsync -av mozcdic-ut-dev/* mozcdic-ut-$UTDICDATE --exclude=id.def \
--exclude=jawiki-latest* --exclude=jawiki-ut.txt --exclude=KEN_ALL.* --exclude=*.csv \
--exclude=*.xml --exclude=*.gz --exclude=*.bz2 --exclude=*.xz --exclude=*.zip
rm -f mozcdic-ut-$UTDICDATE/*/mozcdic*.txt*
}

function main() {
clean
get-mozc-dict-defs
get-and-process-alt-cannadic
get-and-process-edict
get-and-process-jawiki-titles
get-and-process-jawiki-articles
process-jinmei
get-and-process-neologd
get-and-process-nicoime
get-and-process-skk
get-and-process-sudachidict
fetch_and_process-Japan-postcode
extract_new_entry_and_apply_jawiki_costs
make_mozcdic-ut_pkg
}

main
