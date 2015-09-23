# Photo Filename To Meta
This is a very specific app that extracts the date and title from an image filename and adds the information to the file as meta data with the help of ExifTool (http://www.sno.phy.queensu.ca/~phil/exiftool).

The reason for this project is that my dad have a bunch of "pre digital camera" photos that he have scanned (and will continue to scan) and saved with a filename that starts with a date, or an approximate date, and then a short description of the photo. He wants to add the photos to the OS X Photos app (I guess it will work just fine with other apps as well), and have the photos sorted in a correct timeline.

## Filename format
The title meta data will simply be created by taking the filename and exclude the file extension.

For the date meta data to be added the date needs to be at the beginning of the filename in a `[YYYY]-[MM]-[dd]-[ss]` format like in one of the following examples:

1. `1985-09-23 Photo description.jpg`
2. `198?-??-?? Photo description.jpg`
3. `1985-00-00 Photo description.jpg`
4. `1985-09-23-01 Photo description.jpg`

The first case is pretty straight forward. In case number two, the application will default to `1980-01-01 00:00:00`, since the full filename will be added to the file it will still be obivious that the date is unsure and not nessarly from the new year's eve party. Case number three will work the same as case number two and the result will be `1985-01-01 00:00:00`. In case number four the extra two digits works as an enumeration (in case you know the order the photos were taken in) and will be added to the date meta data as seconds, the result would be `1985-09-23 00:00:01`.

## File types
The supported file types are ".jpg", ".tiff" and ".gif". Note that although the meta data will be written to the ".gif" files the OS X Photos app will currently ignore those meta data tags.

## OS X App
The first version of the app supports OS X 10.10 (Yosemite) and OS X 10.11 (El Capitan) and can be downloaded here, https://github.com/jonasrydenhag/Photo-Filename-To-Meta/releases/download/v0.1-beta/Photo.Meta.app.zip.

## Bash script
This application is based on a bash script that I created. It can be found here, https://github.com/jonasrydenhag/Photo-Filename-To-Meta-Bash
