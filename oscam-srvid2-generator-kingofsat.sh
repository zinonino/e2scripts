#!/bin/bash

HEADER="
#################################################################################
### - the script serves as a generator of the 'oscam.srvid2' file
### - based on data parsing from website: http://en.KingOfSat.net/pack-XXXXXX.php
### - script written by s3n0, 2021-03-02: https://github.com/s3n0
#################################################################################
"

#################################################################################

find_oscam_cfg_dir()
{
    RET_VAL=""
    DIR_LIST="/"
    for FOLDER in $DIR_LIST; do
        FILEPATH=$(find "${FOLDER}" -iname "oscam.conf" | head -n 1)
        [ -f "$FILEPATH" ] && { RET_VAL="${FILEPATH%/*.conf}"; break; }
    done

    if [ -z "$RET_VAL" ]; then
        OSCAM_BIN=$(find /usr/bin -iname 'oscam*' | head -n 1)
        if [ -z "$OSCAM_BIN" ]; then
            echo -e "ERROR !\nOscam binary file was not found in folder '/usr/bin'.\nAlso, do not find the Oscam configuration directory.\nThe script will be terminated."
            exit 1
        else
            RET_VAL="$($OSCAM_BIN -V | grep -i 'configdir' | awk '{print substr($2,0,length($2)-1)}')"
        fi
    fi

    [ -z "$RET_VAL" ] && echo "WARNING ! Oscam configuration directory not found !"
    echo "$RET_VAL"
}

#################################################################################

create_srvid_file()
{
    # INPUT ARGUMENTS:
    #    $1 = the URL of the package list of channels with their data, on a specific http://en.KingOfSat.net/pack-XXXXX.php website (see below)
    #    $2 = CAIDs (separated by comma) what is necessary for the provider
    #
    # EXAMPLE:      create_srvid_file "skylink" "0D96,0624"
    #
    # NOTE:         "${1^}" provides the first-character-upper string = "Provider"     "${1^^}" provides the upper-case string = "PROVIDER"     "${1}" provides the string = "provider"     "${1,,}" provides the lower-case string = "provider"
    
    URL="http://en.kingofsat.net/pack-${1,,}.php"
    
    if wget -q -O /tmp/kos.html --no-check-certificate "$URL" > /dev/null 2>&1; then
        echo "URL download successful:   ${URL}"
        
        awk -F '>' -v CAIDS="${2}" -v PROVIDER="${1^^}" -e '
            BEGIN { CHNAME = "invalid" }
            /<i>|class="A3"/ { CHNAME = substr($2,1,length($2) - 3) }
            /class="s">[0-9]+/ {
                SID = substr($2,1,length($2) - 4)
                if (CHNAME == "invalid") next
                printf "%04X:%s|%s|||%s\n", SID, CAIDS, CHNAME, PROVIDER
                CHNAME = "invalid"
              }' /tmp/kos.html > "/tmp/oscam__${1,,}.srvid"
        
        echo -e "The new file was created:  /tmp/oscam__${1,,}.srvid2\n"
        rm -f /tmp/kos.html
    else
        echo "URL download failed !!! URL:  ${URL}"
    fi
}

#################################################################################

echo "$HEADER"

### if the oscam config directory is not found, then use the "/tmp" directory, to avoid a possible error in the variable below:
OSCAM_CFGDIR=$(find_oscam_cfg_dir)
[ -z "$OSCAM_CFGDIR" ] && { echo "WARNING ! The output directory for the 'oscam.srvid2' file was changed to '/tmp' !"; OSCAM_CFGDIR="/tmp"; }

#OSCAM_SRVID="/home/ditev/HDD/zapisi/oscam_-_merged-kingofsat.srvid2"
OSCAM_SRVID="${OSCAM_CFGDIR}/oscam.srvid2"



### create temporary ".srvid" files:
create_srvid_file "skylink" "0D96,0624,FFFE"
create_srvid_file "antiksat" "0B00"
create_srvid_file "orangesk" "0B00,0609"            # some channels are shared to the AntikSat provider (package), so this one "orangesk" package is also needed for "antiksat" (as the CAID=0B00)
create_srvid_file "focussat" "0D97,0B02,1815,0B02"
create_srvid_file "skygermany" "09C4,098C,098D"

#create_srvid_file "focussat" "0B02"
create_srvid_file "digitv" "1802,1880"
#create_srvid_file "mtv" "0B00,0D00"
create_srvid_file "canaldigitalnordic" "0B00"
#create_srvid_file "bbc" "0B00"
create_srvid_file "skydigital" "0963"
create_srvid_file "skyitalia" "0919,093B,09CD"
create_srvid_file "dolcetv" "092F"
#create_srvid_file "hellohd" "0BAA,0000"
create_srvid_file "rai" "183E,183D"
create_srvid_file "bulsatcom" "4AEE"
create_srvid_file "maxtv" "1830"
create_srvid_file "canaldigitaal" "0100@00006A"
create_srvid_file "totaltv" "091F"
create_srvid_file "pink" "0629"
create_srvid_file "vivacom" "09BD"
create_srvid_file "ncplus" "1884,0B01"
create_srvid_file "tvvlaanderen" "0100@00006C"
create_srvid_file "polsat" "1803,1861"




### backup the original file "oscam.srvid" to the "/tmp" dir:
fileSRC="${OSCAM_CFGDIR}/oscam.srvid2"
fileDST="/tmp/oscam_-_backup_$(date '+%Y-%m-%d_%H-%M-%S').srvid2"
[ -f "$fileSRC" ] && { mv "$fileSRC" "$fileDST"; echo -e "The original file was backed up: ${fileSRC} >>> ${fileDST}\n"; }      # backup the old 'oscam.srvid' file

### merge all generated ".srvid" files into one file + move this new file to the Oscam config-dir:
echo "$HEADER" > $OSCAM_SRVID
echo -e "### File creation date: $(date '+%Y-%m-%d %H:%M:%S')\n" >> $OSCAM_SRVID
cat /tmp/oscam__* >> $OSCAM_SRVID
rm -f /tmp/oscam__*
[ -f "$OSCAM_SRVID" ] && echo "All generated '.srvid' files have been merged into one and moved to the directory:  ${OSCAM_SRVID}"




exit 0

#################################################################################
#################################################################################
