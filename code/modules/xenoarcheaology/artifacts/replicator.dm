/obj/machinery/replicator
	name = "alien machine"
	desc = "It's some kind of pod with strange wires and gadgets all over it."
	icon = 'icons/obj/xenoarchaeology.dmi'
	icon_state = "borgcharger0(old)"
	density = 1

	idle_power_usage = 100
	active_power_usage = 1000
	use_power = USE_POWER_IDLE

	var/spawn_progress_time = 0
	var/max_spawn_time = 50
	var/last_process_time = 0

	var/list/construction = list()
	var/list/spawning_types = list()
	var/list/stored_materials = list()

	var/fail_message

/obj/machinery/replicator/Initialize()
	. = ..()

	var/list/viables = list(
	/obj/item/roller,
	/obj/structure/closet/crate,
	/obj/structure/closet/acloset,
	/mob/living/simple_mob/mechanical/viscerator,
	/mob/living/simple_mob/mechanical/hivebot,
	/obj/item/device/analyzer,
	/obj/item/device/camera,
	/obj/item/device/flash,
	/obj/item/device/flashlight,
	/obj/item/device/healthanalyzer,
	/obj/item/device/multitool,
	/obj/item/device/paicard,
	/obj/item/device/radio,
	/obj/item/device/radio/headset,
	/obj/item/device/radio/beacon,
	/obj/item/weapon/autopsy_scanner,
	/obj/item/weapon/bikehorn,
	/obj/item/weapon/surgical/bonesetter,
	/obj/item/weapon/material/knife/butch,
	/obj/item/clothing/suit/caution,
	/obj/item/clothing/head/cone,
	/obj/item/weapon/tool/crowbar,
	/obj/item/weapon/clipboard,
	/obj/item/weapon/cell,
	/obj/item/weapon/surgical/circular_saw,
	/obj/item/weapon/material/knife/machete/hatchet,
	/obj/item/weapon/handcuffs,
	/obj/item/weapon/surgical/hemostat,
	/obj/item/weapon/material/knife,
	/obj/item/weapon/flame/lighter,
	/obj/item/weapon/light/bulb,
	/obj/item/weapon/light/tube,
	/obj/item/weapon/pickaxe,
	/obj/item/weapon/shovel,
	/obj/item/weapon/weldingtool,
	/obj/item/weapon/tool/wirecutters,
	/obj/item/weapon/tool/wrench,
	/obj/item/weapon/tool/screwdriver,
	/obj/item/weapon/grenade/chem_grenade/cleaner,
	/obj/item/weapon/grenade/chem_grenade/metalfoam)

	var/quantity = rand(5, 15)
	for(var/i=0, i<quantity, i++)
		var/button_desc = "a [pick("yellow","purple","green","blue","red","orange","white")], "
		button_desc += "[pick("round","square","diamond","heart","dog","human")] shaped "
		button_desc += "[pick("toggle","switch","lever","button","pad","hole")]"
		var/type = pick(viables)
		viables.Remove(type)
		construction[button_desc] = type

	fail_message = "<font color='blue'>[bicon(src)] a [pick("loud","soft","sinister","eery","triumphant","depressing","cheerful","angry")] \
		[pick("horn","beep","bing","bleep","blat","honk","hrumph","ding")] sounds and a \
		[pick("yellow","purple","green","blue","red","orange","white")] \
		[pick("light","dial","meter","window","protrusion","knob","antenna","swirly thing")] \
		[pick("swirls","flashes","whirrs","goes schwing","blinks","flickers","strobes","lights up")] on the \
		[pick("front","side","top","bottom","rear","inside")] of [src]. A [pick("slot","funnel","chute","tube")] opens up in the \
		[pick("front","side","top","bottom","rear","inside")].</font>"

/obj/machinery/replicator/process()
	if(spawning_types.len && powered())
		spawn_progress_time += world.time - last_process_time
		if(spawn_progress_time > max_spawn_time)
			src.visible_message("<span class='notice'>[bicon(src)] [src] pings!</span>")

			var/obj/source_material = pop(stored_materials)
			var/spawn_type = pop(spawning_types)
			var/obj/spawned_obj = new spawn_type(src.loc)
			if(source_material)
				if(length(source_material.name) < MAX_MESSAGE_LEN)
					spawned_obj.name = "[source_material] " +  spawned_obj.name
				if(length(source_material.desc) < MAX_MESSAGE_LEN * 2)
					if(spawned_obj.desc)
						spawned_obj.desc += " It is made of [source_material]."
					else
						spawned_obj.desc = "It is made of [source_material]."
				qdel(source_material)

			spawn_progress_time = 0
			max_spawn_time = rand(30,100)

			if(!spawning_types.len || !stored_materials.len)
				update_use_power(USE_POWER_IDLE)
				icon_state = "borgcharger0(old)"

		else if(prob(5))
			src.visible_message("<span class='notice'>[bicon(src)] [src] [pick("clicks","whizzes","whirrs","whooshes","clanks","clongs","clonks","bangs")].</span>")

	last_process_time = world.time

/obj/machinery/replicator/attack_hand(mob/user as mob)
	interact(user)

/obj/machinery/replicator/interact(mob/user)
	var/dat = "The control panel displays an incomprehensible selection of controls, many with unusual markings or text around them.<br>"
	dat += "<br>"
	for(var/index=1, index<=construction.len, index++)
		dat += "<A href='?src=\ref[src];activate=[index]'>\[[construction[index]]\]</a><br>"

	user << browse(dat, "window=alien_replicator")

/obj/machinery/replicator/attackby(obj/item/weapon/W as obj, mob/living/user as mob)
	if(!W.canremove || !user.canUnEquip(W)) //No armblades, no grabs. No other-thing-I-didn't-think-of.
		to_chat(user, "<span class='notice'>You cannot put \the [W] into the machine.</span>")
		return
	user.drop_item()
	W.loc = src
	stored_materials.Add(W)
	src.visible_message("<span class='notice'>\The [user] inserts \the [W] into \the [src].</span>")

/obj/machinery/replicator/Topic(href, href_list)

	if(href_list["activate"])
		var/index = text2num(href_list["activate"])
		if(index > 0 && index <= construction.len)
			if(stored_materials.len > spawning_types.len)
				if(spawning_types.len)
					src.visible_message("<span class='notice'>[bicon(src)] a [pick("light","dial","display","meter","pad")] on [src]'s front [pick("blinks","flashes")] [pick("red","yellow","blue","orange","purple","green","white")].</span>")
				else
					src.visible_message("<span class='notice'>[bicon(src)] [src]'s front compartment slides shut.</span>")

				spawning_types.Add(construction[construction[index]])
				spawn_progress_time = 0
				update_use_power(USE_POWER_ACTIVE)
				icon_state = "borgcharger1(old)"
			else
				src.visible_message(fail_message)
