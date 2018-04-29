// This file is for actual fighting. Targeting is in a seperate file.

/datum/ai_holder
	var/firing_lanes = FALSE				// If ture, tries to refrain from shooting allies or the wall.
	var/conserve_ammo = FALSE				// If true, the mob will avoid shooting anything that does not have a chance to hit a mob. Requires firing_lanes to be true.

//	var/ranged = FALSE						// If true, attempts to shoot at the enemy instead of charging at them wildly.
	var/shoot_range = 5						// How close the mob needs to be to attempt to shoot at the enemy, if the mob is capable of ranged attacks.
	var/pointblank = FALSE					// If ranged is true, and this is true, people adjacent to the mob will suffer the ranged instead of using a melee attack.

	var/special_attack_prob = 0				// The chance to ATTEMPT a special_attack(). If it fails, it will do a regular attack instead.
	var/special_attack_min_range = 2		// The minimum distance required for an attempt to be made.
	var/special_attack_max_range = 7		// The maximum for an attempt.

	var/can_breakthrough = TRUE				// If false, the AI will not try to break things like windows or other structures in the way.


// This does the actual attacking.
/datum/ai_holder/proc/engage_target()
	ai_log("engage_target() : Entering.", AI_LOG_DEBUG)

	// Can we still see them?
	if(!target || !can_attack(target) || (!(target in list_targets())) )
		ai_log("engage_target() : Lost sight of target.", AI_LOG_TRACE)
		lose_target() // We lost them.

		if(!find_target()) // If we can't get a new one, then wait for a bit and then time out.
			set_stance(STANCE_IDLE)
			lost_target()
			ai_log("engage_target() : No more targets. Exiting.", AI_LOG_DEBUG)
			return
	//		if(lose_target_time + lose_target_timeout < world.time)
	//			ai_log("engage_target() : Unseen enemy timed out.", AI_LOG_TRACE)
	//			set_stance(STANCE_IDLE) // It must've been the wind.
	//			lost_target()
	//			ai_log("engage_target() : Exiting.", AI_LOG_DEBUG)
	//			return

	//		// But maybe we do one last ditch effort.
	//		if(!target_last_seen_turf || intelligence_level < AI_SMART)
	//			ai_log("engage_target() : No last known position or is too dumb to fight unseen enemies.", AI_LOG_TRACE)
	//			set_stance(STANCE_IDLE)
	//		else
	//			ai_log("engage_target() : Fighting unseen enemy.", AI_LOG_TRACE)
	//			engage_unseen_enemy()
		else
			ai_log("engage_target() : Got new target ([target]).", AI_LOG_TRACE)

	var/distance = get_dist(holder, target)
	ai_log("engage_target() : Distance to target ([target]) is [distance].", AI_LOG_TRACE)
	holder.face_atom(target)
	last_conflict_time = world.time

	request_help() // Call our allies.

	// Do a 'special' attack, if one is allowed.
//	if(prob(special_attack_prob) && (distance >= special_attack_min_range) && (distance <= special_attack_max_range))
	if(holder.ICheckSpecialAttack(target))
		ai_log("engage_target() : Attempting a special attack.", AI_LOG_TRACE)
		on_engagement(target)
		if(special_attack(target)) // If this fails, then we try a regular melee/ranged attack.
			ai_log("engage_target() : Successful special attack. Exiting.", AI_LOG_DEBUG)
			return

	// Stab them.
	else if(distance <= 1 && !pointblank)
		ai_log("engage_target() : Attempting a melee attack.", AI_LOG_TRACE)
		on_engagement(target)
		melee_attack(target)

	// Shoot them.
	else if(holder.ICheckRangedAttack(target) && (distance <= max_range(target)) )
		on_engagement(target)
		if(firing_lanes && !test_projectile_safety(target))
			// Nudge them a bit, maybe they can shoot next time.
			step_rand(holder)
			holder.face_atom(target)
			ai_log("engage_target() : Could not safely fire at target. Exiting.", AI_LOG_DEBUG)
			return

		ai_log("engage_target() : Attempting a ranged attack.", AI_LOG_TRACE)
		ranged_attack(target)

	// Run after them.
	else
		ai_log("engage_target() : Target ([target]) too far away. Exiting.", AI_LOG_DEBUG)
		set_stance(STANCE_APPROACH)

// We're not entirely sure how holder will do melee attacks since any /mob/living could be holder, but we don't have to care because Interfaces.
/datum/ai_holder/proc/melee_attack(atom/A)
	. = holder.IAttack(A)
	if(.)
		post_melee_attack(A)

// Ditto.
/datum/ai_holder/proc/ranged_attack(atom/A)
	. = holder.IRangedAttack(A)
	if(.)
		post_ranged_attack(A)

// Most mobs probably won't have this defined but we don't care.
/datum/ai_holder/proc/special_attack(atom/movable/AM)
	. = holder.ISpecialAttack(AM)
	world << "special_attack result is [.]"
	if(.)
		post_special_attack(AM)

// Called when within striking/shooting distance, however cooldown is not considered.
// Override to do things like move in a random step for evasiveness.
// Note that this is called BEFORE the attack.
/datum/ai_holder/proc/on_engagement(atom/A)

// Called after a successful (IE not on cooldown) ranged attack.
// Note that this is not whether the projectile actually hit, just that one was launched.
/datum/ai_holder/proc/post_ranged_attack(atom/A)

// Ditto but for melee.
/datum/ai_holder/proc/post_melee_attack(atom/A)

// And one more for special snowflake attacks.
/datum/ai_holder/proc/post_special_attack(atom/A)

// Used to make sure projectiles will probably hit the target and not the wall or a friend.
/datum/ai_holder/proc/test_projectile_safety(atom/movable/AM)
	var/mob/living/L = check_trajectory(AM, holder) // This isn't always reliable but its better than the previous method.
//	world << "Checked trajectory, would hit [L]."

	if(istype(L)) // Did we hit a mob?
//		world << "Hit [L]."
		if(holder.IIsAlly(L))
//			world << "Would hit ally, canceling."
			return FALSE // We would hit a friend!
//		world << "Won't threaten ally, firing."
		return TRUE // Otherwise we don't care, even if its not the intended target.
	else
		if(!isliving(AM)) // If the original target was an object, then let it happen if it doesn't threaten an ally.
//			world << "Targeting object, ignoring and firing."
			return TRUE
//	world << "Not sure."

	return !conserve_ammo // If we have infinite ammo than shooting the wall isn't so bad, but otherwise lets not.

// Test if we are within range to attempt an attack, melee or ranged.
/datum/ai_holder/proc/within_range(atom/movable/AM)
	var/distance = get_dist(holder, AM)
	if(distance <= 1)
		return TRUE // Can melee.
	else if(holder.ICheckRangedAttack(AM) && distance <= max_range(AM))
		return TRUE // Can shoot.
	return FALSE

// Determines how close the AI will move to its target.
/datum/ai_holder/proc/closest_distance(atom/movable/AM)
	return max(max_range(AM) - 1, 1) // Max range -1 just because we don't want to constantly get kited

// Can be used to conditionally do a ranged or melee attack.
/datum/ai_holder/proc/max_range(atom/movable/AM)
	return holder.ICheckRangedAttack(AM) ? 7 : 1

// Goes to the target, to attack them.
// Called when in STANCE_APPROACH.
/datum/ai_holder/proc/walk_to_target()
	ai_log("walk_to_target() : Entering.", AI_LOG_DEBUG)
	// Make sure we can still chase/attack them.
	if(!target || !can_attack(target))
		ai_log("walk_to_target() : Lost target.", AI_LOG_INFO)
		if(!find_target())
			lost_target()
			ai_log("walk_to_target() : Exiting.", AI_LOG_DEBUG)
			return
		else
			ai_log("walk_to_target() : Found new target ([target]).", AI_LOG_INFO)

	// Find out where we're going.
	var/get_to = closest_distance(target)
	var/distance = get_dist(holder, target)
	ai_log("walk_to_target() : get_to is [get_to].", AI_LOG_TRACE)

	// We're here!
	// Special case: Our holder has a special attack that is ranged, but normally the holder uses melee.
	// If that happens, we'll switch to STANCE_FIGHT so they can use it. If the special attack is limited, they'll likely switch back next tick.
	if(distance <= get_to || holder.ICheckSpecialAttack(target))
		ai_log("walk_to_target() : Within range.", AI_LOG_INFO)
		forget_path()
		set_stance(STANCE_FIGHT)
		ai_log("walk_to_target() : Exiting.", AI_LOG_DEBUG)
		return


	// Otherwise keep walking.
	walk_path(target, get_to)

	ai_log("walk_to_target() : Exiting.", AI_LOG_DEBUG)

// Resists out of things.
// Sometimes there are times you want your mob to be buckled to something, so override this for when that is needed.
/datum/ai_holder/proc/handle_resist()
	holder.resist()

// Used to break through windows and barriers to a target on the other side.
/datum/ai_holder/proc/breakthrough(atom/target_atom)
	if(!can_breakthrough)
		return FALSE
	var/dir_to_target = get_dir(holder, target_atom)
	holder.face_atom(target_atom)

	// First, try to break things directly in front of us.
	var/result = destroy_surroundings(dir_to_target)

	// If that doesn't work, we might be trying to attack something diagonally.
	// If so, we can try again with some adjustments to avoid invalid diagonal directions.
	if(!result)
		result = destroy_surroundings(turn(dir_to_target, 45))

	// One last time, going the other way.
	if(!result)
		result = destroy_surroundings(turn(dir_to_target, -45))

	// Welp.
	return result

/datum/ai_holder/proc/destroy_surroundings(direction)
	if(!direction)
		direction = pick(cardinal) // FLAIL WILDLY

	var/turf/problem_turf = get_step(holder, direction)

	// First, kill windows in the way.
	for(var/obj/structure/window/W in problem_turf)
		if(W.dir == reverse_dir[holder.dir]) // So that windows get smashed in the right order
			ai_log("destroy_surroundings() : Attacking diagonal window.", AI_LOG_INFO)
			return holder.IAttack(W)

		else if(W.is_fulltile())
			ai_log("destroy_surroundings() : Attacking full tile window.", AI_LOG_INFO)
			return holder.IAttack(W)

	var/obj/structure/obstacle = locate(/obj/structure, problem_turf)
	if(istype(obstacle, /obj/structure/window) || istype(obstacle, /obj/structure/closet) || istype(obstacle, /obj/structure/table) || istype(obstacle, /obj/structure/grille))
		ai_log("destroy_surroundings() : Attacking generic structure.", AI_LOG_INFO)
		return holder.IAttack(obstacle)

	for(var/obj/machinery/door/D in problem_turf) // Required since firelocks take up the same turf.
		if(D.density)
			ai_log("destroy_surroundings() : Attacking closed door.", AI_LOG_INFO)
			return holder.IAttack(D)

	return FALSE // Nothing to attack.

