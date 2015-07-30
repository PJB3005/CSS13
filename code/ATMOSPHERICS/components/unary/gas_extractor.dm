#define GAS_PER_ORE 10

//Extracts gas from plasma ore and solid N2O.
//Takes those from the opposite direction.
/obj/machinery/atmospherics/unary/gas_extractor
	name = "\improper Gas Extractor"
	desc = "A machine that extracts gas from plasma or solid N2O. \n The latter is done by simply melting it."

	density		= 1
	anchored	= 0
	state		= 0

	machine_flags = WRENCHMOVE | FIXED2WORK

	var/on				= 0
	var/speed			= 1
	var/max_speed		= 5
	var/max_per_tick	= 20

	var/list/rotate_verbs = list(
	/obj/machinery/atmospherics/unary/gas_extractor/verb/rotate,
	/obj/machinery/atmospherics/unary/gas_extractor/verb/rotate_ccw
	)

	var/datum/html_interface/nanotrasen/interface		//Look fancy interface!

/obj/machinery/atmospherics/unary/gas_extractor/New()
	. = ..()

	if(anchored)
		verbs -= rotate_verbs

	//Do the UI.
	var/const/head = {"<meta http-equiv="X-UA-Compatible" content="IE=edge"/>"}

	interface = new(src, sanitize(name), 560, 240, head)
	init_ui()

	html_machines += src

/obj/machinery/atmospherics/unary/gas_extractor/Destroy()
	. = ..()

	del(interface)

	html_machines -= src

/obj/machinery/atmospherics/unary/gas_extractor/attack_hand(var/mob/user)
	. = ..()
	if(.)
		return

	interface.show(user)

/obj/machinery/atmospherics/unary/gas_extractor/proc/init_ui()
	interface.updateLayout({"
		<div class="item">
			<div class="itemLabel">
				Device power:
			</div>
			<div class="itemContent" id="inputToggles">
				<a href="?src=\ref[interface];power=1" class="linkOn">Enable</a>
				<a href="?src=\ref[interface];power=1">Disable</a>
			</div>
		</div>
		<br>
		<div class="item">
			<div class="itemLabel">
				Device speed multiplier:
			</div>
			<div class="itemContent">
				<form action="?src=\ref[interface]" method="get"><input type="hidden" name="src" value="\ref[interface]"/>
					<span id="speedInput"><input type="textbox" name="setSpeed" value="[speed]" style="width: 50px;"/></span><input type="submit" name="act" value="Set"/><!--I hope nobody ever is stupid enough to need the set button here.-->
				</form>
			</div>
		</div>
		<br>
		<br>
		<div class="statusDisplay">
			<div class="statusLabel">
				Max ore / second:
			</div>
			<div class="statusValue" id="orePS">
				[round((max_per_tick * speed) / 2)]
			</div><br>
			<div class="statusLabel">
				Efficiency:
			</div>
			<div class="statusValue">
				<span id="efficiency">
					[round(((GAS_PER_ORE * (1.5 / speed)) / 15) * 100, 0.1)]
				</span>
				%
			</div>
			<br/>
			<div class="statusLabel">
				Max mol / second:
			</div>
			<div class="statusValue" id="molPS">
				[round((GAS_PER_ORE * (1.5 / speed)) * max_per_tick, 0.1)]
			</div>
			<br/>
		</div>
"})

/obj/machinery/atmospherics/unary/gas_extractor/updateUsrDialog()
	if(!interface.isUsed())
		return

	interface.updateContent("speedInput",		{"<input type="textbox" name="setSpeed" value="[speed]" style="width: 50px;"/>"})

	if(on)
		interface.updateContent("inputToggles",	{"<a href="?src=\ref[interface];power=1" class="linkOn">Enable</a><a href="?src=\ref[interface];power=0">Disable</a>"})
	else
		interface.updateContent("inputToggles",	{"<a href="?src=\ref[interface];power=1">Enable</a><a href="?src=\ref[interface];power=0" class="linkDanger">Disable</a>"})

	interface.updateContent("orePS", 		round((max_per_tick * speed) / 2))	//Divide by 2 because a process is every 2 sec.
	interface.updateContent("efficiency", 	round(((GAS_PER_ORE * (1.5 / speed)) / 15) * 100, 	0.1))
	interface.updateContent("molPS", 		round((GAS_PER_ORE * (1.5 / speed)) * max_per_tick,	0.1))

//Screw having to set a machine.
/obj/machinery/atmospherics/unary/gas_extractor/hiIsValidClient(var/datum/html_interface_client/hclient, var/datum/html_interface/hi)
	if(hclient.client.mob)
		return hclient.client.mob.html_mob_check(src.type)

/obj/machinery/atmospherics/unary/gas_extractor/Topic(var/href, var/list/href_list)
	. = ..()
	if(.)
		return

	if(href_list["power"])
		on = !on
		updateUsrDialog()
		update_icon()
		return 1

	if(href_list["setSpeed"])
		speed = round(Clamp(text2num(href_list["setSpeed"]), 1, 5), 0.1)
		updateUsrDialog()
		update_icon()
		return 1

/obj/machinery/atmospherics/unary/gas_extractor/process()
	if(stat & (NOPOWER | BROKEN) || !on)
		return

	//First we grab things.
	var/found_n2o		= 0
	var/found_plasma	= 0

	var/this_tick		= 0

	//Weapon is the closest to both the N2O and plasma objects.
	for(var/obj/item/weapon/W in get_step(src, turn(dir, 180)))
		if(istype(W, /obj/item/weapon/solid_n2o))
			found_n2o++
			qdel(W)

		else if(istype(W, /obj/item/weapon/ore/plasma))
			found_plasma++
			qdel(W)

		else
			continue

		this_tick++
		if(this_tick >= max_per_tick * speed)
			break

	var/gas_modifier = GAS_PER_ORE * (1.5 / speed)

	//Make the gas.
	//N2O first.
	var/datum/gas/sleeping_agent/N2O = new
	N2O.moles = found_n2o * gas_modifier

	//Add the gasses.
	air_contents.adjust(tx = found_plasma * gas_modifier, traces = list(N2O))

/obj/machinery/atmospherics/unary/gas_extractor/wrenchAnchor(var/mob/user)
	if(on)
		user << "You have to turn off \the [src] first!"
		return
	..()

	if(!anchored)
		verbs += rotate_verbs
		if(node)
			node.disconnect(src)
			del(network)
			node = null

	else
		verbs -= rotate_verbs
		initialize_directions = dir
		initialize()
		build_network()
		if (node)
			node.initialize()
			node.build_network()

/obj/machinery/atmospherics/unary/gas_extractor/verb/rotate()
	set name = "Rotate Clockwise"
	set category = "Object"
	set src in oview(1)

	if (src.anchored || usr.stat)
		usr << "It is fastened to the floor!"
		return 0
	src.dir = turn(src.dir, -90)
	return 1

/obj/machinery/atmospherics/unary/gas_extractor/verb/rotate_ccw()
	set name = "Rotate Counter Clockwise"
	set category = "Object"
	set src in oview(1)

	if (src.anchored || usr.stat)
		usr << "It is fastened to the floor!"
		return 0
	src.dir = turn(src.dir, 90)
	return 1


