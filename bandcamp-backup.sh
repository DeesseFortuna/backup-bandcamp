#!/bin/bash
URL="$1"
ARTIST="$2"

echo ""
echo "Pre-execution cleanup"
rm ./index.html*
rm ./*.list

echo ""
echo "Fetching page..."
wget $URL #get the page

grep -o '"\/album\/.*">' index.html > dirlist.list #grep out the album urls
rm ./index.html* #delete temp index page(s)

sed -e 's/^"//' dirlist.list > dirlist2.list #trim preceding double quote
rm ./dirlist.list

NUMBER=`cat dirlist2.list | wc -l` #get the length of dirlist2 (# of albums)

echo ""
echo "Found" $NUMBER "album directories:"
sed -e 's/">$//' dirlist2.list | sudo tee -a dirlist.list #trim trailing "> and print to console
rm ./dirlist2.list 

sed -e 's/^\/album\///' dirlist.list > albumlist.list #trim preceding /album/
sed -e 's/-/ /g' albumlist.list > albumlist2.list #replace - with ' '
rm ./albumlist.list

while IFS= read -r line; do
	Target=`echo $line | tr [A-Z] [a-z] | sed -e 's/^./\U&/g; s/ ./\U&/g'` #capitalizes the first letter of each word
	echo $Target >> albumlist.list
done < albumlist2.list
rm albumlist2.list

echo ""
echo "Generated these pretty directory names:"
cat albumlist.list

echo ""
echo "Making artist directory..."
mkdir "$ARTIST"

echo ""
echo "Descending to ./" $ARTIST
cd "$ARTIST"

echo ""
echo "Making album directories..."
while IFS= read -r line; do
	mkdir "$line"
	echo "Directory" $line "made."
done < ./../albumlist.list

echo ""
echo "Starting downloads..."

COUNT=1
while IFS= read -r line; do
	echo "Progress: Item #" $COUNT "/" $NUMBER ":"
	ALBUM=`tail -n+$COUNT ./../albumlist.list | head -n1`
	echo "Descending to ./" $ALBUM
	cd "$ALBUM"
	echo "Downloading" $ALBUM
	youtube-dl --audio-quality=0 --audio-format=mp3 -o "%(title)s.%(ext)s" $URL$line
	echo "Ascending..."
	echo ""
	cd ..
	let "COUNT++"
done < ./../dirlist.list

echo ""
echo "Ascending..."
cd ..

echo ""
echo "Cleaning up temp files..."
rm ./*.list


echo ""
echo "Done!"
