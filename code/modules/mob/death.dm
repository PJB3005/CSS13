//This is the proc for gibbing a mob. Cannot gib ghosts.
//added different sort of gibs and animations. N
/mob/proc/gib()
	//writepanic("[__FILE__].[__LINE__] ([src.type])([usr ? usr.ckey : ""])  \\/mob/proc/gib() called tick#: [world.time]")
	death(1)
	monkeyizing = 1
	canmove = 0
	icon = null
	invisibility = 101

//	anim(target = src, a_icon = 'icons/mob/mob.dmi', /*flick_anim = "dust-m"*/, sleeptime = 15)
	gibs(loc, viruses, dna)

	dead_mob_list -= src

	qdel(src)


//This is the proc for turning a mob into ash. Mostly a copy of gib code (above).
//Originally created for wizard disintegrate. I've removed the virus code since it's irrelevant here.
//Dusting robots does not eject the MMI, so it's a bit more powerful than gib() /N
/mob/proc/dust()
	//writepanic("[__FILE__].[__LINE__] ([src.type])([usr ? usr.ckey : ""])  \\/mob/proc/dust() called tick#: [world.time]")
	death(1)
	monkeyizing = 1
	canmove = 0
	icon = null
	invisibility = 101

//	anim(target = src, a_icon = 'icons/mob/mob.dmi', /*flick_anim = "dust-m"*/, sleeptime = 15)
	new /obj/effect/decal/cleanable/ash(loc)

	dead_mob_list -= src

	qdel(src)


/mob/proc/death(gibbed)
	//writepanic("[__FILE__].[__LINE__] ([src.type])([usr ? usr.ckey : ""])  \\/mob/proc/death() called tick#: [world.time]")
	timeofdeath = world.time

	living_mob_list -= src
	dead_mob_list += src
	for(var/obj/item/I in src)
		I.OnMobDeath(src)
	return ..(gibbed)
