set MAPFILE_TG=tgstation.dmm
set MAPFILE_VG=vgstation.dmm
set MAPFILE_EFF=defficiency.dmm
set MAPFILE_TAX=taxistation.dmm
set MAPFILE_MS=metaclub.dmm
set MAPFILE_DF=dorf.dmm

java -jar MapPatcher.jar -clean ../maps/%MAPFILE_TG%.backup ../maps/%MAPFILE_TG% ../maps/%MAPFILE_TG%
java -jar MapPatcher.jar -clean ../maps/%MAPFILE_VG%.backup ../maps/%MAPFILE_VG% ../maps/%MAPFILE_VG%
java -jar MapPatcher.jar -clean ../maps/%MAPFILE_EFF%.backup ../maps/%MAPFILE_EFF% ../maps/%MAPFILE_EFF%
java -jar MapPatcher.jar -clean ../maps/%MAPFILE_TAX%.backup ../maps/%MAPFILE_TAX% ../maps/%MAPFILE_TAX%
java -jar MapPatcher.jar -clean ../maps/%MAPFILE_MS%.backup ../maps/%MAPFILE_MS% ../maps/%MAPFILE_MS%
java -jar MapPatcher.jar -clean ../maps/%MAPFILE_DF%.backup ../maps/%MAPFILE_DF% ../maps/%MAPFILE_DF%

pause
