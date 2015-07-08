/datum/job/con_worker
	title = "Construction Worker"
	flag = ENGINEER
	department_flag = ENGSEC
	faction = "Station"

	total_positions = -1
	spawn_positions = -1

	supervisors = "Nanotrasen"
	selection_color = "#fff5cc"

	idtype = /obj/item/weapon/card/id/engineering

	access = list(access_eva, access_engine, access_engine_equip, access_tech_storage, access_maint_tunnels, access_external_airlocks, access_construction, access_atmospherics, access_cargo, access_cargo_bot, access_mint, access_mining, access_mining_station)
	minimal_access = list(access_eva, access_engine, access_engine_equip, access_tech_storage, access_maint_tunnels, access_external_airlocks, access_construction, access_atmospherics, access_cargo, access_cargo_bot, access_mint, access_mining, access_mining_station)

	pdaslot=slot_l_store
	pdatype=/obj/item/device/pda/heads/ce

/datum/job/con_worker/equip(var/mob/living/carbon/human/H)
	if(!H)	return 0

	H.equip_or_collect(new /obj/item/device/radio/headset(H), slot_ears)

	switch(H.backbag)
		if(2) H.equip_or_collect(new /obj/item/weapon/storage/backpack/industrial(H), slot_back)
		if(3) H.equip_or_collect(new /obj/item/weapon/storage/backpack/satchel_eng(H), slot_back)
		if(4) H.equip_or_collect(new /obj/item/weapon/storage/backpack/satchel(H), slot_back)
	H.equip_or_collect(new /obj/item/clothing/under/rank/engineer(H), slot_w_uniform)

	H.equip_or_collect(new /obj/item/clothing/shoes/orange(H), slot_shoes)
	H.equip_or_collect(new /obj/item/weapon/storage/belt/utility/full(H), slot_belt)
	H.equip_or_collect(new /obj/item/clothing/head/hardhat(H), slot_head)
	H.equip_or_collect(new /obj/item/device/t_scanner(H), slot_r_store)

	if(H.backbag == 1)
		H.equip_or_collect(new /obj/item/weapon/storage/box/engineer(H), slot_r_hand)
	else
		H.equip_or_collect(new /obj/item/weapon/storage/box/engineer(H.back), slot_in_backpack)
	return 1
