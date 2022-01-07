# input file names should not contain space maybe something else...
srch="    title           : "
for i in *; do
  j=`ffmpeg -i "$i" 2>&1 | grep "$srch" | sed "s/^$srch//"`.mp4
  mv -i "$i" "$j"
done
