#!/bin/bash

UTDICDATE="20210907"

altcannadic="true"
chimei="true"
edict="true"
jawikiarticles="true"
jinmeiut="true"
neologd="true"
skkdic="true"
sudachidict="true"


# ==============================================================================
# Make each dictionary
# ==============================================================================

rm -f mozcdic-ut*.txt
rm -f ../*/mozcdic-ut-*.txt

cd ../mozc/
sh get-official-mozc.sh

cd ../jawiki-all-titles/
ruby count-jawiki-titles.rb

cd ../alt-cannadic/
ruby modify-cannadic.rb

cd ../chimei/
ruby fix-ken_all.rb
ruby generate-chimei.rb

cd ../edict/
ruby modify-edict2.rb

cd ../jawiki-articles/
ruby convert-jawiki-ut-to-mozc.rb
ruby ../src/filter-entries.rb mozcdic-ut-jawiki.txt

cd ../jinmei-ut/
ruby modify-jinmei-ut.rb

cd ../neologd/
ruby convert-neologd-to-mozc.rb
ruby ../src/filter-entries.rb mozcdic-ut-neologd.txt

cd ../skkdic/
ruby modify-skkdic.rb

cd ../sudachidict/
ruby convert-sudachiduct-to-mozc.rb
ruby ../src/filter-entries.rb mozcdic-ut-sudachidict-*.txt

cd ../src/


# ==============================================================================
# Extract new entries and apply jawiki costs
# ==============================================================================

if [[ $altcannadic = "true" ]]; then
cat ../alt-cannadic/mozcdic-ut-altcanna*.txt >> mozcdic-ut-$UTDICDATE.txt
fi

if [[ $chimei = "true" ]]; then
cat ../chimei/mozcdic-ut-chimei.txt >> mozcdic-ut-$UTDICDATE.txt
fi

if [[ $edict = "true" ]]; then
cat ../edict/mozcdic-ut-edict2.txt >> mozcdic-ut-$UTDICDATE.txt
fi

if [[ $jawikiarticles = "true" ]]; then
cat ../jawiki-articles/mozcdic-ut-jawiki.txt >> mozcdic-ut-$UTDICDATE.txt
fi

if [[ $jinmeiut = "true" ]]; then
cat ../jinmei-ut/mozcdic-ut-jinmei.txt >> mozcdic-ut-$UTDICDATE.txt
fi

if [[ $neologd = "true" ]]; then
cat ../neologd/mozcdic-ut-neologd.txt >> mozcdic-ut-$UTDICDATE.txt
fi

if [[ $skkdic = "true" ]]; then
cat ../skkdic/mozcdic-ut-skkdic.txt >> mozcdic-ut-$UTDICDATE.txt
fi

if [[ $sudachidict = "true" ]]; then
cat ../sudachidict/mozcdic-ut-sudachidict-*.txt >> mozcdic-ut-$UTDICDATE.txt
fi

ruby remove-duplicates.rb mozcdic-ut-$UTDICDATE.txt
ruby apply-jawiki-costs.rb mozcdic-ut-$UTDICDATE.txt.nodup
rm mozcdic-ut-$UTDICDATE.txt
mv mozcdic-ut-$UTDICDATE.txt.nodup ../mozcdic-ut-$UTDICDATE.txt


# ==============================================================================
# Make a mozcdic-ut package
# ==============================================================================

cd ../../
rm -rf mozcdic-ut-$UTDICDATE
rsync -av mozcdic-ut-dev/* mozcdic-ut-$UTDICDATE --exclude=id.def \
--exclude=jawiki-latest* --exclude=jawiki-ut.txt --exclude=KEN_ALL.* --exclude=*.csv \
--exclude=*.xml --exclude=*.gz --exclude=*.bz2 --exclude=*.xz --exclude=*.zip --exclude=*/mozcdic*.txt*
