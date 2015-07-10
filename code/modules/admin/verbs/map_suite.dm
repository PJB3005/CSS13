/client/proc/write_map(var/x1 as num, var/y1 as num, var/z1 as num, var/x2 as num, var/y2 as num, var/z2 as num, var/name as text)
	set name = "Save Map"
	set category = "Server"
	set desc = "(x1, y1, z1, x2, x2, y2, map)This will save the map to a valid .dmm file which can be opened by DM, THIS IS VERY LAGGY."

	var/A = alert("Are you sure you want to do this? this WILL lag!", "LAG ALERT", "YES", "NO")

	if(A == "NO")
		return

	var/dmm_suite/DMM = new

	var/T = DMM.write_map(locate(x1, y1, z1), locate(x2, y2, z2), 24)

	if(!T)
		usr << "<span class='warning'>There was an error writing the map, sorry.</span>"

	if(fexists("[name].dmm"))
		fdel("[name].dmm")

	var/F = file("[name].dmm")

	F << T

	usr << browse(F)
	usr << "<span class='notify'>The .dmm file has been sent to your BYOND cache</span>"