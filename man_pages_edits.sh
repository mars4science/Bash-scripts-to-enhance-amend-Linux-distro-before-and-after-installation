#!/bin/bash
# changes some text for some of the system reference manual pages to make them more easily found by apropos and for understanding
# edits man pages in place
# expects input file named man_pages_edits.txt at ${software_path_root} location root folder
# input file in a format of triplets of lines with: 1) the system reference manual page name dot section number (e.g. grep.1); 2) text to find; 3) text to replace with
# text is to be rearched and replaced verbatim except \n to be replaced with line breaks
# expects one file per archive; TODO maybe make more general code

# Format of man pages (nroff):
# minus sign "-" is escaped with "\"; where hythen (same ASCII symbol on most keyboards) is expected, so "-" is not escaped. In name section "\-" is used; also for options/switches "\-" was used to allow copy-paste to terminal but seems now just "-" is used as `man` code had been patched to relax that requirement.
# entries in "SEE ALSO" are each on separate line
# many empty lines between sections in source file seems to be displayed by man as one empty line

#man_section=man1
man_section="man" # changed due to: now section number included in input file like grep.1

if [ "x${software_path_root}" = "x" ] ; then software_path_root=/media/$(id -un)/usb/LM ; fi
man_pages_edits="${software_path_root}/to_root/usr/share/src/amendedliveiso/man_pages_edits.txt"

echo "  Processing changes to the system reference manual pages from ${man_pages_edits}"
sudo updatedb # to update database used by `locate`
IFS=''
i=0
while read -r line; do
  ((i++))
  if [ $i -eq 1 ] ; then page="${line}" ; fi
  if [ $i -eq 2 ] ; then itext="${line}" ; fi
  if [ $i -eq 3 ] ; then 
    i=0
    otext="$line"
# printf "%s\n%s\n%s\n" $page $itext $otext
    if [ $(locate "/${page}." "${man_section}" gz | wc -l) -ne 1 ] ;  then
      echo "    ERROR: it seems locate cannot find unique gz archive of ${page} in ${man_section}, skipping" # after adding "/" and "." to ${page} multiples are not expected to happen, only no one found
      continue
    fi
    man_page_gzip=$(locate "/${page}." "${man_section}" gz)
    if [ $(gzip --list "${man_page_gzip}" | wc -l) -ne 2 ] ; then
      echo "    ERROR: it seems ${man_page_gzip} contains more than 1 file, skipping"
      continue
    fi

    man_page=$(gzip --list "${man_page_gzip}" | tail --lines=1 | awk '{print $4}')
    sudo gzip --keep --uncompress "${man_page_gzip}" # using --keep to keep input (original) file

    # replace \n with line breaks
    itext="$(printf "%s" "${itext}" | perl -p -e 's/\Q\n\E/\n/g')"
    otext="$(printf "%s" "${otext}" | perl -p -e 's/\Q\n\E/\n/g')"

    # grep --fixed-strings --quiet -- "${itext}" "${man_page}" # -- needed in case "${itext}" starts with "-"
    # after adding line breaks replaced grep with perl (as grep works with single lines)
    rtext="replaced_replaced_replaced"
    perl -s -0777 -p -e 's/\Q$itext\E/$otext/' -- -itext="${itext}" -otext="${rtext}" "${man_page}" | grep --fixed-strings --quiet -- "${rtext}"

    if [ $? -ne 0 ]; then
      echo "    ERROR: it seems ${man_page} does not contain: ${itext}"
    else

      # sudo sed --in-place "s|${itext}|${otext}|" "${man_page}"
      sudo perl -s -0777 -pi -e 's/\Q$itext\E/$otext/' -- -itext="${itext}" -otext="${otext}" "${man_page}" # this is expected to work with meta characters (backslashes - escapes, etc); per what I've read perl expands variables in replacement once, so it is safe to have $ and @ in replacement variable (but writing $ / @ directily like s//$@/ is expected to result in interpreting symbols after $ / @ as variable names)

      gzip -c "${man_page}" | 1>/dev/null sudo tee "${man_page_gzip}" # tee w/out --append deletes previous file
    fi
    sudo rm "${man_page}" # gzip can delete input file when decompressing, but seems to not do that when compressing, in the future error here might point for the fact gzip will have changed that
  fi
done < "${man_pages_edits}"

1>/dev/null sudo mandb --create # --create option forces mandb to delete previous databases and re-create them from scratch, and implies --no-purge

