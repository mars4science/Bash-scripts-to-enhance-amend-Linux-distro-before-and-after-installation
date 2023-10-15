#!/bin/bash
trap 'err=$?; echo >&2 "  ERROR: Exiting $0 on error $err"; exit $err' ERR

# TODO: add usage of debconf-set-selections to allow automatic installation of packages that ask questions

if [ "x${software_path_root}" = "x" ] ; then software_path_root=/media/$(id -un)/usb/LM ; fi
if [ "x${work_path}" = "x" ] ; then work_path=/tmp ; fi
packages_to_install="${software_path_root}/packages_to_install.list"
amend_errors_log="${work_path}/amend_errors.log"
install_debs_log="${work_path}/install_debs.log"
debian_archives="${software_path_root}/debian_archives"
separate_debian_packages="${software_path_root}/debs"
distribution="$(awk --field-separator '=' -- '/UBUNTU_CODENAME/{print $2}' /etc/os-release)"
component=amend
strategy_for_sources=add # "replace" or "add"

# a trap below had not helped fully, installing debs one after another is not easy to interrupt
# call above in case of ctrl-c pressed
exit_on_ctrl_c(){
    echo -e "\nERROR: stopped manually"
    exit 0
}
trap 'exit_on_ctrl_c' SIGINT

#
# installing packages downloaded via apt-get with dependencies and where all deb package files are stored in one Debian archive

if [ -d "${debian_archives}" ]; then

    # does NOT work during liveISO amendment as source files are mounted read-only because of thoughts about safety
    # can still serve as guide to run manually
    # creates package index files used by `apt-get update` (in the code below)
    if [ ! -d "${debian_archives}/dists/${distribution}/${component}/binary-amd64" ]; then
        cd "${debian_archives}"
        mkdir --parents "./dists/${distribution}/${component}/binary-amd64"
        mkdir --parents "./dists/${distribution}/${component}/binary-i386"
        dpkg-scanpackages --multiversion . > "./dists/${distribution}/${component}/binary-amd64/Packages"
        cp "./dists/${distribution}/${component}/binary-amd64/Packages" "./dists/${distribution}/${component}/binary-i386/Packages"
        cd - # change directory back
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

        # set priority for local archive (via expectedly unique "component") as higher than linuxmint's official repositories (Pin-Priority: 700)
        # TODO: check if possible to allow downgrades for individual packages and how
        # TODO: understand effect of "release" on next line
        echo -e "Package: *\nPin: release c=${component}\nPin-Priority: 900" | sudo tee "${PREFS_FILE_ADD}"
    else
        echo "    ERROR:  '${strategy_for_sources}' value for strategy_for_sources w/out code to process it (at least seems like it), next line is programmed to abort $0 script"  | tee --append "${install_debs_log}" | 1>&2 sudo tee --append "${amend_errors_log}"
        return 1
    fi

    sudo cp "${SOURCES_FILE}" "${SOURCES_FILE}".bak
    { echo "deb [ allow-insecure=yes, trusted=yes ] file:${software_path_root}/debian_archives ${distribution} ${component}"; printf "${source_original}";} | sudo tee "${SOURCES_FILE}"
    echo -e "\n    Reading the package(s) index files from newly assigned sources is programmed in the code that follows this line\n"
    sudo apt-get update # reads index files (aka Package files by man page of dpkg-scanpackages), by observation noted it removes previous files of sources that are no longer in sources lists, so for restoring if strategy is "replace" need to backup those (done via "${INDEX_FILES_DIR}")
    echo

    # read packages names and install
    cat "${packages_to_install}" | \
    while read line; do
        line="${line%%#*}" # remove commands from the end up to last from end #, also seems to allow to comment out whole lime
        line="${line%% *}" # remove a blank, how to match one or more blanks I have not found

        if [ -n "${line}" ];then # allow for empty lines
            echo -e "    ${line}  to be installed next\n" | tee --append "${install_debs_log}"
            sudo DEBIAN_FRONTEND=noninteractive apt-get install --assume-yes "${line}" |& tee --append "${install_debs_log}" # --no-install-recommends deleted from the line as in apt_get recommended dependencies were added as were in the folders of deb files to install all files from
            # man bash: Each  command in a pipeline is executed as a separate process (i.e., in a subshell)
            # pipeline works similarly in e.g. sh, however PIPESTATUS array is Bash-specific, solution is different for sh
            if [ ${PIPESTATUS[0]} -eq 0 ];then
                echo -e "\n    $line  package installed (at least seems like it)\n" | tee --append "${install_debs_log}"
            else
                echo | tee --append "${install_debs_log}"
                echo "    ERROR:  $line  package NOT installed (at least seems like it)"  | tee --append "${install_debs_log}" | 1>&2 sudo tee --append "${amend_errors_log}"
                echo | tee --append "${install_debs_log}"
            fi

        fi # empty line
    done # reading lines of names of packages

    # restore original apt sources files
    if [ "${strategy_for_sources}" = "replace" ]; then
        sudo rm --force --recursive "${INDEX_FILES_DIR}" # that one is expected to be non-empty, but filled via `apt-get update`
        sudo mv "${INDEX_FILES_DIR}".bak "${INDEX_FILES_DIR}"
        sudo rmdir "${SOURCES_DIR}"
        sudo mv "${SOURCES_DIR}".bak "${SOURCES_DIR}"
        sudo rm "${PREFS_FILE_ADD}"
    fi
    sudo mv --force "${SOURCES_FILE}".bak "${SOURCES_FILE}"

    if [ "${strategy_for_sources}" = "add" ]; then
        echo -e "  A command on next line (apt-get update) is to remove apt state index files for temporary added local Debian archive. Errors in output are expected if there is no internet connection and in practice had not resulted in failed restoring of initial apt state (in particular of index files).\n"
        sudo apt-get update
        echo
    fi

fi

#
# installing packages where dependencies were downloaded "manually" and/or packages not for original distro specifically, packages to be placed in a set of similar folders with grouped with dependencies deb files

if [ -d "${separate_debian_packages}" ]; then

    # install all packages from local storage using apt_get.sh
    # as apt_get got altered to output all errors at the end, developer changes this script to run apt_get only once, not for every package.
    # In fact the developed does not recall why longer code [1] have been developed developed in the first place

    # changed to sort by modification date of folders, newest last; that way latest downloaded are installed last
    # Note: trap had not caught when ls output was "No such file or directory"

    ls -1 "${separate_debian_packages}" | ./apt_get.sh -i # (list files by modification time reversed)
#    ls -1tr "${separate_debian_packages}" | ./apt_get.sh -i # (list files by modification time reversed)
    # TODO: understand why there are errors during installation if list of folders with debs is ordered alphabetically (want to switch because consider it more convenient to ensure desired ordering). Part of the cause (hypothesis): Errors are due to diffeent ordering from order in which packages were added.
fi

if [ $(grep --quiet -i 'removed' "${install_debs_log}";echo $?) -eq 0 ]; then
    echo -e "\n===== Unwanted removals potentially happened      =====" | 1>&2 sudo tee --append "${amend_errors_log}"
    echo -e "  === List below by grep, entries separated by --   ===\n" | 1>&2 sudo tee --append "${amend_errors_log}"
    grep -i -A 1 'removed' "${install_debs_log}" | 1>&2 sudo tee --append "${amend_errors_log}"
    echo -e "\n===== See  ${install_debs_log}  for details       =====\n" | 1>&2 sudo tee --append "${amend_errors_log}"
fi

exit

[1] 
# -L to follow links, one may create a directory with links for specific install, edit default_local_debs line in apt_get.sh
#find -L "$(./apt_get.sh printpath)" -maxdepth 1 -mindepth 1 -type d -execdir bash -c 'basename $(ls -d1 "{}")' \; | { while read debs_path; do echo $debs_path | ./apt_get.sh -i; done; }
# changed to sort by modification date of folders, newest last; that way latest downloaded are installed last
#find -L "$(./apt_get.sh printpath)" -maxdepth 1 -mindepth 1 -type d -printf "%T@ %Tc %p\n" | sort -n | awk '{print $7}' | xargs -L 1 basename | ./apt_get.sh -i

# ln -s /media/mint/usb/LM_20.2/stress_1 /media/mint/usb/LM_20.tmp
# ln -s /media/mint/usb/LM_20.2/stress-ng_1 /media/mint/usb/LM_20.tmp
# echo stress_1 | apt_get -i # works on liveUSB
