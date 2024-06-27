#!/bin/bash
trap 'err=$?; echo >&2 "  ERROR: Exiting $0 on error $err"; exit $err' ERR

# TODO: add usage of debconf-set-selections to allow automatic installation of packages that ask questions

if [ "x${liveiso_path_sources_root}" = "x" ] ; then liveiso_path_sources_root="~/Documents" ; fi
if [ "x${work_path}" = "x" ] ; then work_path=/tmp ; fi
packages_to_install="${liveiso_path_sources_root}/packages_to_install.list"
amend_errors_log="${work_path}/amend_errors.log"
install_debs_log="${work_path}/install_debs.log"

# for install, update arguments, help message output
# check for availability of common_arguments_to_scripts.sh added for Example 1 of using scripts
commons_path="$(dirname "$(realpath "$0")")"/common_arguments_to_scripts.sh
if [ -e "${commons_path}" ] ; then
    source "${commons_path}"
    # help
    help_message="  The Script is written to download debian packages with all dependencies via apt to apt cache.
      Packages to be downloaded are to be listed in a file with format similar to '$(locate packages_to_install.list)'
      One may try to use 'apt_get cp' to copy from cache to current folder afterwards.
      One optional parameter: full path for the file with a list.
      If called w/out any parameters, default location is used : '${packages_to_install}'\n"
    display_help "$help_message$common_help"
else
    if [ "x$1" = "xinstall" ] ; then echo "$(basename $(realpath ${0})) is not going to be installed due to not locating common_arguments_to_scripts.sh"; exit 1; fi
fi

# ----- processing command line arguments ----- #

# if no arguments, use these:
if [ $# -eq 0 ]; then
    echo "$0 was called w/out any parameters, default location is used : '${packages_to_install}'"
fi

if [ $# -eq 1 ]; then
    packages_to_install="${1}"
fi

if [ ! -e "${packages_to_install}" ]; then
    echo "    ERROR: file not found: '${packages_to_install}'" | tee --append "${amend_errors_log}"
    exit 1
fi

# where to put dpkg status file and apt sources temporarity (for script to work, apt might update them?)
apt_dpkg_folder_tmp="$work_path/apt_dpkg_state"
status_file_path_tmp="$apt_dpkg_folder_tmp/dpkg_status"

# noted there are /var/lib/dpkg/status, /etc/apt/sources.list, single file /etc/apt/sources.list.d/official-package-repositories.list, but made hopefully more future proof
eval $(apt-config shell STATUS_FILE Dir::State::status) # full path
eval $(apt-config shell ETC_DIR Dir::Etc) # gave etc/apt
eval $(apt-config shell CACHE Dir::Cache)
eval $(apt-config shell ARCHIVES Dir::Cache::archives)
debs_cache_folder=/${CACHE}/${ARCHIVES} # man bash: brace { after $ "serve to protect the variable to be expanded from characters immediately following it which could be interpreted as part of the name."

# ----- functions definitions ----- #

substitute_status(){
    mkdir --parent "${apt_dpkg_folder_tmp}"
    touch "${status_file_path_tmp}" # make empty file for dpkg status
    copy_status_file_exit_status=$?
    if [ ${copy_status_file_exit_status} -ne 0 ]; then # error
        echo >&2 "Exiting on ERROR, empty dpkg status was NOT created with success"
        exit 1
    fi
    sudo mv $STATUS_FILE $STATUS_FILE.bak;
    sudo ln -s $status_file_path_tmp $STATUS_FILE;
}

restore_status(){
    if [ -d "$apt_dpkg_folder_tmp" ]; then
        if [ $copy_status_file_exit_status -eq 0 ] ; then
            sudo mv --force $STATUS_FILE.bak $STATUS_FILE
            # rm $status_file_path_tmp
        fi
        rm --recursive "$apt_dpkg_folder_tmp"
    fi
}


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

echo -e "\n    Set of  ${packages_list}  debian packages to be downloaded next in a few seconds\n" | tee --append "${install_debs_log}"
sleep 3

substitute_status

sudo DEBIAN_FRONTEND=noninteractive apt-get install --download-only --assume-yes ${packages_list} |& tee --append "${install_debs_log}" # packages_list NOT quoted to allow it to expand to indvividual words (packages)

restore_status

