#!/bin/bash
trap 'err=$?; echo >&2 "  ERROR: Exiting $0 on error $err"; exit $err' ERR

if [ "x${software_path_root}" = "x" ] ; then software_path_root=/media/$(id -un)/usb/LM ; fi
if [ "x${work_path}" = "x" ] ; then work_path=/tmp ; fi
debian_archives="${software_path_root}/debian_archives"
amend_errors_log="${work_path}/amend_errors.log"
install_debs_log="${work_path}/install_debs.log"
distribution="$(awk --field-separator '=' -- '/UBUNTU_CODENAME/{print $2}' /etc/os-release)"
component=amend
strategy_for_sources=replace # "replace" or "add" (replace previous/official sources with local Debian archive or all the archive to already listed sources)

# for install, update arguments, help message output
# check for availability of common_arguments_to_scripts.sh added for Example 1 of using scripts
commons_path="$(dirname "$(realpath "$0")")"/common_arguments_to_scripts.sh
if [ -e "${commons_path}" ] ; then
    source "${commons_path}"
    # help
    help_message="  The Script is written to update apt sources to set of packages from the location: ${debian_archives} or from path given as argument to the script\n"
    display_help "$help_message$common_help"
else
    if [ "x$1" = "xinstall" ] ; then echo "apt_get not going to be installed due to not locating common_arguments_to_scripts.sh"; exit 1; fi
fi

# ===== #

# if no arguments, use these:
if [ $# -eq 0 ]
  then
    echo "$0 was called without any parameters, in that case default location for deb archives is used: ${debian_archives} with strategy: ${strategy_for_sources}"
else
    debian_archives="${1}"
fi

if [ ! -d "${debian_archives}" ]; then
    echo "    ERROR:  no such folder: ${debian_archives}"  | tee --append "${install_debs_log}" | 1>&2 sudo tee --append "${amend_errors_log}"
    exit 1
fi

# Note: seems apt/dpkg files location paths are stable: /var/lib/dpkg/status, /etc/apt/sources.list, single file /etc/apt/sources.list.d/official-package-repositories.list, but made hopefully more future proof
eval $(apt-config shell STATUS_FILE Dir::State::status) # full path, just in case, line from apt_get
eval $(apt-config shell ETC_DIR Dir::Etc) # assigned variable to "etc/apt"
eval $(apt-config shell SOURCES_FILE Dir::Etc::sourcelist) # only last part of path, assigned variable to "sources.list"
eval $(apt-config shell SOURCES_DIR Dir::Etc::sourceparts) # only last part of path, assigned variable to "sources.list.d"

# man apt.conf: The Dir::State section pertains to local state information
eval $(apt-config shell STATE_DIR Dir::State) # assigned variable to "var/lib/apt"
eval $(apt-config shell LISTS_DIR Dir::State::Lists) # only past part of path, assigned variable to "lists/"; lists is the directory to place downloaded package lists in
eval $(apt-config shell PREFS_DIR Dir::Etc::PreferencesParts) # only past part of path

# creates package index files used by `apt-get update` (in the code below)
if [ ! -d "${debian_archives}/dists/${distribution}/${component}/binary-amd64" ]; then

    Debian_Archives_DIR="/${ETC_DIR}/debian_archives"
    if [ -d "${Debian_Archives_DIR}" ]; then
        echo "    ERROR:  '${Debian_Archives_DIR}' found, probably previous replacement has not been reversed by counterpart of this script (apt_sources_restore.sh), next line is programmed to abort $0 script"  | tee --append "${install_debs_log}" | 1>&2 sudo tee --append "${amend_errors_log}"
        exit 1
    fi
    sudo mkdir --parents "${Debian_Archives_DIR}/dists/${distribution}/${component}/binary-amd64"
    sudo mkdir --parents "${Debian_Archives_DIR}/dists/${distribution}/${component}/binary-i386"
    cd "${Debian_Archives_DIR}"
    for f in "${debian_archives}/"* ; do
        sudo ln --symbolic "${f}"
    done
    dpkg-scanpackages --multiversion . | sudo tee "./dists/${distribution}/${component}/binary-amd64/Packages" > /dev/null
    sudo cp "./dists/${distribution}/${component}/binary-amd64/Packages" "./dists/${distribution}/${component}/binary-i386/Packages"

    debian_archives="${Debian_Archives_DIR}"
    echo -e "\n    '${Debian_Archives_DIR}' is where links to debian archive have been made and 'Packages' files have been generated.\n"
    cd - 1>/dev/null # change directory back
fi

SOURCES_FILE="/${ETC_DIR}/${SOURCES_FILE}"
SOURCES_DIR="/${ETC_DIR}/${SOURCES_DIR%/}" # just in case for the future
INDEX_FILES_DIR="/${STATE_DIR}/${LISTS_DIR%/}" # remove ending "/" (for mv to .bak)
PREFS_FILE_ADD="/${ETC_DIR}/${PREFS_DIR}/amended_iso.pref"

# replace original apt sources files or add one line with local archive
if [ "${strategy_for_sources}" = "replace" ]; then
    sudo mv "${INDEX_FILES_DIR}" "${INDEX_FILES_DIR}".bak
    sudo mkdir "${INDEX_FILES_DIR}"

    sudo mv "${SOURCES_DIR}" "${SOURCES_DIR}".bak
    sudo mkdir "${SOURCES_DIR}"

    source_original=""
elif [ "${strategy_for_sources}" = "add" ]; then
    source_original="$(cat ${SOURCES_FILE})"

    # set priority for local archive (via expectedly unique "component") as higher than linuxmint's official repositories (Pin-Priority: 700). Usage details: `man apt_preferences(5)`
    # TODO: check if possible to allow downgrades for individual packages and how
    # TODO: understand effect of "release" on next line
    echo -e "Package: *\nPin: release c=${component}\nPin-Priority: 900" | sudo tee "${PREFS_FILE_ADD}"
else
    echo "    ERROR:  '${strategy_for_sources}' value for strategy_for_sources w/out code to process it (at least seems like it), next line is programmed to abort $0 script"  | tee --append "${install_debs_log}" | 1>&2 sudo tee --append "${amend_errors_log}"
    exit 1
fi

sudo cp "${SOURCES_FILE}" "${SOURCES_FILE}".bak
{ echo "deb [ allow-insecure=yes, trusted=yes ] file:${debian_archives} ${distribution} ${component}"; printf "${source_original}";} | sudo tee "${SOURCES_FILE}"   
echo -e "\n    Reading the package(s) index files from newly assigned sources is programmed in the code that follows this line\n"
sudo apt-get update # reads index files (aka Package files by man page of dpkg-scanpackages), by observation noted it removes previous files of sources that are no longer in sources lists, so for restoring if strategy is "replace" need to backup those (done via "${INDEX_FILES_DIR}")
echo

