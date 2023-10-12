#!/bin/bash
trap 'err=$?; echo >&2 "  ERROR: Exiting $0 on error $err"; exit $err' ERR

# TODO: add usage of debconf-set-selections to allow automatic installation of packages that ask questions

if [ "x${software_path_root}" = "x" ] ; then software_path_root=/media/$(id -un)/usb/LM ; fi
if [ "x${work_path}" = "x" ] ; then work_path=/tmp ; fi
packages_to_install="${software_path_root}/packages_to_install.list"
amend_log="${work_path}/amend_errors.log"
debian_archives="${software_path_root}/debian_archives"
separate_debian_packages="${software_path_root}/debs"
distribution="$(awk --field-separator '=' -- '/UBUNTU_CODENAME/{print $2}' /etc/os-release)"
component=main

#
# installing packages downloaded via apt-get with dependencies and where all deb package files are stored in one Debian archive

if [ -d "${debian_archives}" ]; then

    # does NOT work during liveISO amendment as source files is mounted read-only because of thoughts about safety
    # can still serve as guide to run manually
    # Creates package index files used by `apt-get update` (in the code below)
    if [ ! -d "${debian_archives}/dists/${distribution}/${component}/binary-amd64" ]; then
        cd "${debian_archives}"
        mkdir --parents "./dists/${distribution}/${component}/binary-amd64"
        mkdir --parents "./dists/${distribution}/${component}/binary-i386"
        dpkg-scanpackages --multiversion . > "./dists/${distribution}/${component}/binary-amd64/Packages"
        cp "./dists/${distribution}/${component}/binary-amd64/Packages" "./dists/${distribution}/${component}/binary-i386/Packages"
        cd - # change directory back
    fi

    # Note: seems apt/dpkg files location paths are stable: /var/lib/dpkg/status, /etc/apt/sources.list, single file /etc/apt/sources.list.d/official-package-repositories.list, but made hopefully more future proof
    eval $(apt-config shell STATUS_FILE Dir::State::status) # full path
    eval $(apt-config shell ETC_DIR Dir::Etc) # gave etc/apt
    eval $(apt-config shell SOURCES_FILE Dir::Etc::sourcelist) # only last part of path
    eval $(apt-config shell SOURCES_DIR Dir::Etc::sourceparts) # only last part of path
    SOURCES_FILE="/${ETC_DIR}/${SOURCES_FILE}"
    SOURCES_DIR="/${ETC_DIR}/${SOURCES_DIR}"

    # replace original apt sources files
    sudo mv "${SOURCES_DIR}" "${SOURCES_DIR}".bak
    sudo mv "${SOURCES_FILE}" "${SOURCES_FILE}".bak
    sudo mkdir "${SOURCES_DIR}"
    echo "deb [ allow-insecure=yes, trusted=yes ] file:${software_path_root}/debian_archives ${distribution} ${component}" | sudo tee "${SOURCES_FILE}"
    echo -e "    Reading the package(s) index files from newly assigned sources next\n"
    sudo apt-get update
    echo

    # read packages names and install
    cat "${packages_to_install}" | \
    while read line; do
        if [ -n "${line}" ];then # allow for empty lines
            echo -e "    ${line}  to be installed next\n"
            sudo DEBIAN_FRONTEND=noninteractive apt-get install --assume-yes --no-install-recommends "${line}"
            Eval=$?
            if [ $Eval -eq 0 ];then
                echo -e "\n    $line  package installed (at least seems like it)\n"
            else
                echo
                echo "    ERROR:  $line  package NOT installed (at least seems like it)" | 1>&2 sudo tee --append "${amend_log}"
                echo
            fi

        fi # empty line
    done # reading lines of names of packages

    # restore original apt sources files
    sudo rm "${SOURCES_FILE}"
    sudo rmdir "${SOURCES_DIR}"
    sudo mv "${SOURCES_DIR}".bak "${SOURCES_DIR}"
    sudo mv "${SOURCES_FILE}".bak "${SOURCES_FILE}"
    sudo apt-get update

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

exit

[1] 
# -L to follow links, one may create a directory with links for specific install, edit default_local_debs line in apt_get.sh
#find -L "$(./apt_get.sh printpath)" -maxdepth 1 -mindepth 1 -type d -execdir bash -c 'basename $(ls -d1 "{}")' \; | { while read debs_path; do echo $debs_path | ./apt_get.sh -i; done; }
# changed to sort by modification date of folders, newest last; that way latest downloaded are installed last
#find -L "$(./apt_get.sh printpath)" -maxdepth 1 -mindepth 1 -type d -printf "%T@ %Tc %p\n" | sort -n | awk '{print $7}' | xargs -L 1 basename | ./apt_get.sh -i

# ln -s /media/mint/usb/LM_20.2/stress_1 /media/mint/usb/LM_20.tmp
# ln -s /media/mint/usb/LM_20.2/stress-ng_1 /media/mint/usb/LM_20.tmp
# echo stress_1 | apt_get -i # works on liveUSB
