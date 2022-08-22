#!/bin/bash

DEVICE=$1
REPOS="${@:2}"

d=$(date +%Y%m%d)

FILENAME=$(echo "lineage-17.1-${d}-UNOFFICIAL-${DEVICE}.zip")

mv ../signed-ota_update.zip ../out/target/product/$DEVICE/$FILENAME

oldd=$(grep filename $DEVICE.json | cut -d '-' -f 3)
md5=$(md5sum ../out/target/product/$DEVICE/$FILENAME | cut -d ' ' -f 1)
oldmd5=$(grep '"id"' $DEVICE.json | cut -d':' -f 2)
utc=$(grep ro.build.date.utc ../out/target/product/$DEVICE/system/build.prop | cut -d '=' -f 2)
oldutc=$(grep datetime $DEVICE.json | cut -d ':' -f 2)
size=$(wc -c ../out/target/product/$DEVICE/$FILENAME | cut -d ' ' -f 1)
oldsize=$(grep size $DEVICE.json | cut -d ':' -f 2)
oldurl=$(grep url $DEVICE.json | cut -d ' ' -f 9)

# Generate the Changelog
# Clear the changelog file
echo "" > changelog.txt

for repo in ${REPOS[*]}
do
    echo "########################################" >> changelog.txt
    echo "${repo} Changes:" >> changelog.txt
    git --git-dir ../"${repo}"/.git log --since="${oldutc}" >> changelog.txt
done

echo "########################################" >> changelog.txt

#This is where the magic happens
sed -i "s/$oldmd5/ \"$md5\",/g" $DEVICE.json
sed -i "s/${oldutc}/ \"${utc}\",/g" $DEVICE.json
sed -i "s/${oldsize}/ \"${size}\",/g" $DEVICE.json
#echo Generate Download URL
TAG=$(echo "${DEVICE}-${d}")
url="https://github.com/S-I-M-O-N/Lineage-OTA/releases/download/${TAG}/${FILENAME}"

# sed doesnt wanna replace the filenames date in the url for whatever reason, even though the url is correct
sed -i "s|${oldurl}|\"${url}\",|g" $DEVICE.json
sed -i "s/${oldd}/${d}/g" $DEVICE.json

git add $DEVICE.json
git commit -m "Update ${DEVICE} to ${d}"
git push origin lineage-17.1

#hub release create -a ../out/target/product/$DEVICE/$FILENAME -a changelog.txt -m "${TAG}" "${TAG}"
