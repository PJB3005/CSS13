/**********************Unloading unit**************************/

/obj/machinery/mineral/unloading_machine
	name = "unloading machine"
	icon = 'icons/obj/machines/mining_machines.dmi'
	icon_state = "unloader"
	density = 1
	anchored = 1
	machine_flags = SCREWTOGGLE | CROWDESTROY | MULTITOOL_MENU

	var/atom/movable/mover //Virtual atom used to check passing ability on the out turf.

	var/in_dir	= 8
	var/out_dir	= 4

	var/max_moved = 100

/obj/machinery/mineral/unloading_machine/New()
	..()

	component_parts = newlist(
		/obj/item/weapon/circuitboard/unloader,
		/obj/item/weapon/stock_parts/matter_bin,
		/obj/item/weapon/stock_parts/matter_bin,
		/obj/item/weapon/stock_parts/matter_bin,
		/obj/item/weapon/stock_parts/capacitor
	)

	RefreshParts()

	mover = new

/obj/machinery/mineral/unloading_machine/RefreshParts()
	var/T = 0
	for(var/obj/item/weapon/stock_parts/matter_bin/bin in component_parts)
		T += bin.rating
	max_moved = initial(max_moved) * (T / 3)

	T = 0 //reusing T here because muh RAM.
	for(var/obj/item/weapon/stock_parts/capacitor/C in component_parts)
		T += C.rating - 1
	idle_power_usage = initial(idle_power_usage) - (T * (initial(idle_power_usage) / 4))//25% power usage reduction for an advanced capacitor, 50% for a super one.

/obj/machinery/mineral/unloading_machine/process()
	if(stat & (NOPOWER | BROKEN))
		return

	var/turf/I = get_step(src, in_dir)
	var/turf/O = get_step(src, out_dir)

	if(!O.CanPass(mover, O) || !O.Enter(mover))
		return

	var/moved_this_tick = 0

	for(var/obj/structure/ore_box/B in I)
		for(var/ore_id in B.materials.storage)
			var/datum/material/mat = B.materials.getMaterial(ore_id)
			var/n = B.materials.getAmount(ore_id)

			if(n <= 0 || !mat.oretype)
				continue

			for(var/i = 0; i < n; i++)
				new mat.oretype(O)
				B.materials.removeAmount(ore_id, 1)

				moved_this_tick++
				if(moved_this_tick >= max_moved)
					return

	for(var/obj/item/IO in I)
		IO.forceMove(O)

		moved_this_tick++
		if(moved_this_tick >= max_moved)
			return

/obj/machinery/mineral/unloading_machine/multitool_menu(var/mob/user, var/obj/item/device/multitool/P)
	return {"
		<ul>
			<li><b>Input: </b><a href='?src=\ref[src];changedir=1'>[capitalize(dir2text(in_dir))]</a></li>
			<li><b>Output: </b><a href='?src=\ref[src];changedir=2'>[capitalize(dir2text(out_dir))]</a></li>
		</ul>
	"}

//For the purposes of this proc, 1 = in, 2 = out.
//Yes the implementation is overkill but I felt bad for hardcoding it with gigantic if()s and shit.
/obj/machinery/mineral/unloading_machine/multitool_topic(mob/user, list/href_list, obj/item/device/multitool/P)
	if("changedir" in href_list)
		var/changingdir = text2num(href_list["changedir"])
		changingdir = Clamp(changingdir, 1, 2)//No runtimes from HREF exploits.

		var/newdir = input("Select the new direction", name, "North") as null|anything in list("North", "South", "East", "West")
		if(!newdir)
			return 1
		newdir = text2dir(newdir)

		var/list/dirlist = list(in_dir, out_dir) //Behold the idea I got on how to do this.
		var/olddir = dirlist[changingdir] //Store this for future reference before wiping it next line.
		dirlist[changingdir] = -1 //Make the dir that's being changed -1 so it doesn't see itself.

		var/conflictingdir = dirlist.Find(newdir) //Check if the dir is conflicting with another one
		if(conflictingdir) //Welp, it is.
			dirlist[conflictingdir] = olddir //Set it to the olddir of the dir we're changing.

		dirlist[changingdir] = newdir //Set the changindir to the selected dir.

		in_dir = dirlist[1]
		out_dir = dirlist[2]

		return MT_UPDATE
		//Honestly I didn't expect that to fit in, what, 10 lines of code?

	return ..()

/obj/machinery/mineral/unloading_machine/Destroy()
	qdel(mover)
	mover = null

	. = ..()
