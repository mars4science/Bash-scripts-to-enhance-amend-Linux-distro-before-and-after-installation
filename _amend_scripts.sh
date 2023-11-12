# support script to avoid saving and commiting regular but temporarily changes to scripts

# change label, original ISO file, keyboard layout languages, etc., add bash fuctions and prepare for reduced set of debs to install (note: symbolic linking does not work on exFAT)

# edit, check path to debs and run from repo's folder
# P.S. at the end some useful code [2]

# for skipping changing a variable one is adviced to try commenting out the line
software_path_root="/media/data/LM1"
base_version="21"
distro_label="GNU-Linux_1.2_b${base_version}" # max 32 symbols as used for ISO volume ID (volume name or label) (`man genisoimage`), maybe some other rules apply
original_iso='${software_path_root}'"/linuxmint-${base_version}-cinnamon-64bit.iso" # ' here as contains $
new_legacy_menu_title="GNU/Linux Cinnamon OS based on LM ${base_version} 64-bit (legacy boot)"
work_path="/media/disk1/work2"
user_name="user2"
locales='("en_US" "de_DE")' # note: string here whereas array in the file to edit
cgroup="gr2" # see [1] for example of usage (in addition of moving process into a group)
cpu_max_mksquashfs="1100000 1000000"

# ----------------------------------------------------------- #

#
# change variables
#
script_path="$(dirname "$(realpath "$0")")" # need to read $0 before folder change via `cd` later as `realpath` just substitutes "." (if script started from where located via ./script_name) with current folder

change_variable(){
    par="$1" # needed for using "an exclamation point (!)" to introduce "a level of indirection" (see man bash). '!$1' does not work because positional parameter is just number w/out '$' however indirection uses variable name and number is not valid variable name
#    if [ "x${!par}" != "x" ] ; then sed -i 's|^'"${par}"'=.*#|'"${par}"'="'"${!par}"'" #|' "${file_to_change}";fi # worked only if line to edit contains comment symbol
    if [ "x${!par}" != "x" ] ; then perl -i -pe 's!^'"${par}"'=.*?(#| #|\n)!'"${par}"'="'"${!par/$/\\$}"'"$1!' "${file_to_change}";fi # '?' for lazy matching, '/$/\\$' to escape possible '$' - make literal symbol, '^' - start of line
}

file_to_change="_make_custom_liveusb.sh"
change_variable software_path_root
change_variable distro_label
change_variable original_iso
change_variable work_path
change_variable new_legacy_menu_title
change_variable cgroup
change_variable cpu_max_mksquashfs
change_variable user_name

# not via change_variable function as locales is an array variable and enclosing in quotation marks right part of assignment command chamges it to incorrect (for purposes of other parts of the scripts) array
perl -i -pe 's/^locales=\(.+?\)/locales='"${locales}"'/' "${file_to_change}"

#
# add bash functions
#
file_to_change="bash_functions_and_other_config.sh"
# length of 1st line to be at least number of symbols to select in variable in a following grep (otherwise part of 2nd line is matched too - amd separately as grep works with single lines)
text_to_add='# tests tests tests tests tests
add_function '\''t_est'\'' '\''
    echo test
'\''
'
grep --quiet "${text_to_add:0:20}" "${file_to_change}"
if [ $? -ne 0 ]; then
    printf "${text_to_add}" | tee --append "${file_to_change}"
fi

# remake dictd links for some long named dictionaries (namaly wikt*-date)
dict_path="${software_path_root}"/to_root/usr/share/dictd/
if [ -d "${dict_path}" ]; then
    for f in "${dict_path}"/* ; do # remove previous links
        if [ -h "${f}" ]; then rm "${f}"; fi
    done
    for f in "${dict_path}"/* ; do
            f="$(basename ${f})"
            ln --symbolic --relative "${dict_path}/${f}" "${dict_path}/${f%%-2*}.${f#*.}"
    done
fi

# end of script
exit


###########################################

# [1]
# set up cgroup to redure CPU load if wanted
set -x
sudo cgcreate -g cpu,cpuset:"${cgroup}"
sudo cgset -r cpu.max="500000 1000000" "${cgroup}" # limit for whole CPU, write quota and period (valid values in the range of 1000 to 1000000) in microseconds, for  performance reasons could be better to use larger periods). Total CPU time in the system equals period multiplied by number of cores/processors
# sudo cgset -r cpuset.cpus="0-3" gr1 # not to use hyperthreading in typical 4 core Intel (list of cores obtained via `lscpu --all --extended`)
sudo cgset -r cpuset.cpus="all" "${cgroup}"
sudo cgexec -g cpu:"${cgroup}" sudo -u `id -un` -g `id -gn` echo "Example of running this line as ordinary user in ${cgroup}"
sudo cgexec -g cpu:"${cgroup}" echo "Example of running this line as root in ${cgroup}"
set +x



# Not run as of 2023/10/12
# make debs_virt folder in not there yet (if v pressed); make links to folder with all debs and rename to debs what's needed
read -p "Choose set of debs: press v key to select reduced set of debs to install, otherwise any other key:" -n 1 -r
echo  # (optional) move to a new line
if [[ $REPLY =~ ^[Vv]$ ]]; then 
    label="${label}"_virt
    if [ -e "${software_path_root}"/debs_virt ]; then
        mv "${software_path_root}"/debs "${software_path_root}"/debs_all
        mv "${software_path_root}"/debs_virt "${software_path_root}"/debs
    elif [ ! -e "${software_path_root}"/debs_all ]; then
        mv "${software_path_root}"/debs "${software_path_root}"/debs_all
        mkdir "${software_path_root}"/debs && cd $_

        # sleep added to copy alphabetical order to modification time order
        # seems unexpected that for same time files order by `ls `-1 --time` is not alphabetical  
        ls -1 ../debs_all | while read line ; do echo $line ; sleep 1 ; ln -s ../debs_all/$line $line ; done
        cat ../debs_to_exclude_for_virt.txt | while read line;do rm $line ; done
        cd "${script_path}" # change current folder back
    fi
else
    if [ -e "${software_path_root}"/debs_all ]; then
        mv "${software_path_root}"/debs "${software_path_root}"/debs_virt
        mv "${software_path_root}"/debs_all "${software_path_root}"/debs
    fi
fi


# [2] Notes, useful code

# Useful to change something in all scripts
find . -name '*.sh' -execdir bash -c 'sed -i '\''s|Exiting $0 on error $err|  ERROR: Exiting $0 on error $err|'\'' "$0"' "{}" \;

# get information of size taken if a package is installed (for set of packages, estimation by APT for each separately)

# Run install_debs.sh with changed `apt-get install` line  to `sudo apt-get install --assume-no ${line}`
# Copy install_debs.log from /tmp somewhere
perl -lne 's/^.*?(?=    )//s; for (split /    /) { print qq($1 $2\n) if /(.*?)  to be installed next.*?After this operation, (.*?) of additional disk space will be used./s }' -0777 <install_debs.log | grep ' ' > perl.txt
# copy perl.txt to Calc

# typical run
clear;.temp/_amend_scripts.sh;date;stopfan 1;./_make_custom_liveusb.sh ;stopfan 0;date

# monitor temperature and free memory during run
clear;date;for (( i=1;i<10000;i++ )); do printf '%5d: ' $i;a=$(date '+%H:%M:%S');printf "$a ";t="$(sensors | grep -i package | awk '{ print "-<- "$4" ->-" }')";printf -- "$t ";free -wm | awk '/^Mem:/ { print "---"$8"---" }';sleep 60;done
