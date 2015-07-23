/obj/machinery/atmospherics/binary/msgs
	name = "\improper Magnetically Suspended Gas Storage Unit."
	desc = "Stores large quantities of gas in electro-magnetic suspension."
	icon = 'icons/obj/atmospherics/msgs.dmi'
	icon_state = "on"

	var/target_pressure = 4500	//Output pressure.
	var/on = 0								//Are we taking in gas?

	var/datum/gas_mixture/air				//Internal tank.

	var/datum/html_interface/interface

/obj/machinery/atmospherics/binary/msgs/New()
	. = ..()

	html_machines += src

	interface = new(src, sanitize(name), width = 420, height = 400)	//MSGSses don't have fires inside them, I think.

	air = new

//Here we set the content of the interface.
/obj/machinery/atmospherics/binary/msgs/proc/init_ui()
	var/data = {"
		<h2>
			Gas storage status
		</h2>
		<div class="statusDisplay">
			<div class="statusLabel">Total pressure: 	</div><div class="statusValue"><span id="pressurereadout">0</span> kPa</div><br>
			<div class="statusLabel">Temperature:	 	</div><div class="statusValue"><span id="tempreadout">0</span> K</div><br>
			<hr>
			<div class="statusLabel">Oxygen: 			</div><div class="statusValue"><span id="oxypercent">0</span> %</div><br>
			<div class="statusLabel">Nitrogen: 			</div><div class="statusValue"><span id="nitpercent">0</span> %</div><br>
			<div class="statusLabel">Carbon Dioxide: 	</div><div class="statusValue"><span id="co2percent">0</span> %</div><br>
			<div class="statusLabel">Plasma: 			</div><div class="statusValue"><span id="plapercent">0</span> %</div><br>
			<div class="statusLabel">Nitrous Oxide: 	</div><div class="statusValue"><span id="n2opercent">0</span> %</div><br>
		</div>
		<h2>
			I/O controls
		</h2>
		<div class="item">
			<div class="itemLabel">Input: </div>
			<div class="itemContent">
				<span id="inputtoggles">
					<a href="?src=\ref[interface];power=1">Enable</a> <a href="?src=\ref[interface];power=0" class="linkDanger">Disable</a>
				</span>
			</div>
		</div>
		<br><br>
		<div class="item">
			<div class="itemLabel">Output pressure (kPa): </div>
			<div class="itemContent">
				<form action="?src=\ref[interface]" method="get">
					<span id="pressureinput"><input type="textbox" name="set_pressure" value="0"/></span> <input type="submit" name="act" value="Set"/>
				</form>
			</div>
		</div>
	"}
	interface.updateContent("content", data)

/obj/machinery/atmospherics/binary/msgs/Destroy()
	. = ..()

	html_machines -= src

	air = null

/obj/machinery/atmospherics/binary/msgs/process()
	. = ..()
	if(stat & (NOPOWER | BROKEN))
		return

	//Output handling, stolen from pump code.
	var/output_starting_pressure = air2.return_pressure()

	if((target_pressure - output_starting_pressure) < 0.01)
		//No need to output gas if target is already reached!

		//Calculate necessary moles to transfer using PV=nRT
		if((air.total_moles() > 0) && (air.temperature > 0))
			var/pressure_delta = target_pressure - output_starting_pressure
			var/transfer_moles = pressure_delta * air2.volume / (air1.temperature * R_IDEAL_GAS_EQUATION)

			//Actually transfer the gas
			var/datum/gas_mixture/removed = air.remove(transfer_moles)
			air2.merge(removed)

			if(network2)
				network2.update = 1

	//Input handling.
	if(on)
		var/datum/gas_mixture/removed = air1.remove(air1.total_moles())
		air.merge(removed)

		if(network1)
			network1.update = 1

	updateUsrDialog()

/obj/machinery/atmospherics/binary/msgs/updateUsrDialog()
	if(!interface.inUse())
		return

	interface.updateContent("pressurereadout", air.return_pressure())
	interface.updateContent("tempreadout", air.return_temperature())

	var/total_moles = air.total_moles()
	if(total_moles)
		interface.updateContent("oxypercent", round(100 * air.oxygen			/ total_moles, 0.1))
		interface.updateContent("nitpercent", round(100 * air.nitrogen			/ total_moles, 0.1))
		interface.updateContent("co2percent", round(100 * air.carbon_dioxide	/ total_moles, 0.1))
		interface.updateContent("plapercent", round(100 * air.toxins			/ total_moles, 0.1))

		//Begin stupid shit to get the N2O amount.
		var/datum/gas/sleeping_agent/G = locate(/datum/gas/sleeping_agent) in air.trace_gases
		var/n2o_moles = 0
		if(G)
			n2o_moles = G.moles

		interface.updateContent("n2opercent", round(100 * n2o_moles			/ total_moles, 0.1))

	else
		interface.updateContent("oxypercent", 0)
		interface.updateContent("nitpercent", 0)
		interface.updateContent("co2percent", 0)
		interface.updateContent("plapercent", 0)
		interface.updateContent("n2opercent", 0)

	if(on)
		interface.updateContent("inputtoggles",	{"<a href="?src=\ref[interface];power=1" class="linkOn">Enable</a> <a href="?src=\ref[interface];power=0">Disable</a>"})
	else
		interface.updateContent("inputtoggles",	{"<a href="?src=\ref[interface];power=1">Enable</a> <a href="?src=\ref[interface];power=0" class="linkDanger">Disable</a>"})

	interface.updateContent("pressureinput", 	{"<input type="textbox" name="set_pressure" value="[target_pressure]"/>"})

/obj/machinery/atmospherics/binary/msgs/Topic(href, href_list)
	. = ..()
	if(.)
		return

	if(href_list["power"])
		on = Clamp(text2num(href_list["power"]), 0, 1)
		updateUsrDialog()
		return 1

	if(href_list["set_pressure"])
		target_pressure = round(Clamp(text2num(href_list["set_pressure"]), 0, 4500))
		updateUsrDialog()
		return 1

/obj/machinery/atmospherics/binary/msgs/attack_hand(var/mob/user)
	. = ..()
	if(.)
		return

	interface.show(user)
	updateUsrDialog()

/obj/machinery/atmospherics/binary/msgs/attack_ai(var/mob/user)
	. = attack_hand(user)

/obj/machinery/atmospherics/binary/msgs/power_change()
	. = ..()
	update_icon()

/obj/machinery/atmospherics/binary/msgs/update_icon()
	. = ..()

	overlays.Cut()
	if(node1)
		overlays += "node-1"

	if(node2)
		overlays += "node-2"

	if(!(stat & (NOPOWER | BROKEN)))
		var/p = Clamp(round(target_pressure / 5), 1, 5)

		overlays += "0-[p]"

		overlays += "p"

		if(on)
			overlays += "i"
