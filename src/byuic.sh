#!/bin/bash

###################################################################################################################################
# @package webbgaraget byuic bash compressor
# @version v1.0
# @copyright (c) 2012 Webbgaraget (http://webbgaraget.se)
# @license BSD License - http://www.opensource.org/licenses/bsd-license.php
#
# This is a modified version of the byuic bash compressor (http://wiki.brilaps.com/wikka.php?wakka=byuic)
#
# Usage:
# 1) chmod this script to give it execute permissions 
#  (ex) chmod +x byuic.sh
# 2) Run the script and pass it the path to your web project needing compression and any optional parameters as needed
#  (ex) sh /path/to/byuic.sh -d /path/to/your/project
# 3) Run with -h to see the full usage statement (ex) sh /path/to/byuic.sh -h
###################################################################################################################################

#Track down the YUI Compressor (better than hardcoding the version #)
if ! [ `find /usr/local/bin -type f -name yuicompressor\*.jar` ]
	then
	echo "Unable to locate the YUI Compressor jar file!"
	exit 1
else 
	YUICOMPRESSOR=`find /usr/local/bin -type f -name yuicompressor\*.jar`
fi

#Setup some script defaults
NO_ARGS=0
VALID_WEBDIR=0
PRESERVE_SEMI=""
DISABLE_MICRO_OPT=""
JSWARN=""
MINENDING=0

#Define a usage statement
function usage() {
	echo "Usage: sh byuic.sh -[hnszv]d /path/to/webdirectory)."
	echo "JavaScript Options:"
	echo "-h    Display help/usage information"
	echo "-d    Valid web directory path to act on (should be last parameter with a valid directory path)"
	echo "-m    Create new, .min.js files"
	echo "-n    Minify only, do not obfuscate"
	echo "-s    Preserve all semicolons"
	echo "-z    Disable all micro optimizations"
	echo "-v    Display informational messages and warnings"
}

if [ $# -eq "$NO_ARGS" ]  #Script invoked with no command-line args
	then
	usage
	exit 1 #Exit and explain usage, if no argument(s) given.
elif [ ${1:0:1} != '-' ] #The option list must begin with a '-'
	then
	echo "Invalid option value!"
	usage
	exit 1
fi

while getopts "hnszvmd:path" input
do
	case $input in
		h ) usage
		exit 0;;
		n ) NOMUNGE="--nomunge";;
		s ) PRESERVE_SEMI="--preserve-semi";;
		z ) DISABLE_MICRO_OPT="--disable-optimizations";;
		v ) JSWARN="--verbose";;
		m ) MINENDING=1;;
		d ) WEBDIR="$OPTARG"
		if ! [ -d "$WEBDIR" ]; then
			echo "Invalid web directory specified!"
			exit 1
		else 
			VALID_WEBDIR=1
		fi;; 
	esac
done

if [ $VALID_WEBDIR -eq 0 ] #Should have been set in the while loop if 'd' was provided
	then
	echo "The -d option must be specified last with a valid web directory path!"
	usage
	exit 1
fi

#Process JavaScript files
jslist=`find $WEBDIR -type f -name \*.js -not \( -name \*.min.js \)`
jscount=`find $WEBDIR -type f -name \*.js -not \( -name \*.min.js \) | wc -l` #0 is returned if none are found
totaloldsize=0
totalnewsize=0
for jfile in $jslist
do
	if [ "${jfile:(-7)}" != "-min.js" ] && [ "${jfile:(-7)}" != ".min.js" ] && [ "${jfile:(-9)}" != '.debug.js' ]; then
		echo -n "${jfile}..."
		oldsize=`ls -l ${jfile} | awk '{ print $5 }'`
		if [ $MINENDING == 1 ]; then
			newjfile=${jfile/.js/.min.js}
		else
			newjfile=$jfile
		fi
		java -jar ${YUICOMPRESSOR} --type js ${NOMUNGE} ${PRESERVE_SEMI} ${DISABLE_MICRO_OPT} ${JSWARN} -o ${newjfile} ${jfile} 1>/dev/null 2>>ERRORS
		newsize=`ls -l ${newjfile} | awk '{ print $5 }'`
		if [ $oldsize -ne "0" ] && [ $newsize -ne "0" ]; then
			saved=`echo ${newsize}*100/${oldsize}/100 | bc -l | xargs printf '%1.2f'`
			echo "${saved} (${newsize}/${oldsize})"
		else
			echo "0"
		fi
		totaloldsize=`echo "${totaloldsize} + ${oldsize}" | bc -l`
		totalnewsize=`echo "${totalnewsize} + ${newsize}" | bc -l`
	fi
done
echo -n -e "\033[32mDone compressing JS: \033[0m"
if [ $totaloldsize -ne 0 ]; then
	saved=`echo ${totalnewsize}*100/${totaloldsize}/100 | bc -l | xargs printf %1.2f`
	echo -e "\033[32m${saved} (${totalnewsize}/${totaloldsize})\033[0m"	
else
	echo -e "\033[31mNo files\033[0m"
fi

#Process CSS files
csslist=`find $WEBDIR -type f -name \*.css -not \( -name \*.min.css \)`
csscount=`find $WEBDIR -type f -name \*.css -not \( -name \*.min.css \) | wc -l` #0 is returned if none are found
totaloldsize=0
totalnewsize=0
for cfile in $csslist
do
	if [ "${cfile:(-8)}" != ".min.css" ] && [ "${cfile:(-8)}" != ".min.css" ] && [ "${cfile:(-10)}" != '.debug.css' ]; then
		echo -n "${cfile}..."
		oldsize=`ls -l ${cfile} | awk '{ print $5 }'`
		if [ $MINENDING == 1 ]; then
			newcfile=${cfile/.css/.min.css}
		else
			newcfile=$cfile
		fi
		java -jar ${YUICOMPRESSOR} --type css -o ${newcfile} ${cfile} 1>/dev/null 2>>ERRORS
		newsize=`ls -l ${newcfile} | awk '{ print $5 }'`
		if [ $oldsize -ne "0" ] && [ $newsize -ne "0" ]; then
			saved=`echo ${oldsize}*100/${newsize}/100 | bc -l | xargs printf '%1.2f'`
			echo "${saved} (${oldsize}/${newsize})"
		else
			echo "0"
		fi
		totaloldsize=`echo "${totaloldsize} + ${oldsize}" | bc -l`
		totalnewsize=`echo "${totalnewsize} + ${newsize}" | bc -l`
	fi
done
echo -n -e "\033[32mDone compressing CSS: \033[0m"
if [ $totaloldsize -ne 0 ]; then
	saved=`echo ${totalnewsize}*100/${totaloldsize}/100 | bc -l | xargs printf %1.2f`
	echo -e "\033[32m${saved} (${totalnewsize}/${totaloldsize})\033[0m"	
else
	echo -e "\033[31mNo files\033[0m"
fi

#Exit cleanly
cat ERRORS 2> /dev/null
rm ERRORS 2> /dev/null
exit 0
