//Default list destination taggers and such can use.

var/list/DEFAULT_TAGGER_LOCATIONS = list(
	"Disposals",
	"Cargo Bay",
	"QM Office",
	"Engineering",
	"CE Office",
	"Atmospherics",
	"Security",
	"HoS Office",
	"Medbay",
	"CMO Office",
	"Chemistry",
	"Research",
	"RD Office",
	"Robotics",
	"HoP Office",
	"Library",
	"Chapel",
	"Theatre",
	"Bar",
	"Kitchen",
	"Hydroponics",
	"Janitor Closet",
	"Genetics",
	"Telecomms"
	)

/obj/structure/bigDelivery
	desc = "A big wrapped package."
	name = "large parcel"
	icon = 'icons/obj/storage.dmi'
	icon_state = "deliverycloset"
	var/obj/wrapped = null
	density = 1
	var/sortTag
	flags = FPRINT
	mouse_drag_pointer = MOUSE_ACTIVE_POINTER

/obj/structure/bigDelivery/attack_robot(mob/user)
	if(!Adjacent(user))
		return
	attack_hand(user)

/obj/structure/bigDelivery/attack_hand(mob/user as mob)
	if(wrapped) //sometimes items can disappear. For example, bombs. --rastaf0
		wrapped.forceMove(get_turf(src.loc))
		if(istype(wrapped, /obj/structure/closet))
			var/obj/structure/closet/O = wrapped
			O.welded = 0
	qdel(src)

/obj/structure/bigDelivery/attackby(obj/item/W as obj, mob/user as mob)
	if(istype(W, /obj/item/device/destTagger))
		var/obj/item/device/destTagger/O = W

		if(src.sortTag != O.currTag)
			var/tag = uppertext(O.destinations[O.currTag])
			user << "<span class='notice'>*[tag]*</span>"
			sortTag = tag
			playsound(get_turf(src), 'sound/machines/twobeep.ogg', 100, 1)
			overlays = 0
			overlays += "deliverytag"
			src.desc = "A big wrapped package. It has a label reading [tag]"

	else if(istype(W, /obj/item/weapon/pen))
		var/str = copytext(sanitize(input(usr,"Label text?","Set label","")),1,MAX_NAME_LEN)
		if (!Adjacent(user) || user.stat) return
		if(!str || !length(str))
			usr << "<span class='warning'>Invalid text.</span>"
			return
		for(var/mob/M in viewers())
			M << "<span class='notice'>[user] labels [src] as [str].</span>"
		src.name = "[src.name] ([str])" //needs updating

/obj/item/smallDelivery
	desc = "A small wrapped package."
	name = "small parcel"
	icon = 'icons/obj/storage.dmi'
	icon_state = "deliverycrateSmall"
	var/obj/item/wrapped = null
	var/sortTag
	flags = FPRINT

/obj/item/smallDelivery/attack_self(mob/user as mob)
	if (src.wrapped) //sometimes items can disappear. For example, bombs. --rastaf0
		wrapped.forceMove(user.loc)
		if(ishuman(user))
			user.put_in_hands(wrapped)
		else
			wrapped.forceMove(get_turf(src))

	qdel(src)
	return

/obj/item/smallDelivery/attackby(obj/item/W as obj, mob/user as mob)
	if(istype(W, /obj/item/device/destTagger))
		var/obj/item/device/destTagger/O = W

		if(src.sortTag != O.currTag)
			var/tag = uppertext(O.destinations[O.currTag])
			user << "<span class='notice'>*[tag]*</span>"
			sortTag = tag
			playsound(get_turf(src), 'sound/machines/twobeep.ogg', 100, 1)
			overlays = 0
			overlays += "deliverytag"
			src.desc = "A small wrapped package. It has a label reading [tag]"

	else if(istype(W, /obj/item/weapon/pen))
		var/str = copytext(sanitize(input(usr,"Label text?","Set label","")),1,MAX_NAME_LEN)
		if (!Adjacent(user) || user.stat) return
		if(!str || !length(str))
			usr << "<span class='warning'>Invalid text.</span>"
			return
		for(var/mob/M in viewers())
			M << "<span class='notice'>[user] labels [src] as [str].</span>"
		src.name = "[src.name] ([str])" //also needs updating
	return


/obj/item/weapon/packageWrap
	name = "package wrapper"
	icon = 'icons/obj/items.dmi'
	icon_state = "deliveryPaper"
	w_class = 3.0
	var/amount = 25.0

	var/list/cannot_wrap = list(
		/obj/structure/table,
		/obj/structure/rack,
		/obj/item/smallDelivery,
		/obj/structure/bigDelivery,
		/obj/item/weapon/gift,//real presents are given directly
		/obj/item/weapon/winter_gift,
		/obj/item/weapon/evidencebag,
		/obj/item/weapon/legcuffs/bolas,
		)

/obj/item/weapon/packageWrap/afterattack(var/obj/target as obj, mob/user as mob)
	if(!istype(target))	//this really shouldn't be necessary (but it is).	-Pete
		return
	if(is_type_in_list(target, cannot_wrap))
		return
	if(target.anchored)
		return
	if(target in user)
		return

	user.attack_log += text("\[[time_stamp()]\] <font color='blue'>Has used [src.name] on \ref[target]</font>")


	if (istype(target, /obj/item) && !(istype(target, /obj/item/weapon/storage) && !istype(target,/obj/item/weapon/storage/box)))
		var/obj/item/O = target
		if (src.amount > 1)
			var/obj/item/smallDelivery/P = new /obj/item/smallDelivery(get_turf(O.loc))	//Aaannd wrap it up!
			if(!istype(O.loc, /turf))
				if(user.client)
					user.client.screen -= O
			P.wrapped = O
			O.forceMove(P)
			var/i = round(O.w_class)
			if(i in list(1,2,3,4,5))
				P.icon_state = "deliverycrate[i]"
			P.add_fingerprint(usr)
			O.add_fingerprint(usr)
			src.add_fingerprint(usr)
			src.amount -= 1
	else if (istype(target, /obj/structure/closet/crate))
		var/obj/structure/closet/crate/O = target
		if (src.amount > 3 && !O.opened)
			var/obj/structure/bigDelivery/P = new /obj/structure/bigDelivery(get_turf(O.loc))
			P.icon_state = "deliverycrate"
			P.wrapped = O
			O.forceMove(P)
			P.add_fingerprint(usr)
			O.add_fingerprint(usr)
			src.add_fingerprint(usr)
			src.amount -= 3
		else if(src.amount < 3)
			user << "<span class='notice'>You need more paper.</span>"
	else if (istype (target, /obj/structure/closet))
		var/obj/structure/closet/O = target
		if (src.amount > 3 && !O.opened)
			var/obj/structure/bigDelivery/P = new /obj/structure/bigDelivery(get_turf(O.loc))
			P.wrapped = O
			O.welded = 1
			O.forceMove(P)
			P.add_fingerprint(usr)
			O.add_fingerprint(usr)
			src.add_fingerprint(usr)
			src.amount -= 3
		else if(src.amount < 3)
			user << "<span class='notice'>You need more paper.</span>"
	else if (istype(target, /obj/structure/vendomatpack))
		var/obj/structure/vendomatpack/O = target
		if (src.amount > 1)
			var/obj/structure/bigDelivery/P = new /obj/structure/bigDelivery(get_turf(O.loc))
			P.icon_state = "deliverypack"
			P.wrapped = O
			O.forceMove(P)
			P.add_fingerprint(usr)
			O.add_fingerprint(usr)
			src.add_fingerprint(usr)
			src.amount -= 1
	else if (istype(target, /obj/structure/stackopacks))
		var/obj/structure/stackopacks/O = target
		if (src.amount > 1)
			var/obj/structure/bigDelivery/P = new /obj/structure/bigDelivery(get_turf(O.loc))
			P.icon_state = "deliverystack"
			P.wrapped = O
			O.forceMove(P)
			P.add_fingerprint(usr)
			O.add_fingerprint(usr)
			src.add_fingerprint(usr)
			src.amount -= 1
	else
		user << "<span class='notice'>The object you are trying to wrap is unsuitable for the sorting machinery!</span>"
	if (src.amount <= 0)
		new /obj/item/weapon/c_tube( src.loc )
		qdel(src)
		return
	return

/obj/item/weapon/packageWrap/examine(mob/user)
	..()
	user << "<span class='info'>There are [amount] units of package wrap left!</span>"

/obj/item/device/destTagger
	name = "destination tagger"
	desc = "Used to set the destination of properly wrapped packages."
	icon_state = "dest_tagger"

	var/panel = 0 //If the panel is open.
	var/mode  = 0 //If the tagger is "hacked" so you can add extra tags.

	var/currTag = 0
	var/list/destinations

	w_class = 1
	item_state = "electronic"
	flags = FPRINT
	siemens_coefficient = 1
	slot_flags = SLOT_BELT

/obj/item/device/destTagger/panel
	panel = 1

/obj/item/device/destTagger/panel/New()
	. = ..()
	update_icon()

/obj/item/device/destTagger/New()
	. = ..()
	destinations = DEFAULT_TAGGER_LOCATIONS.Copy() //T-thanks BYOND.

/obj/item/device/destTagger/interact(mob/user as mob)

	var/dat = "<table style='width:100%; padding:4px;'><tr>"

	for (var/i = 1, i <= destinations.len, i++)
		dat += "<td><a href='?src=\ref[src];nextTag=[i]'>[destinations[i]]</a>[mode ? "<a href='?src=\ref[src];remove_dest=[i]' class='linkDanger'>\[X\]</a>" : ""]</td>"

		if (i % 4 == 0)
			dat += "</tr><tr>"

	dat += "</tr></table><br>Current Selection: [currTag ? destinations[currTag] : "None"].<hr><br>"

	if(mode)
		dat += "<a href='?src=\ref[src];new_dest=1'>Add destination</a>"

	var/datum/browser/popup = new(user, "destTagger", name, 380, 350, src)
	popup.add_stylesheet("shared", 'nano/css/shared.css')
	popup.set_content(dat)
	popup.open()

/obj/item/device/destTagger/attack_self(mob/user as mob)
	interact(user)

/obj/item/device/destTagger/attackby(obj/item/W, mob/user)
	if(isscrewdriver(W))
		panel = !panel
		user << "<span class='notify'>You [panel ? "open" : "close"] the panel on \the [src].</span>"
		playsound(get_turf(src), 'sound/items/Screwdriver.ogg', 50, 1)
		update_icon()
		return 1

	if(ismultitool(W) && panel)
		mode = !mode
		user << "<span class='notify'>You [mode ? "disable" : "enable"] the lock on \the [src].</span>"
		return 1

	. = ..()

/obj/item/device/destTagger/update_icon()
	if(panel)
		icon_state = "dest_tagger_p"
		desc += "\nThe panel appears to be open."
	else
		icon_state = "dest_tagger"
		desc = initial(desc)

/obj/item/device/destTagger/Topic(href, href_list)
	. = ..()
	if(.)
		return

	add_fingerprint(usr)

	if(href_list["nextTag"])
		currTag = Clamp(text2num(href_list["nextTag"]), 0, destinations.len)
		interact(usr)
		return 1

	if(href_list["remove_dest"] && mode)
		var/idx = Clamp(text2num(href_list["remove_dest"]), 1, destinations.len)
		destinations -= destinations[idx]
		interact(usr)
		return 1

	if(href_list["new_dest"] && mode)
		var/newtag = uppertext(copytext(sanitize(input(usr, "Destination ID?","Add Destination") as text), 1, MAX_NAME_LEN))
		destinations |= newtag
		interact(usr)
		return 1

/obj/machinery/disposal/deliveryChute
	name = "Delivery chute"
	desc = "A chute for big and small packages alike!"
	density = 1
	icon_state = "intake"
	var/c_mode = 0
	var/doFlushIn=0
	var/num_contents=0

/obj/machinery/disposal/deliveryChute/New()
	..()
	processing_objects.Remove(src)
	spawn(5)
		trunk = locate() in src.loc
		if(trunk)
			trunk.linked = src	// link the pipe trunk to self

/obj/machinery/disposal/deliveryChute/interact()
	return

/obj/machinery/disposal/deliveryChute/update_icon()
	return

/obj/machinery/disposal/deliveryChute/Bumped(var/atom/movable/AM) //Go straight into the chute
	if(istype(AM, /obj/item/projectile) || istype(AM, /obj/item/weapon/dummy))	return
	switch(dir)
		if(NORTH)
			if(AM.loc.y != src.loc.y+1) return
		if(EAST)
			if(AM.loc.x != src.loc.x+1) return
		if(SOUTH)
			if(AM.loc.y != src.loc.y-1) return
		if(WEST)
			if(AM.loc.x != src.loc.x-1) return

	//testing("[src] FUCKING BUMPED BY \a [AM]")

	if(istype(AM, /obj))
		var/obj/O = AM
		O.loc = src
	else if(istype(AM, /mob))
		var/mob/M = AM
		M.loc = src
	//src.flush() This spams audio like fucking crazy.
	// Instead, we queue up for the next process.
	doFlushIn=5 // Ticks, adjust if delay is too long or too short
	num_contents++

/obj/machinery/disposal/deliveryChute/flush()
	flushing = 1
	flick("intake-closing", src)
	var/deliveryCheck = 0
	var/obj/structure/disposalholder/H = new()	// virtual holder object which actually
												// travels through the pipes.
	for(var/obj/structure/bigDelivery/O in src)
		deliveryCheck = 1
		if(O.sortTag == 0)
			O.sortTag = "DISPOSALS"
	for(var/obj/item/smallDelivery/O in src)
		deliveryCheck = 1
		if (O.sortTag == 0)
			O.sortTag = "DISPOSALS"
	if(deliveryCheck == 0)
		H.destinationTag = "DISPOSALS"

	air_contents = new()		// new empty gas resv.

	sleep(10)
	playsound(src, 'sound/machines/disposalflush.ogg', 50, 0, 0)
	sleep(5) // wait for animation to finish

	H.init(src)	// copy the contents of disposer to holder
	num_contents=0
	doFlushIn=0

	H.start(src) // start the holder processing movement
	flushing = 0
	// now reset disposal state
	flush = 0
	if(mode == 2)	// if was ready,
		mode = 1	// switch to charging
	update_icon()
	return

/obj/machinery/disposal/deliveryChute/attackby(var/obj/item/I, var/mob/user)
	if(!I || !user)
		return

	if(istype(I, /obj/item/weapon/screwdriver))
		if(c_mode==0)
			c_mode=1
			playsound(get_turf(src), 'sound/items/Screwdriver.ogg', 50, 1)
			user << "You remove the screws around the power connection."
			return
		else if(c_mode==1)
			c_mode=0
			playsound(get_turf(src), 'sound/items/Screwdriver.ogg', 50, 1)
			user << "You attach the screws around the power connection."
			return
	else if(istype(I,/obj/item/weapon/weldingtool) && c_mode==1)
		var/obj/item/weapon/weldingtool/W = I
		if(W.remove_fuel(0,user))
			playsound(get_turf(src), 'sound/items/Welder2.ogg', 100, 1)
			user << "You start slicing the floorweld off the delivery chute."
			if(do_after(user, src,20))
				if(!src || !W.isOn()) return
				user << "You sliced the floorweld off the delivery chute."
				var/obj/structure/disposalconstruct/C = new (src.loc)
				C.ptype = 8 // 8 =  Delivery chute
				C.update()
				C.anchored = 1
				C.density = 1
				qdel(src)
			return
		else
			user << "You need more welding fuel to complete this task."
			return

/obj/machinery/disposal/deliveryChute/process()
	if(doFlushIn>0)
		if(doFlushIn==1 || num_contents>=50)
			//testing("[src] FLUSHING")
			spawn(0)
				src.flush()
		doFlushIn--

//Base framework for sorting machines.
/obj/machinery/sorting_machine
	name = "Sorting Machine"
	desc = "Sorts stuff."
	density = 1
	icon = 'icons/obj/recycling.dmi'
	icon_state = "grinder-b1"
	anchored = 1

	machine_flags = SCREWTOGGLE | CROWDESTROY | MULTITOOL_MENU

	idle_power_usage = 100 //No active power usage because this thing passively uses 100, always. Don't ask me why N3X15 coded it like this.

	var/atom/movable/mover //Virtual atom used to check passing ability on the out turf.

	var/input_dir = EAST
	var/output_dir = WEST
	var/filter_dir = SOUTH

	var/max_items_moved = 100

/obj/machinery/sorting_machine/New()
	. = ..()

	mover = new

/obj/machinery/sorting_machine/Destroy()
	. = ..()

	qdel(mover)
	mover = null

/obj/machinery/sorting_machine/RefreshParts()
	var/T = 0
	for(var/obj/item/weapon/stock_parts/matter_bin/bin in component_parts)
		T += bin.rating//intentionally not doing '- 1' here, for the math below
	max_items_moved = initial(max_items_moved) * (T / 3) //Usefull upgrade/10, that's an increase from 10 (base matter bins) to 30 (super matter bins)

	T = 0//reusing T here because muh RAM
	for(var/obj/item/weapon/stock_parts/capacitor/C in component_parts)
		T += C.rating - 1
	idle_power_usage = initial(idle_power_usage) - (T * (initial(idle_power_usage) / 4))//25% power usage reduction for an advanced capacitor, 50% for a super one.

/obj/machinery/sorting_machine/process()
	if(stat & (BROKEN | NOPOWER))
		return

	var/turf/in_T = get_step(src, input_dir)
	var/turf/out_T = get_step(src, output_dir)
	var/turf/filter_T = get_step(src, filter_dir)

	if(!out_T.CanPass(mover, out_T) || !out_T.Enter(mover) || !filter_T.CanPass(mover, filter_T) || !filter_T.Enter(mover))
		return

	var/affecting = in_T.contents
	var/items_moved = 0

	for(var/atom/movable/A in affecting)
		if(A.anchored)
			continue

		if(sort(A))
			A.forceMove(filter_T)
		else
			A.forceMove(out_T)

		items_moved++
		if(items_moved >= max_items_moved)
			break

/obj/machinery/sorting_machine/attack_ai(mob/user)
	interact(user)

/obj/machinery/sorting_machine/attack_hand(mob/user)
	interact(user)

/obj/machinery/sorting_machine/Topic(href, href_list)
	. = ..()
	if(.)
		return

	if(href_list["close"])
		if(usr.machine == src)
			usr.unset_machine()
		return 1

	src.add_fingerprint(usr)//After close, else it wouldn't make sense.

/obj/machinery/sorting_machine/multitool_menu(var/mob/user, var/obj/item/device/multitool/P)
	return {"
		<ul>
			<li><b>Sorting directions:</b></li>
			<li><b>Input: </b><a href='?src=\ref[src];changedir=1'>[capitalize(dir2text(input_dir))]</a></li>
			<li><b>Output: </b><a href='?src=\ref[src];changedir=2'>[capitalize(dir2text(output_dir))]</a></li>
			<li><b>Selected: </b><a href='?src=\ref[src];changedir=3'>[capitalize(dir2text(filter_dir))]</a></li>
		</ul>
	"}

//Handles changing of the IO dirs, 'ID's: 1 is input, 2 is output, and 3 is filter, in this proc.

/obj/machinery/sorting_machine/multitool_topic(var/mob/user, var/list/href_list, var/obj/item/device/multitool/P)
	. = ..()
	if(.)
		return .

	if("changedir" in href_list)
		var/changingdir = text2num(href_list["changedir"])
		changingdir = Clamp(changingdir, 1, 3)//No runtimes from HREF exploits.

		var/newdir = input("Select the new direction", "MinerX SortMaster 5000", "North") as null|anything in list("North", "South", "East", "West")
		if(!newdir)
			return 1
		newdir = text2dir(newdir)

		var/list/dirlist = list(input_dir, output_dir, filter_dir)//Behold the idea I got on how to do this.
		var/olddir = dirlist[changingdir]//Store this for future reference before wiping it next line
		dirlist[changingdir] = -1//Make the dir that's being changed -1 so it doesn't see itself.

		var/conflictingdir = dirlist.Find(newdir)//Check if the dir is conflicting with another one
		if(conflictingdir)//Welp, it is.
			dirlist[conflictingdir] = olddir//Set it to the olddir of the dir we're changing

		dirlist[changingdir] = newdir//Set the changindir to the selected dir

		input_dir = dirlist[1]
		output_dir = dirlist[2]
		filter_dir = dirlist[3]

		return MT_UPDATE
		//Honestly I didn't expect that to fit in, what, 10 lines of code?

//Return 1 if the atom is to be filtered of the line.
/obj/machinery/sorting_machine/proc/sort(var/atom/movable/A)
	//writepanic("[__FILE__].[__LINE__] ([src.type])([usr ? usr.ckey : ""])  \\/obj/machinery/sorting_machine/proc/sort() called tick#: [world.time]")
	return prob(50) //Henk because the base sorting machine shouldn't ever exist anyways.

//RECYCLING SORTING MACHINE.
//AKA the old sorting machine until I decided to use the sorting machines in an OOP way for BELT HELL!
/obj/machinery/sorting_machine/recycling
	name = "Recycling Sorting Machine"

	var/list/selected_types = list("Glasses", "Metals/Minerals", "Electronics")
	var/list/types[6]

/obj/machinery/sorting_machine/recycling/New()
	. = ..()

	component_parts = newlist(
		/obj/item/weapon/circuitboard/sorting_machine/recycling,
		/obj/item/weapon/stock_parts/matter_bin,
		/obj/item/weapon/stock_parts/matter_bin,
		/obj/item/weapon/stock_parts/matter_bin,
		/obj/item/weapon/stock_parts/capacitor
	)
	RefreshParts()

	// Set up types. BYOND is the dumb and won't let me do this in the var def.
	types[RECYK_BIOLOGICAL] = "Biological"
	types[RECYK_ELECTRONIC] = "Electronics"
	types[RECYK_GLASS]      = "Glasses"
	types[RECYK_METAL]      = "Metals/Minerals"
	types[RECYK_MISC]       = "Miscellaneous"

/obj/machinery/sorting_machine/recycling/Topic(href, href_list)
	. = ..()
	if(.)
		return

	if(href_list["toggle_types"])
		var/typeID = text2num(href_list["toggle_types"])

		typeID = Clamp(typeID, 1, types.len)//No HREF exploits causing runtimes.

		if(types[typeID] in selected_types)//Toggle these
			selected_types -= types[typeID]
		else
			selected_types += types[typeID]

		updateUsrDialog()
		return 1

/obj/machinery/sorting_machine/recycling/sort(atom/movable/A)
	return A.w_type && (types[A.w_type] in selected_types)

/obj/machinery/sorting_machine/recycling/interact(mob/user)
	if(stat & (BROKEN | NOPOWER))
		if(user.machine == src)
			usr.unset_machine()
		return

	user.set_machine(src)

	var/dat = "Select the desired items to sort from the line.<br>"

	for (var/i = 1, i <= types.len, i++)
		var/selected = (types[i] in selected_types)
		var/cssclass = selected ? "linkOn" : "linkDanger"//Fancy coloured buttons

		dat += "<a href='?src=\ref[src];toggle_types=[i]' class='[cssclass]'>[types[i]]</a><br>"

	var/datum/browser/popup = new(user, "recycksortingmachine", name, 320, 200, src)
	popup.add_stylesheet("shared", 'nano/css/shared.css')
	popup.set_content(dat)
	popup.open()

//Essentially a standalone version of disposals sorting pipes.
/obj/machinery/sorting_machine/destination
	name = "Destination Sorting Machine"
	desc = "Like those disposals pipes sorting machines, except not in a pipe."

	var/list/destinations
	var/list/sorting[0]
	var/unwrapped = 0 //Whatever unwrapped packages should be picked from the line.

/obj/machinery/sorting_machine/destination/New()
	. = ..()

	destinations = DEFAULT_TAGGER_LOCATIONS.Copy() //Here because BYOND.

	for(var/i = 1, i <= destinations.len, i++)
		destinations[i] = uppertext(destinations[i])

	component_parts = newlist(
		/obj/item/weapon/circuitboard/sorting_machine/destination,
		/obj/item/weapon/stock_parts/matter_bin,
		/obj/item/weapon/stock_parts/matter_bin,
		/obj/item/weapon/stock_parts/matter_bin,
		/obj/item/weapon/stock_parts/capacitor
	)
	RefreshParts()

/obj/machinery/sorting_machine/destination/interact(mob/user)
	if(stat & (BROKEN | NOPOWER))
		if(user.machine == src)
			usr.unset_machine()
		return

	user.set_machine(src)

	var/dat = "Select the desired items to sort from the line.<br>"

	for (var/i = 1, i <= destinations.len, i++)
		var/selected = (destinations[i] in sorting)
		var/cssclass = selected ? "linkOn" : "linkDanger" //Fancy coloured buttons

		dat += "<a href='?src=\ref[src];toggle_dest=[i]' class='[cssclass]'>[destinations[i]]</a> <a href='?src=\ref[src];remove_dest=[i]' class='linkDanger'>\[X\]</a><br>"

	dat += "<a href='?src=\ref[src];add_dest=1'>Add a new destination</a> <hr><br>"

	dat += "<a href='?src=\ref[src];toggle_wrapped=1' class='[unwrapped ? "linkOn" : "LinkDanger"]'>Filter unwrapped packages</a>"

	var/datum/browser/popup = new(user, "destsortingmachine", name, 320, 200, src)
	popup.add_stylesheet("shared", 'nano/css/shared.css')
	popup.set_content(dat)
	popup.open()

/obj/machinery/sorting_machine/destination/sort(atom/movable/A)
	if(istype(A, /obj/structure/bigDelivery))
		var/obj/structure/bigDelivery/B = A
		return B.sortTag in sorting

	if(istype(A, /obj/item/smallDelivery))
		var/obj/item/smallDelivery/B = A
		return B.sortTag in sorting

	return unwrapped

/obj/machinery/sorting_machine/destination/Topic(href, href_list)
	. = ..()
	if(.)
		return

	if(href_list["toggle_dest"])
		var/idx = Clamp(text2num(href_list["toggle_dest"]), 0, destinations.len)
		if(destinations[idx] in sorting)
			sorting -= destinations[idx]
		else
			sorting += destinations[idx]
		updateUsrDialog()
		return 1

	if(href_list["remove_dest"])
		var/idx = Clamp(text2num(href_list["remove_dest"]), 0, destinations.len)
		sorting -= destinations[idx]
		destinations -= destinations[idx]
		updateUsrDialog()
		return 1

	if(href_list["add_dest"])
		var/newtag = uppertext(copytext(sanitize(input(usr, "Destination ID?","Add Destination") as text), 1, MAX_NAME_LEN))
		destinations |= newtag
		updateUsrDialog()
		return 1

	if(href_list["toggle_wrapped"])
		unwrapped = !unwrapped
		updateUsrDialog()
		return 1

/obj/machinery/sorting_machine/destination/unwrapped
	unwrapped = 1

/obj/machinery/sorting_machine/destination/taxi_engi
	sorting = list(
		"QM OFFICE",
		"CARGO BAY",
		"JANITOR CLOSET",
		"HOP OFFICE",
		"HYDROPONICS",
		"KITCHEN",
		"THEATRE",
		"BAR",
		"ATMOSPHERICS",
		"CE OFFICE",
		"ENGINEERING"
	)

/obj/machinery/sorting_machine/destination/taxi_engi/unwrapped
	unwrapped = 1

/obj/machinery/sorting_machine/destination/taxi_med
	sorting = list(
		"MEDBAY",
		"CMO OFFICE",
		"CHEMISTRY",
		"GENETICS",
		"RESEARCH",
		"RD OFFICE",
		"TELECOMMS",
		"ROBOTICS"
	)

/obj/machinery/sorting_machine/destination/taxi_secsci
	sorting = list(
		"SECURITY",
		"HOS OFFICE",
		"CHAPEL",
		"LIBRARY"
	)
