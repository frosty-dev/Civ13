var/list/global/floor_cache = list()

/turf/floor/trench
	name = "trench"
	icon = 'icons/turf/trench.dmi'
	icon_state = "trench"
	base_icon_state = "trench"
	//var/image/over_OS_darkness = null
	plane = UNDERFLOOR_PLANE
	initial_flooring = /decl/flooring/trench
	var/trench_filling = 0
	var/flooded = FALSE
	var/salty = FALSE
	var/message_cooldown = 0

/turf/floor/trench/New()
	if (!icon_state)
		icon_state = "trench"

	..()
	spawn(4)
		if (src && istype(src, /turf/floor/trench))
			update_icon()
			if (istype(src, /turf/floor/trench/flooded))
				for (var/turf/floor/trench/TF in range(1, src))
					if (!TF.flooded || !istype(TF,/turf/floor/trench/flooded))
						if (salty)
							TF.ChangeTurf(/turf/floor/trench/flooded/salty)
						else
							TF.ChangeTurf(/turf/floor/trench/flooded)
			else
				for (var/turf/floor/TF in range(1, src))
					if (istype(TF, /turf/floor/beach/water) || istype(TF, /turf/floor/trench/flooded))
						flooded = TRUE
						if (istype(TF, /turf/floor/trench/flooded))
							var/turf/floor/trench/flooded/WT = TF
							if (WT.salty)
								ChangeTurf(/turf/floor/trench/flooded/salty)
							else
								ChangeTurf(/turf/floor/trench/flooded)
						else if (istype(TF, /turf/floor/beach/water))
							var/turf/floor/beach/water/WT = TF
							if (WT.salty)
								ChangeTurf(/turf/floor/trench/flooded/salty)
							else
								ChangeTurf(/turf/floor/trench/flooded)
			for (var/direction in list(1,2,4,8,5,6,9,10))
				if (istype(get_step(src,direction),/turf))
					var/turf/FF = get_step(src,direction)
					if (istype(FF, /turf/floor/trench))
						FF.update_icon() //so siding get updated properly
/turf/floor/trench/make_grass()
	overlays.Cut()
	if (islist(decals))
		decals.Cut()
		decals = null

	set_light(0)
	levelupdate()

	ChangeTurf(/turf/floor/trench)

/turf/floor/trench/flooded
	name = "flooded trench"
	flooded = TRUE
	icon_state = "trench_flooded"
	base_icon_state = "trench_flooded"
	initial_flooring = /decl/flooring/trench/flooded
	salty = FALSE
	move_delay = 4

/turf/floor/trench/flooded/proc/check_bridge()
	if(locate(/obj/covers/repairedfloor) in contents)
		move_delay = 0
	if(locate(/obj/structure/vehicleparts/frame) in contents)
		move_delay = 0
	return

/turf/floor/trench/flooded/salty
	name = "flooded saltwater trench"
	salty = TRUE


/turf/floor/trench/attackby(obj/item/C as obj, mob/user as mob)
	if (istype (C, /obj/item/weapon/sandbag) && !istype(C, /obj/item/weapon/sandbag/sandbag))
		var/choice = WWinput(user, "Do you want to start filling up the trench with \the [C]?","Trench","Yes",list("Yes","No"))
		if (choice == "Yes")
			user << "You shove some dirt into the trench."
			if (istype(src, /turf/floor/trench))
				trench_filling++
				qdel(C)
				check_filling()
				return
	..()

/turf/floor/trench/flooded/attackby(obj/item/C as obj, mob/user as mob)
	if (istype (C, /obj/item/weapon/sandbag) && !istype(C, /obj/item/weapon/sandbag/sandbag))
		var/choice = WWinput(user, "Do you want to start filling up the trench with \the [C]?","Trench","Yes",list("Yes","No"))
		if (choice == "Yes")
			user << "You shove some dirt into the trench."
			if (istype(src, /turf/floor/trench))
				trench_filling++
				qdel(C)
				check_filling()
				return
		else
			return
	else if (istype(C, /obj/item/weapon/reagent_containers/glass) || istype(C, /obj/item/weapon/reagent_containers/food/drinks))
		var/obj/item/weapon/reagent_containers/RG = C
		if (istype(RG) && RG.is_open_container())
			if (do_after(user, 15, src, check_for_repeats = FALSE))
				var/sumex = 0
				if (src.salty)
					RG.reagents.add_reagent("sodiumchloride", min(RG.volume - RG.reagents.total_volume, RG.amount_per_transfer_from_this)*0.04)
					sumex += min(RG.volume - RG.reagents.total_volume, RG.amount_per_transfer_from_this)*0.04
				RG.reagents.add_reagent("water", min(RG.volume - RG.reagents.total_volume, RG.amount_per_transfer_from_this)-sumex)
				user.visible_message("<span class='notice'>[user] fills \the [RG] with water.</span>","<span class='notice'>You fill \the [RG] with water.</span>")
				playsound(user, 'sound/effects/watersplash.ogg', 100, TRUE)
				user.setClickCooldown(5)
				return
			else
				return
	else if (istype(C, /obj/item/clothing) && !busy)
		var/obj/item/clothing/CL = C
		usr << "<span class='notice'>You start washing \the [C].</span>"
		var/turf/location = user.loc

		busy = TRUE
		sleep(40)
		busy = FALSE

		if (user.loc != location) return				//User has moved
		if (!C) return 								//Item's been destroyed while washing
		if (user.get_active_hand() != C) return		//Person has switched hands or the item in their hands

		CL.clean_blood()
		CL.radiation = 0
		CL.dirtyness = 0
		CL.fleas = FALSE
		user.visible_message( \
			"<span class='notice'>[user] washes \a [C] using \the [src].</span>", \
			"<span class='notice'>You wash \a [C] using \the [src].</span>")
	else
		..()

/turf/floor/trench/proc/check_filling()
	if (trench_filling < 0)
		trench_filling = 0
	if (trench_filling >= 2)
		ChangeTurf(get_base_turf_by_area(src))
	return

/decl/flooring/trench
	name = "trench"
	desc = "A knee-high trench."
	icon = 'icons/turf/trench.dmi'
	icon_base = "trench"
	flags = TURF_HAS_EDGES | SMOOTH_ONLY_WITH_ITSELF

/decl/flooring/trench/flooded
	name = "flooded trench"
	desc = "A knee-high trench, flooded with water."
	icon = 'icons/turf/trench.dmi'
	icon_base = "trench_flooded"
	flags = TURF_HAS_EDGES | SMOOTH_ONLY_WITH_ITSELF


/turf/floor/dirt
	var/trench_stage = 0
	available_dirt = 2
/turf/floor/trench/Enter(atom/movable/O, atom/oldloc)
	if(isliving(O))
		var/mob/living/L = O
		if (L.mob_size <= MOB_SMALL)
			L.forceMove(src)
			return 1
		if(!istype(oldloc, /turf/floor/trench))
			if(locate(/obj/covers/repairedfloor) in contents)
				L.forceMove(src)
				return 1
			if(locate(/obj/structure/vehicleparts/frame) in contents)
				L.forceMove(src)
				return 1
			if(L.grabbed_by && L.grabbed_by.len)
				var/mob/living/L2 = L.grabbed_by[1].assailant
				visible_message("<span class = 'notice'>[L2] starts pulling [L] out of trench.</span>")
				if(!do_after(L2, 20, oldloc))
					return FALSE
				if(..())
					visible_message("<span class = 'notice'>[L2] pulls [L] out of trench.</span>")
					L.forceMove(src)
					return TRUE
				return FALSE
			if(world.time > message_cooldown + 30)
				visible_message("<span class = 'notice'>[L] starts to enter a trench.</span>")
				message_cooldown = world.time
			if (!do_after(L, 5, src, needhand = FALSE))
				return FALSE
			if(..())
				visible_message("<span class = 'notice'>[L] enters a trench.</span>")
				L.forceMove(src)
				return 1
		if(istype(oldloc, /turf/floor/trench) && locate(/obj/covers/repairedfloor, usr.loc))
			if(!locate(/obj/covers/repairedfloor) in contents)
				if(world.time > message_cooldown + 30)
					visible_message("<span class = 'notice'>[L] starts to climb down from a bridge.</span>")
					message_cooldown = world.time
				if (!do_after(L, 5, src, needhand = FALSE))
					return FALSE
				if(..())
					visible_message("<span class = 'notice'>[L] climbs down from a bridge.</span>")
					L.forceMove(src)
					return TRUE
		if(istype(oldloc, /turf/floor/trench) && locate(/obj/structure/vehicleparts/frame, usr.loc))
			if(!locate(/obj/structure/vehicleparts/frame) in contents)
				if(world.time > message_cooldown + 30)
					visible_message("<span class = 'notice'>[L] starts to climb down.</span>")
					message_cooldown = world.time
				if (!do_after(L, 5, src, needhand = FALSE))
					return FALSE
				if(..())
					visible_message("<span class = 'notice'>[L] climbs down.</span>")
					L.forceMove(src)
					return TRUE

	return ..()

/turf/floor/trench/Exit(atom/movable/O, atom/newloc)
	if(isliving(O))
		var/mob/living/L = O
		if (L.mob_size <= MOB_SMALL)
			var/turf/T = newloc
			if(T.Enter(O, src))
				L.forceMove(newloc)
			return TRUE
		if(!istype(newloc, /turf/floor/trench))
			if(locate(/obj/covers/repairedfloor) in contents)
				var/turf/T = newloc
				if(T.Enter(O, src))
					L.forceMove(newloc)
				return TRUE
			if(locate(/obj/structure/vehicleparts/frame) in contents)
				var/turf/T = newloc
				if(T.Enter(O, src))
					L.forceMove(newloc)
				return TRUE
			if(L.grabbed_by && L.grabbed_by.len)
				var/mob/living/L2 = L.grabbed_by[1].assailant
				visible_message("<span class = 'notice'>[L2] starts pulling [L] out of trench.</span>")
				if(!do_after(L2, 35, src))
					return FALSE
				if(..())
					visible_message("<span class = 'notice'>[L2] pulls [L] out of trench.</span>")
					L.forceMove(newloc)
					return TRUE
				return FALSE
			var/atom/newlocation = get_step(L,L.dir)
			if (newlocation.density)
				return FALSE
			for (var/atom/A in newlocation)
				if (A.density)
					return FALSE
			if(world.time > message_cooldown + 30)
				visible_message("<span class = 'notice'>[L] starts to exit a trench.</span>")
				message_cooldown = world.time
			if (!do_after(L, 20, src, needhand = FALSE))
				return FALSE
			if(..())
				visible_message("<span class = 'notice'>[L] exits a trench.</span>")
				var/turf/T = newloc
				if(T.Enter(O, src))
					L.forceMove(newloc)
				return TRUE
		if(istype(newloc, /turf/floor/trench) && locate(/obj/covers/repairedfloor, newloc) && !locate(/obj/covers/repairedfloor, usr.loc))
			if(world.time > message_cooldown + 30)
				visible_message("<span class = 'notice'>[L] starts to climb on a bridge.</span>")
				message_cooldown = world.time
			if (!do_after(L, 20, src, needhand = FALSE))
				return FALSE
			if(..())
				visible_message("<span class = 'notice'>[L] climbs on a bridge.</span>")
				var/turf/T = newloc
				if(T.Enter(O, src))
					L.forceMove(newloc)
				return TRUE
		if(istype(newloc, /turf/floor/trench) && locate(/obj/structure/vehicleparts/frame, newloc) && !locate(/obj/structure/vehicleparts/frame, usr.loc))
			if(world.time > message_cooldown + 30)
				visible_message("<span class = 'notice'>[L] starts to climb on a frame.</span>")
				message_cooldown = world.time
			if (!do_after(L, 20, src, needhand = FALSE))
				return FALSE
			if(..())
				visible_message("<span class = 'notice'>[L] climbs on a frame.</span>")
				var/turf/T = newloc
				if(T.Enter(O, src))
					L.forceMove(newloc)
				return TRUE
	return ..()

/turf/floor/dirt/attackby(obj/item/C as obj, mob/user as mob)
	if (istype(C, /obj/item/weapon/shovel/trench))
		var/obj/item/weapon/shovel/trench/S = C
		visible_message("<span class = 'notice'>[user] starts to dig a trench.</span>")
		if (!do_after(user, (10 - S.dig_speed)*10, src))
			return
		trench_stage++
		switch(trench_stage)
			if(1)
				//icon_state = ""
				visible_message("<span class = 'notice'>[user] digs.</span>")
				user << ("<span class = 'notice'>You need to dig this tile one more time to make a trench.</span>")
				return
			if(2)
				visible_message("<span class = 'notice'>[user] makes a trench.</span>")
				ChangeTurf(/turf/floor/trench)
		return
	..()

/turf/floor/beach/sand
	var/trench_stage = 0
/turf/floor/beach/sand/attackby(obj/item/C as obj, mob/user as mob)
	if (istype(C, /obj/item/weapon/shovel/trench))
		var/obj/item/weapon/shovel/trench/S = C
		visible_message("<span class = 'notice'>[user] starts to dig a trench.</span>")
		if (!do_after(user, (10 - S.dig_speed)*10, src))
			return
		if (istype(src, /turf/floor/beach/sand))
			trench_stage++
			switch(trench_stage)
				if(1)
					//icon_state = ""
					visible_message("<span class = 'notice'>[user] digs.</span>")
					user << ("<span class = 'notice'>You need to dig this tile one more time to make a trench.</span>")
					return
				if(2)
					visible_message("<span class = 'notice'>[user] makes a trench.</span>")
					ChangeTurf(/turf/floor/trench)
		return
	..()

/turf/floor/dirt/attackby(obj/item/C as obj, mob/user as mob)
	if (istype(C, /obj/item/weapon/shovel/trench))
		var/obj/item/weapon/shovel/trench/S = C
		visible_message("<span class = 'notice'>[user] starts to dig a trench.</span>")
		if (!do_after(user, (10 - S.dig_speed)*10, src))
			return
		if (istype(src,/turf/floor/dirt))
			trench_stage++
			switch(trench_stage)
				if(1)
					//icon_state = ""
					visible_message("<span class = 'notice'>[user] digs.</span>")
					user << ("<span class = 'notice'>You need to dig this tile one more time to make a trench.</span>")
					return
				if(2)
					visible_message("<span class = 'notice'>[user] makes a trench.</span>")
					ChangeTurf(/turf/floor/trench)
		return
	..()

/turf/floor/grass/attackby(obj/item/C as obj, mob/user as mob)
	if (istype(C, /obj/item/weapon/shovel/trench))
		var/obj/item/weapon/shovel/trench/S = C
		visible_message("<span class = 'notice'>[user] starts to remove grass layer.</span>")
		if (!do_after(user, (10 - S.dig_speed)*10, src))
			return
		visible_message("<span class = 'notice'>[user] removes grass layer.</span>")
		var/area/A = get_area(src)
		if (A.climate == "jungle" || A.climate == "savanna")
			ChangeTurf(/turf/floor/dirt/jungledirt)
		else
			ChangeTurf(/turf/floor/dirt)
		return
	..()

/turf/floor/winter/attackby(obj/item/C as obj, mob/user as mob)
	if (istype(C, /obj/item/weapon/shovel/trench))
		var/obj/item/weapon/shovel/trench/S = C
		visible_message("<span class = 'notice'>[user] starts to remove snow layer.</span>")
		if (!do_after(user, (10 - S.dig_speed)*10, src))
			return
		visible_message("<span class = 'notice'>[user] removes snow layer.</span>")
		ChangeTurf(/turf/floor/dirt)
		return
	..()

/turf/floor/trench/flooded/attack_hand(var/mob/living/carbon/human/H)
	if (!ishuman(H))
		return
	if (H.a_intent == I_GRAB)
		if (salty)
			H << "<span class='warning'>Itґs probably not a good idea to drink saltwater.</span>"
			return
		H << "You start drinking some water from the flooded trench..."
		if (do_after(H,50,src))
			var/watertype = "water"
			if (radiation>0)
				watertype = "irradiated_water"
			if (watertype == "irradiated_water")
				H.rad_act(5)
			else
				if (prob(25) && !H.orc && !H.crab)
					if (H.disease == 0)
						H.disease_progression = 0
						H.disease_type ="cholera"
						H.disease = 1
			if (H.water < 0)
				H.water += rand(40,50)
			H.water += 75
			H.bladder += 75
			H << "You drink some water."
			playsound(H.loc, 'sound/items/drink.ogg', rand(10, 50), TRUE)
			return
		else
			return
	else
		..()