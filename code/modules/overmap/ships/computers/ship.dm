/*
While these computers can be placed anywhere, they will only function if placed on either a non-space, non-shuttle turf
with an /obj/effect/overmap/visitable/ship present elsewhere on that z level, or else placed in a shuttle area with an /obj/effect/overmap/visitable/ship
somewhere on that shuttle. Subtypes of these can be then used to perform ship overmap movement functions.
*/
/obj/machinery/computer/ship
	var/obj/effect/overmap/visitable/ship/linked
	var/list/viewers // Weakrefs to mobs in direct-view mode.
	var/extra_view = 0 // how much the view is increased by when the mob is in overmap mode.
	var/list/whitelisted_types = list(/obj/effect/overmap/visitable/ship)
	var/list/blacklisted_types = list()

/obj/machinery/computer/ship/Initialize()
	. = ..()
	var/list/L = list()
	for(var/type in whitelisted_types)
		L |= typesof(type)
	for(var/type in blacklisted_types)
		L -= typesof(type)
	whitelisted_types = L

// A late init operation called in SSshuttles, used to attach the thing to the right ship.
/obj/machinery/computer/ship/proc/attempt_hook_up(obj/effect/overmap/visitable/sector)
	if(!sector || !(sector.type in whitelisted_types))
		return FALSE
	if(sector.check_ownership(src))
		linked = sector
		return TRUE

/obj/machinery/computer/ship/proc/sync_linked(var/user = null)
	var/obj/effect/overmap/visitable/sector = get_overmap_sector(z)
	if(!sector)
		return
	. = attempt_hook_up_recursive(sector)
	if(. && linked && user)
		to_chat(user, "<span class='notice'>[src] reconnected to [linked]</span>")
		user << browse(null, "window=[src]") // close reconnect dialog

/obj/machinery/computer/ship/proc/attempt_hook_up_recursive(obj/effect/overmap/visitable/sector)
	if(attempt_hook_up(sector))
		return sector
	for(var/obj/effect/overmap/visitable/candidate in sector)
		if((. = .(candidate)))
			return

/obj/machinery/computer/ship/proc/display_reconnect_dialog(var/mob/user, var/flavor)
	var/datum/browser/popup = new (user, "[src]", "[src]")
	popup.set_content("<center><strong><font color = 'red'>Error</strong></font><br>Unable to connect to [flavor].<br><a href='?src=\ref[src];sync=1'>Reconnect</a></center>")
	popup.open()

// In computer_shims for now - we had to define it.
// /obj/machinery/computer/ship/interface_interact(var/mob/user)
// 	ui_interact(user)
// 	return TRUE

/obj/machinery/computer/ship/OnTopic(var/mob/user, var/list/href_list)
	if(..())
		return TOPIC_HANDLED
	if(href_list["sync"])
		sync_linked(user)
		return TOPIC_REFRESH
	if(href_list["close"])
		unlook(user)
		user.unset_machine()
		return TOPIC_HANDLED
	return TOPIC_NOACTION

// Management of mob view displacement. look to shift view to the ship on the overmap; unlook to shift back.

/obj/machinery/computer/ship/proc/look(var/mob/user)
	if(linked)
		apply_visual(user)
		user.reset_view(linked)
	if(isliving(user))
		var/mob/living/L = user
		L.looking_elsewhere = 1
		L.handle_vision()
	user.set_viewsize(world.view + extra_view)
	GLOB.moved_event.register(user, src, /obj/machinery/computer/ship/proc/unlook)
	// TODO GLOB.stat_set_event.register(user, src, /obj/machinery/computer/ship/proc/unlook)
	LAZYDISTINCTADD(viewers, weakref(user))

/obj/machinery/computer/ship/proc/unlook(var/mob/user)
	user.reset_view()
	if(isliving(user))
		var/mob/living/L = user
		L.looking_elsewhere = 0
		L.handle_vision()
	user.set_viewsize() // reset to default
	GLOB.moved_event.unregister(user, src, /obj/machinery/computer/ship/proc/unlook)
	// TODO GLOB.stat_set_event.unregister(user, src, /obj/machinery/computer/ship/proc/unlook)
	LAZYREMOVE(viewers, weakref(user))

/obj/machinery/computer/ship/proc/viewing_overmap(mob/user)
	return (weakref(user) in viewers)

/obj/machinery/computer/ship/CouldNotUseTopic(mob/user)
	. = ..()
	unlook(user)

/obj/machinery/computer/ship/CouldUseTopic(mob/user)
	. = ..()
	if(viewing_overmap(user))
		look(user)

/obj/machinery/computer/ship/check_eye(var/mob/user)
	if (!get_dist(user, src) > 1 || user.blinded || !linked )
		unlook(user)
		return -1
	else
		return 0

/obj/machinery/computer/ship/sensors/Destroy()
	sensors = null
	if(LAZYLEN(viewers))
		for(var/weakref/W in viewers)
			var/M = W.resolve()
			if(M)
				unlook(M)
	. = ..()
