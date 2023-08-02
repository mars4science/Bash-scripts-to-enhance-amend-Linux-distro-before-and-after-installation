#!/bin/bash
# changes some text for some of the system reference manual pages to make them more easily found by apropos and for understanding
# edits man pages in place; pages are expected to be from section 1 (`locate` includes man1)
# expects input file named man_pages_edits.txt at ${software_path_root} location root folder
# input file in a format of triplets of lines with: 1) the system reference manual page name; 2) text to find; 3) text to replace with
# text expected not to have quotations, | (and maybe also / and maybe some other metacharacters) due to code with sed; TODO maybe make universal
# expects one file per archive; TODO maybe make more general code

man_section=man1
if [ "x${software_path_root}" = "x" ] ; then software_path_root=/media/$(id -un)/usb/LM ; fi
man_pages_edits="${software_path_root}/man_pages_edits.txt"

echo "  Processing changes to the system reference manual pages from ${man_pages_edits}"
sudo updatedb # to update database used by `locate`
IFS=''
i=0
while read -r line; do
  ((i++))
  if [ $i -eq 1 ] ; then page="$line" ; fi
  if [ $i -eq 2 ] ; then itext="$line" ; fi
  if [ $i -eq 3 ] ; then 
    i=0
    otext="$line"
# printf "%s\n%s\n%s\n" $page $itext $otext
    if [ $(locate "${page}" man1 gz | wc -l) -ne 1 ] ;  then
      echo "    ERROR: it seems locate cannot find unique gz archive of ${page} in ${man_section}, skipping"
      continue
    fi
    man_page_gzip=$(locate "${page}" "${man_section}" gz)
    if [ $(gzip --list "${man_page_gzip}" | wc -l) -ne 2 ] ; then
      echo "    ERROR: it seems ${man_page_gzip} contains more than 1 file, skipping"
      continue
    fi
# echo "${man_page_gzip}"
    man_page=$(gzip --list "${man_page_gzip}" | tail --lines=1 | awk '{print $4}')
    sudo gzip --keep --uncompress "${man_page_gzip}" # using --keep to keep input (original) file
# echo "${man_page}"
# sed "s|$itext|$otext|" "${man_page}" | grep -- "$itext"
    grep --quiet -- "${itext}" "${man_page}" # -- needed in case "${itext}" starts with "-"
    if [ $? -ne 0 ]; then
      echo "    ERROR: it seems ${man_page} does not contain: ${itext}"
    else
      sudo sed --in-place "s|$itext|$otext|" "${man_page}"
      gzip -c "${man_page}" | 1>/dev/null sudo tee "${man_page_gzip}" # tee w/out --append deletes previous file
    fi
    sudo rm "${man_page}" # gzip can delete input file when decompressing, but seems to not do that when compressing, in the future error here might point for the fact gzip will have changed that
  fi
done < "${man_pages_edits}"

1>/dev/null sudo mandb --create # --create option forces mandb to delete previous databases and re-create them from scratch, and implies --no-purge

