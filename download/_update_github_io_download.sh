#!/bin/bash

source ~/.bashrc 

cd "$(dirname ${BASH_SOURCE})"
DIR=$(pwd)
SCRIPTNAME="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"
IS_ROOT=""
if [[ "$UID" == "0" ]]; then
	IS_ROOT=1
fi

export SHELL=/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:$PATH

if [[ -z "$GITHUB_AUTH_TOKEN" ]];then
	echo "[ERROR] Github Token is not set. Go to https://github.com/settings/tokens to get one with repo scope selected"
	echo "[ERROR] Put it in ~/.bashrc"
	echo "[ERROR] e.g."
	echo "[ERROR] export GITHUB_AUTH_TOKEN=kkjdffdskj9wksdfkkljd"
	exit 1
fi

INDEX_HTML=index.html
INDEX_TPL=index.html.tpl
INDEX_TMP=index.html.tmp

DATE=`date +%Y-%m-%d`

main() {

	initEnv

	downloadAndPush googlechrome.dmg https://dl.google.com/chrome/mac/stable/GGRO/googlechrome.dmg 63000000 __mac64__ __mac64_download__
	downloadAndPush ChromeStandaloneSetup.exe https://dl.google.com/tag/s/appguid%3D%7B8A69D345-D564-463C-AFF1-A69D9E530F96%7D%26iid%3D%7B441B2A72-75A4-3DD0-34BE-5F472CC2CFCD%7D%26lang%3Dzh%26browser%3D3%26usagestats%3D0%26appname%3DGoogle%2520Chrome%26needsadmin%3Dprefers/update2/installers/ChromeStandaloneSetup.exe 45000000 __win32__ __win32_download__
	downloadAndPush ChromeStandaloneSetup64.exe https://dl.google.com/tag/s/appguid%3D%7B8A69D345-D564-463C-AFF1-A69D9E530F96%7D%26iid%3D%7B441B2A72-75A4-3DD0-34BE-5F472CC2CFCD%7D%26lang%3Dzh%26browser%3D3%26usagestats%3D0%26appname%3DGoogle%2520Chrome%26needsadmin%3Dprefers%26ap%3Dx64-stable/update2/installers/ChromeStandaloneSetup64.exe 49000000 __win64__ __win64_download__
	
	afterAll
	updateCronTab
}

initEnv(){
	rm ${INDEX_TMP}
	cp ${INDEX_TPL} ${INDEX_TMP}
	apt-get update -y
	# install jq
	apt-get install zip jq -y
}

updateCronTab(){
	cronFilePath=/etc/cron.d/${SCRIPTNAME}
	cronScriptToEval=$(cat <<HERE_DOC
		echo "6 6 * * 1 root ${DIR}/${SCRIPTNAME}" >  ${cronFilePath}
		cat ${cronFilePath}
		service cron restart
HERE_DOC
)
	if [[ ! -z "${IS_ROOT}" ]];then
		echo "[INFO] Writing crontab" 
		eval "${cronScriptToEval}"
	else
		echo "[INFO] RUN_AS_NON_ROOT: You should execute the script followed to enable crontab job"
		echo "[INFO] Or just rerun this script with sudo" 
		echo "."
		echo -ne "${cronScriptToEval}"
		echo ""
		echo "."
	fi
}

afterAll(){
	replaceIndexHtml
	git add .
	git commit -m "[log] Script ran on ${DATE}"
	git push
	
}


downloadAndPush(){
	FILENAME=$1
	FILE_DOWNLOAD_LINK=$2
	FILESIZE_MIN=$3
	FILE_DATE_PLACEHOLDER=$4
	FILE_DOWNLOAD_LINK_PLACEHOLDER=$5

	RELEASE_RENAMED=Chrome_${DATE}

	OLD_FILESIZE=0
	if [[ -f "${FILENAME}" ]];then
		OLD_FILESIZE=$(stat -c%s "${FILENAME}")
	fi

	wget -O ${FILENAME} ${FILE_DOWNLOAD_LINK}

	FILESIZE=$(stat -c%s "${FILENAME}")

	initLastUpdateDate ${FILENAME}

	ownerAndRepoPartOfReleasing=$( git config --get remote.origin.url | grep -Po 'https:\/\/github\.com\/\K(.*)' )
	# delete release by tag name if any
	urlPrefixOfRelease=https://api.github.com/repos/${ownerAndRepoPartOfReleasing}/releases
	releaseMsg="Google Chrome: ${FILENAME} ${DATE}"

	if [[ ${FILESIZE} > ${FILESIZE_MIN} ]];then
		if [[ "${OLD_FILESIZE}" != "${FILESIZE}" ]]; then
			git add .
			git commit -m "[chrome] Update Google Chrome:${FILENAME}:${FILESIZE}:${DATE}"
			git push
			rm ${FILENAME}.zip
			zip ${FILENAME}.zip ${FILENAME} 
			echo "[INFO] ."
			echo "[INFO] Releasing at ${urlPrefixOfRelease}"
			echo "[INFO] Releasing with tag name ${RELEASE_RENAMED}"
			echo "[INFO] ."
			#echo "[INFO] delete release by tag name if any"
			#curl -H "Authorization: token $GITHUB_AUTH_TOKEN" -X GET ${urlPrefixOfRelease}/tags/${RELEASE_RENAMED} | jq '.id' | xargs -I % curl -H "Authorization: token $GITHUB_AUTH_TOKEN" -X DELETE ${urlPrefixOfRelease}/%
			echo "[INFO] Create Release with tag name: ${RELEASE_RENAMED}"
			isCurlErr=$(curl -H "Authorization: token $GITHUB_AUTH_TOKEN" -d '{"tag_name":"'${RELEASE_RENAMED}'", "name":"'${RELEASE_RENAMED}'", "body": "Released: Google Chrome:'${FILENAME}:${FILESIZE}:${DATE}'"}' -H "Content-Type: application/json" -X POST  ${urlPrefixOfRelease} )
			echo "[INFO] Curl Response: $isCurlErr"
			isCurlErr=$(echo $isCurlErr | jq --raw-output 'try (.errors[] | select(.code!="already_exists")) catch ""')
			
			# get the release created and upload binaries of Chrome
			if [[ -z "$isCurlErr" ]];then
				echo "[INFO] Waiting 10s for Github for syncronising DB for next step"
				sleep 10
			else
				echo "[ERROR] $isCurlErr"
			fi
			
			echo "[INFO] Upload assets to tag name: ${RELEASE_RENAMED}, filename: ${FILENAME}.zip"
			upload_url=$(curl -H "Authorization: token $GITHUB_AUTH_TOKEN" -X GET ${urlPrefixOfRelease}/latest | jq '.upload_url')
			upload_url=${upload_url%\{*}
			upload_url=$(echo $upload_url | sed 's#"##g')
			echo "[INFO] Upload URL: ${upload_url}"
			isCurlErr=$(curl -H "Authorization: token $GITHUB_AUTH_TOKEN" -H "Content-Type: application/zip" --data-binary @${FILENAME}.zip -X POST ${upload_url}?name=${FILENAME}.zip&label="${releaseMsg}")
			echo "[INFO] Curl Response: $isCurlErr"
			isCurlErr=$(echo $isCurlErr | jq --raw-output 'try (.errors[] | select(.code!="already_exists")) catch ""')
			if [[ -z "$isCurlErr" ]];then
				echo "[INFO] Waiting 10s for Github for syncronising DB for next step"
				sleep 10
			else
				echo "[ERROR] $isCurlErr"
				echo "[WARN] Uploading assets failed; You should rerun this script"
			fi
			setLastUpdateDate ${FILENAME} ${DATE}
		else 
			echo "[INFO] Skip git push since identical file size of ${FILENAME}"
		fi
	else
		echo "[ERROR] The file size of ${FILENAME} is ${FILESIZE} which is smaller than expected (mininum: ${FILESIZE_MIN}). Skip git push."
	fi

	releaseAssetLink=$(curl -H "Authorization: token $GITHUB_AUTH_TOKEN" -X GET ${urlPrefixOfRelease}/latest | jq '.assets | .[] | select(.name=="'${FILENAME}.zip'") | .browser_download_url')
	releaseAssetLink=$(echo $releaseAssetLink | sed 's#"##g')
	if [[ -z "${releaseAssetLink}" ]];then
		echo "[WARN] Asset download URL is not generated properly. It might be caused by github DB delay"
		echo "[WARN] Asset download URL is not generated properly. Try rerun this script"
	fi
	echo "[INFO] Asset ${FILENAME}.zip Download URL: ${releaseAssetLink}"

	updateIndexTplDate ${FILE_DATE_PLACEHOLDER} ${FILENAME}
	updateIndexTplDownloadLink ${FILE_DOWNLOAD_LINK_PLACEHOLDER} ${releaseAssetLink}
	
	sleep 5
}

initLastUpdateDate() {
	FILENAME_LOG="$1.log"
	if [[ ! -f ${FILENAME_LOG} ]];then
		setLastUpdateDate  "$1" 
	fi
}

setLastUpdateDate(){
	FILENAME_LOG="$1.log"
	echo ${DATE} > ${FILENAME_LOG}
}

getLastUpdateDate() {
	FILENAME_LOG="$1.log"
	echo "$(cat ${FILENAME_LOG})"
}

updateIndexTplDate(){
	PLACEHOLDER=$1
	FILENAME=$2

	LAST_UPDATE_DATE=$(getLastUpdateDate ${FILENAME})

	sed -i "s/${PLACEHOLDER}/${LAST_UPDATE_DATE}/g" ${INDEX_TMP}
}

updateIndexTplDownloadLink(){
	PLACEHOLDER=$1
	LINK=$2

	sed -i "s#${PLACEHOLDER}#${LINK}#g" ${INDEX_TMP}
}

replaceIndexHtml() {
	rm ${INDEX_HTML}
	mv ${INDEX_TMP} ${INDEX_HTML}
}

main "$@"
