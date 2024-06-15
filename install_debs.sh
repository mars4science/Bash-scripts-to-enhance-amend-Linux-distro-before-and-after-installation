#!/bin/bash
trap 'err=$?; echo >&2 "  ERROR: Exiting $0 on error $err"; exit $err' ERR

# TODO: add usage of debconf-set-selections to allow automatic installation of packages that ask questions

if [ "x${liveiso_path_sources_root}" = "x" ] ; then liveiso_path_sources_root="/usr/src/amendedliveiso" ; fi
if [ "x${software_path_root}" = "x" ] ; then software_path_root=/media/$(id -un)/usb/LM ; fi
if [ "x${work_path}" = "x" ] ; then work_path=/tmp ; fi
packages_to_install="${liveiso_path_sources_root}/packages_to_install.list"
amend_errors_log="${work_path}/amend_errors.log"
install_debs_log="${work_path}/install_debs.log"
debian_archives="${software_path_root}/debian_archives"
separate_debian_packages="${software_path_root}/debs"
distribution="$(awk --field-separator '=' -- '/UBUNTU_CODENAME/{print $2}' /etc/os-release)"
component=amend
strategy_for_sources=replace # "replace" or "add" (replace previous/official sources with local Debian archive or all the archive to already listed sources)

# a trap below had not helped fully, installing debs one after another is not easy to interrupt
# call above in case of ctrl-c pressed
exit_on_ctrl_c(){
    echo -e "\nERROR: stopped manually"
    exit 0
}
trap 'exit_on_ctrl_c' SIGINT

#
# installing packages downloaded via apt-get with dependencies and where all deb package files are stored in one Debian archive
#
if [ -d "${debian_archives}" ]; then

    # setup apt sources to point to local Debian archive
    apt_sources_replace.sh
    if [ $? -eq 0 ]; then

        # Installing deb files. Note: benchmarking installation of all-on-one-line vs. one-by-one showed ~4.5 minutes duration vs. ~7.5 minute duration - significant improvement; if dependencies are not fully satisfied to failsafe to one-by-one installation took only ~1 second

        # read packages names, remove in-line comments ('%' and/or '#') and blank spaces
        while read line; do
            line="${line##%*}" # remove comments made via '%' symbol - remove symbols to last one if line starts with '%', seems to allow to comment out whole lime; difference with commenting with '#' because deb files themselves often contain '%', but not '#' (package names do not, but just in case); '%' option added because file that is read is as of 2023/11/09 called .list and text editor 'toggle comment' adds '%'
            line="${line%%#*}" # remove comments made via '#' symbol - remove symbols from the end up to last (from end) '#', seems to allow to comment out whole line
            line="${line%% *}" # remove a blank (just in case, and anything after it), how to match one or more blanks only I have not found

            if [ -n "${line}" ];then # allow for empty lines
                packages_list="${packages_list} ${line}"
            fi # empty line
        done < "${packages_to_install}" # reading lines of names of packages, before reading to variable was `cat filename | while read`, but piping creates a subshell and variable assignment happened there (using < fixed it)

        echo -e "\n    Set of  ${packages_list}  debian packages to be installed next in a few seconds\n" | tee --append "${install_debs_log}"
        sleep 3

        sudo DEBIAN_FRONTEND=noninteractive apt-get install --assume-yes ${packages_list} |& tee --append "${install_debs_log}" # packages_list NOT quoted to allow it to expand to indvividual words (packages)

        if [ ${PIPESTATUS[0]} -eq 0 ];then
            echo -e "\n    set of  ${packages_list}  package(s) installed (at least seems like it)\n" | tee --append "${install_debs_log}"

        else
            echo -e "\n    ERROR:  set of  ${packages_list}  package(s) NOT installed (at least seems like it)\n\n    Next is coded to try to install packages separately\n"  | tee --append "${install_debs_log}" | 1>&2 sudo tee --append "${amend_errors_log}"

            packages_array=(${packages_list})
            for line in ${packages_array[@]}; do
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
            done # iterating over array
        fi

        # restore original apt sources files
        apt_sources_restore.sh
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

if [ $(grep --invert-match ', 0 removed' "${install_debs_log}" | grep --quiet --ignore-case 'removed' ;echo $?) -eq 0 ]; then
    echo -e "\n===== Unwanted removals potentially happened      =====" | 1>&2 sudo tee --append "${amend_errors_log}"
    echo -e "  === List of packages below    ===" | 1>&2 sudo tee --append "${amend_errors_log}"
    # grep --invert-match ', 0 removed' "${install_debs_log}" | grep --ignore-case -A 1 'removed' | 1>&2 sudo tee --append "${amend_errors_log}" # replaced with below perl as could be several lines of debs if many

    # searches for parts of file starting with 'REMOVED:' and ending with 'The following', replaces with what's in between and then replaces all after last matched part (assuming it starts with ' NEW packages') with line break. TODO: find out if just selection can be printed in perl, but via substitution operator
    perl -0777 -p -e 's/.*?REMOVED:(.*?)The following/\1/sig;s/ NEW packages.*/\n/si' "${install_debs_log}" | 1>&2 sudo tee --append "${amend_errors_log}" # si modifiers for perl regex: s - makes "." cross line boundaries (alternatively [/s/S] in place of .), i - makes case-insensitive, "?" needed to make regex lazy, otherwise greedy: selects up to past occurence of "export -f", not first (`man perlre`); for -0777 -p -e see `man perlrun`
    echo -e "===== See  ${install_debs_log}  for details       =====\n" | 1>&2 sudo tee --append "${amend_errors_log}"
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
