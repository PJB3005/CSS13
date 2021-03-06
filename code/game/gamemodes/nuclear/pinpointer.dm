/obj/item/weapon/pinpointer
	name = "pinpointer"
	icon = 'icons/obj/device.dmi'
	icon_state = "pinoff"
	flags = FPRINT
	siemens_coefficient = 1
	slot_flags = SLOT_BELT
	w_class = 2.0
	item_state = "electronic"
	throw_speed = 4
	throw_range = 20
	starting_materials = list(MAT_IRON = 500)
	w_type = RECYK_ELECTRONIC
	melt_temperature = MELTPOINT_STEEL
	var/obj/item/weapon/disk/nuclear/the_disk = null
	var/active = 0


/obj/item/weapon/pinpointer/attack_self()
	if(!active)
		active = 1
		workdisk()
		usr << "<span class='notice'>You activate \the [src]</span>"
		playsound(get_turf(src), 'sound/items/healthanalyzer.ogg', 30, 1)
	else
		active = 0
		icon_state = "pinoff"
		usr << "<span class='notice'>You deactivate \the [src]</span>"

/obj/item/weapon/pinpointer/proc/point_at(atom/target)
	//writepanic("[__FILE__].[__LINE__] ([src.type])([usr ? usr.ckey : ""])  \\/obj/item/weapon/pinpointer/proc/point_at() called tick#: [world.time]")
	if(!active)
		return
	if(!target)
		icon_state = "pinonnull"
		return

	var/turf/T = get_turf(target)
	var/turf/L = get_turf(src)
	if(!T || !L)
		icon_state = "pinonnull"
		return
	if(T.z != L.z)
		icon_state = "pinonnull"
	else
		dir = get_dir(L, T)
		switch(get_dist(L, T))
			if(-1)
				icon_state = "pinondirect"
			if(1 to 8)
				icon_state = "pinonclose"
			if(9 to 16)
				icon_state = "pinonmedium"
			if(16 to INFINITY)
				icon_state = "pinonfar"
	spawn(5)
		.()

/obj/item/weapon/pinpointer/proc/workdisk()
	//writepanic("[__FILE__].[__LINE__] ([src.type])([usr ? usr.ckey : ""])  \\/obj/item/weapon/pinpointer/proc/workdisk() called tick#: [world.time]")
	if(!the_disk)
		the_disk = locate()
	point_at(the_disk)

/obj/item/weapon/pinpointer/examine(mob/user)
	..()
	for(var/obj/machinery/nuclearbomb/bomb in machines)
		if(bomb.timing)
			user << "<span class='danger'>Extreme danger. Arming signal detected. Time remaining: [bomb.timeleft]</span>"


/obj/item/weapon/pinpointer/advpinpointer
	name = "Advanced Pinpointer"
	icon = 'icons/obj/device.dmi'
	desc = "A larger version of the normal pinpointer, this unit features a helpful quantum entanglement detection system to locate various objects that do not broadcast a locator signal."
	var/mode = 0  // Mode 0 locates disk, mode 1 locates coordinates.
	var/turf/location = null
	var/obj/target = null

/obj/item/weapon/pinpointer/advpinpointer/attack_self()
	if(!active)
		active = 1
		if(mode == 0)
			workdisk()
		if(mode == 1)
			point_at(location)
		if(mode == 2)
			point_at(target)
		usr << "<span class='notice'>You activate the pinpointer</span>"
	else
		active = 0
		icon_state = "pinoff"
		usr << "<span class='notice'>You deactivate the pinpointer</span>"


/obj/item/weapon/pinpointer/advpinpointer/verb/toggle_mode()
	set category = "Object"
	set name = "Toggle Pinpointer Mode"
	set src in view(1)

	//writepanic("[__FILE__].[__LINE__] ([src.type])([usr ? usr.ckey : ""]) \\/obj/item/weapon/pinpointer/advpinpointer/verb/toggle_mode()  called tick#: [world.time]")
	active = 0
	icon_state = "pinoff"
	target=null
	location = null

	switch(alert("Please select the mode you want to put the pinpointer in.", "Pinpointer Mode Select", "Location", "Disk Recovery", "Other Signature"))
		if("Location")
			mode = 1

			var/locationx = input(usr, "Please input the x coordinate to search for.", "Location?" , "") as num
			if(!locationx || !(usr in view(1,src)))
				return
			var/locationy = input(usr, "Please input the y coordinate to search for.", "Location?" , "") as num
			if(!locationy || !(usr in view(1,src)))
				return

			var/turf/Z = get_turf(src)

			location = locate(locationx,locationy,Z.z)

			usr << "You set the pinpointer to locate [locationx],[locationy]"


			return attack_self()

		if("Disk Recovery")
			mode = 0
			return attack_self()

		if("Other Signature")
			mode = 2
			switch(alert("Search for item signature or DNA fragment?" , "Signature Mode Select" , "" , "Item" , "DNA"))
				if("Item")
					var/list/item_names[0]
					var/list/item_paths[0]
					for(var/typepath in potential_theft_objectives)
						var/obj/item/tmp_object=new typepath
						var/n="[tmp_object]"
						item_names+=n
						item_paths[n]=typepath
						qdel(tmp_object)
					var/targetitem = input("Select item to search for.", "Item Mode Select","") as null|anything in potential_theft_objectives
					if(!targetitem)
						return
					target=locate(item_paths[targetitem])
					if(!target)
						usr << "Failed to locate [targetitem]!"
						return
					usr << "You set the pinpointer to locate [targetitem]"
				if("DNA")
					var/DNAstring = input("Input DNA string to search for." , "Please Enter String." , "")
					if(!DNAstring)
						return
					for(var/mob/living/carbon/M in mob_list)
						if(!M.dna)
							continue
						if(M.dna.unique_enzymes == DNAstring)
							target = M
							break

			return attack_self()


///////////////////////
//nuke op pinpointers//
///////////////////////


/obj/item/weapon/pinpointer/nukeop
	var/mode = 0	//Mode 0 locates disk, mode 1 locates the shuttle
	var/obj/machinery/computer/syndicate_station/home = null


/obj/item/weapon/pinpointer/nukeop/attack_self(mob/user as mob)
	if(!active)
		active = 1
		if(!mode)
			workdisk()
			user << "<span class='notice'>Authentication Disk Locator active.</span>"
		else
			worklocation()
			user << "<span class='notice'>Shuttle Locator active.</span>"
	else
		active = 0
		icon_state = "pinoff"
		user << "<span class='notice'>You deactivate the pinpointer.</span>"


/obj/item/weapon/pinpointer/nukeop/workdisk()
	if(!active) return
	if(mode)		//Check in case the mode changes while operating
		worklocation()
		return
	if(bomb_set)	//If the bomb is set, lead to the shuttle
		mode = 1	//Ensures worklocation() continues to work
		worklocation()
		playsound(loc, 'sound/machines/twobeep.ogg', 50, 1)	//Plays a beep
		visible_message("Shuttle Locator active.")			//Lets the mob holding it know that the mode has changed
		return		//Get outta here
	if(!the_disk)
		the_disk = locate()
		if(!the_disk)
			icon_state = "pinonnull"
			return
//	if(loc.z != the_disk.z)	//If you are on a different z-level from the disk
//		icon_state = "pinonnull"
//	else
	dir = get_dir(src, the_disk)
	switch(get_dist(src, the_disk))
		if(0)
			icon_state = "pinondirect"
		if(1 to 8)
			icon_state = "pinonclose"
		if(9 to 16)
			icon_state = "pinonmedium"
		if(16 to INFINITY)
			icon_state = "pinonfar"

	spawn(5) .()


/obj/item/weapon/pinpointer/nukeop/proc/worklocation()
	//writepanic("[__FILE__].[__LINE__] ([src.type])([usr ? usr.ckey : ""])  \\/obj/item/weapon/pinpointer/nukeop/proc/worklocation() called tick#: [world.time]")
	if(!active)
		return
	if(!mode)
		workdisk()
		return
	if(!bomb_set)
		mode = 0
		workdisk()
		playsound(loc, 'sound/machines/twobeep.ogg', 50, 1)
		visible_message("<span class='notice'>Authentication Disk Locator active.</span>")
		return
	if(!home)
		home = locate()
		if(!home)
			icon_state = "pinonnull"
			return
	if(loc.z != home.z)	//If you are on a different z-level from the shuttle
		icon_state = "pinonnull"
	else
		dir = get_dir(src, home)
		switch(get_dist(src, home))
			if(0)
				icon_state = "pinondirect"
			if(1 to 8)
				icon_state = "pinonclose"
			if(9 to 16)
				icon_state = "pinonmedium"
			if(16 to INFINITY)
				icon_state = "pinonfar"

	spawn(5) .()

/obj/item/weapon/pinpointer/pdapinpointer
	name = "pda pinpointer"
	desc = "A pinpointer that has been illegally modified to track the PDA of a crewmember for malicious reasons."
	var/obj/target = null
	var/used = 0

/obj/item/weapon/pinpointer/pdapinpointer/attack_self()
	if(!active)
		active = 1
		point_at(target)
		usr << "<span class='notice'>You activate the pinpointer</span>"
	else
		active = 0
		icon_state = "pinoff"
		usr << "<span class='notice'>You deactivate the pinpointer</span>"

/obj/item/weapon/pinpointer/pdapinpointer/verb/select_pda()
	set category = "Object"
	set name = "Select pinpointer target"
	set src in view(1)

	//writepanic("[__FILE__].[__LINE__] ([src.type])([usr ? usr.ckey : ""]) \\/obj/item/weapon/pinpointer/pdapinpointer/verb/select_pda()  called tick#: [world.time]")
	if(used)
		usr << "Target has already been set!"
		return

	var/list/L = list()
	L["Cancel"] = "Cancel"
	var/length = 1
	for (var/obj/item/device/pda/P in world)
		if(P.name != "\improper PDA")
			L[text("([length]) [P.name]")] = P
			length++

	var/t = input("Select pinpointer target. WARNING: Can only set once.") as null|anything in L
	if(t == "Cancel")
		return
	target = L[t]
	if(!target)
		usr << "Failed to locate [target]!"
		return
	active = 1
	point_at(target)
	usr << "You set the pinpointer to locate [target]"
	used = 1


/obj/item/weapon/pinpointer/pdapinpointer/examine(mob/user)
	..()
	if (target)
		user << "<span class='notice'>Tracking [target]</span>"
