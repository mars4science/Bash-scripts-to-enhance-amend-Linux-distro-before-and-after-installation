#!/bin/bash
# trap 'err=$?; echo >&2 "  ERROR: Exiting $0 on error $err"; exit $err' ERR # commented out as 'apt-get update' is expected to produce errors often

strategy_for_sources=replace # "replace" or "add" (replace previous/official sources with local Debian archive or all the archive to already listed sources)

# for install, update arguments, help message output
# check for availability of common_arguments_to_scripts.sh added for Example 1 of using scripts
commons_path="$(dirname "$(realpath "$0")")"/common_arguments_to_scripts.sh
if [ -e "${commons_path}" ] ; then
    source "${commons_path}"
    # help
    help_message="  The Script is written to restore apt sources if previously replaced by counterpart of this script (apt_sources_replace.sh)\n"
    display_help "$help_message$common_help"
else
    if [ "x$1" = "xinstall" ] ; then echo "apt_get not going to be installed due to not locating common_arguments_to_scripts.sh"; exit 1; fi
fi

# ===== #

# Note: seems apt/dpkg files location paths are stable: /var/lib/dpkg/status, /etc/apt/sources.list, single file /etc/apt/sources.list.d/official-package-repositories.list, but made hopefully more future proof
eval $(apt-config shell STATUS_FILE Dir::State::status) # full path, just in case, line from apt_get
eval $(apt-config shell ETC_DIR Dir::Etc) # assigned variable to "etc/apt"
eval $(apt-config shell SOURCES_FILE Dir::Etc::sourcelist) # only last part of path, assigned variable to "sources.list"
eval $(apt-config shell SOURCES_DIR Dir::Etc::sourceparts) # only last part of path, assigned variable to "sources.list.d"

# man apt.conf: The Dir::State section pertains to local state information
eval $(apt-config shell STATE_DIR Dir::State) # assigned variable to "var/lib/apt"
eval $(apt-config shell LISTS_DIR Dir::State::Lists) # only past part of path, assigned variable to "lists/"; lists is the directory to place downloaded package lists in
eval $(apt-config shell PREFS_DIR Dir::Etc::PreferencesParts) # only past part of path

SOURCES_FILE="/${ETC_DIR}/${SOURCES_FILE}"
SOURCES_DIR="/${ETC_DIR}/${SOURCES_DIR%/}" # just in case for the future
INDEX_FILES_DIR="/${STATE_DIR}/${LISTS_DIR%/}" # remove ending "/" (for mv to .bak)
PREFS_FILE_ADD="/${ETC_DIR}/${PREFS_DIR}/amended_iso.pref"

if [ -e "${SOURCES_FILE}".bak ]; then

    # restore original apt sources files
    if [ "${strategy_for_sources}" = "replace" ]; then
        sudo rm --force --recursive "${INDEX_FILES_DIR}" # that one is expected to be non-empty, but filled via `apt-get update`
        sudo mv "${INDEX_FILES_DIR}".bak "${INDEX_FILES_DIR}"
        sudo rmdir "${SOURCES_DIR}"
        sudo mv "${SOURCES_DIR}".bak "${SOURCES_DIR}"
    fi

    sudo mv --force "${SOURCES_FILE}".bak "${SOURCES_FILE}"

    if [ "${strategy_for_sources}" = "add" ]; then
        sudo rm "${PREFS_FILE_ADD}"
    fi
    sudo apt-get clean # seems deb files from local archive are not copied to apt cache, still just in case there will be downloads
    if [ "${strategy_for_sources}" = "add" ]; then
        echo -e "  A command on next line (apt-get update) is to remove apt state index files for temporary added local Debian archive and re-generate cache. Errors in output are expected if there is no internet connection and in practice had not resulted in failed restoring of initial apt state (in particular of index files).\n"
    elif [ "${strategy_for_sources}" = "replace" ]; then
        echo -e "  A command on next line (apt-get update) is to re-generate cache. Errors in output are expected if there is no internet connection and in practice had not resulted in failed restoring of initial apt state.\n"
    fi
    sudo apt-get update
    echo
    sudo rm --force --recursive "/${ETC_DIR}/debian_archives" # --force: ignore nonexistent files and arguments, never prompt

else
    echo "    ERROR:  '${SOURCES_FILE}.bak' file is not found, likely apt sources have not been replaced by counterpart of this script (apt_sources_replace.sh), next line is programmed to abort $0 script"
    exit 1
fi
