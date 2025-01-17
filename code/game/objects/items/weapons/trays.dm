/*
 * Trays - Agouri
 */
/obj/item/weapon/tray
	name = "tray"
	icon = 'icons/obj/food.dmi'
	icon_state = "tray"
	desc = "A metal tray to lay food on."
	force = WEAPON_FORCE_NORMAL
	throwforce = WEAPON_FORCE_NORMAL
	throw_speed = TRUE
	throw_range = 5
	w_class = 3.0
	flags = CONDUCT
	var/list/carrying = list() // List of things on the tray. - Doohl
	var/max_carry = 10

/obj/item/weapon/tray/attack(mob/living/carbon/M as mob, mob/living/carbon/user as mob)

	// Drop all the things. All of them.
	overlays.Cut()
	for (var/obj/item/I in carrying)
		I.loc = M.loc
		carrying.Remove(I)
		if (isturf(I.loc))
			spawn()
				for (var/i = TRUE, i <= rand(1,2), i++)
					if (I)
						step(I, pick(NORTH,SOUTH,EAST,WEST))
						sleep(rand(2,4))


	var/mob/living/carbon/human/H = M      ///////////////////////////////////// /Let's have this ready for later.


	if (!(user.targeted_organ == ("eyes" || "head"))) //////////////hitting anything else other than the eyes
		if (prob(33))
			add_blood(H)
			var/turf/location = H.loc
			if (istype(location, /turf))
				location.add_blood(H)     ///Plik plik, the sound of blood

		M.attack_log += text("\[[time_stamp()]\] <font color='orange'>Has been attacked with [name] by [user.name] ([user.ckey])</font>")
		user.attack_log += text("\[[time_stamp()]\] <font color='red'>Used the [name] to attack [M.name] ([M.ckey])</font>")
		msg_admin_attack("[user.name] ([user.ckey]) used the [name] to attack [M.name] ([M.ckey]) (<A HREF='?_src_=holder;adminplayerobservecoodjump=1;X=[user.x];Y=[user.y];Z=[user.z]'>JMP</a>)")

		if (prob(15))
			M.Weaken(3)
			M.take_organ_damage(3)
		else
			M.take_organ_damage(5)
		if (prob(50))
			playsound(M, 'sound/items/trayhit1.ogg', 50, TRUE)
			for (var/mob/O in viewers(M, null))
				O.show_message(text("<span class='danger'>[] slams [] with the tray!</span>", user, M), TRUE)
			return
		else
			playsound(M, 'sound/items/trayhit2.ogg', 50, TRUE)  //we applied the damage, we played the sound, we showed the appropriate messages. Time to return and stop the proc
			for (var/mob/O in viewers(M, null))
				O.show_message(text("<span class='danger'>[] slams [] with the tray!</span>", user, M), TRUE)
			return


	var/protected = FALSE
	for (var/slot in list(slot_head, slot_wear_mask))
		var/obj/item/protection = M.get_equipped_item(slot)
		if (istype(protection) && (protection.body_parts_covered & FACE))
			protected = TRUE
			break

	if (protected)
		M << "<span class='warning'>You get slammed in the face with the tray, against your mask!</span>"
		if (prob(33))
			add_blood(H)
			if (H.wear_mask)
				H.wear_mask.add_blood(H)
			if (H.head)
				H.head.add_blood(H)
			var/turf/location = H.loc
			if (istype(location, /turf))     //Addin' blood! At least on the floor and item :v
				location.add_blood(H)

		if (prob(50))
			playsound(M, 'sound/items/trayhit1.ogg', 50, TRUE)
			for (var/mob/O in viewers(M, null))
				O.show_message(text("<span class='danger'>[] slams [] with the tray!</span>", user, M), TRUE)
		else
			playsound(M, 'sound/items/trayhit2.ogg', 50, TRUE)  //sound playin'
			for (var/mob/O in viewers(M, null))
				O.show_message(text("<span class='danger'>[] slams [] with the tray!</span>", user, M), TRUE)
		if (prob(10))
			M.Stun(rand(1,3))
			M.take_organ_damage(3)
			return
		else
			M.take_organ_damage(5)
			return

	else //No eye or head protection, tough luck!
		M << "<span class='warning'>You get slammed in the face with the tray!</span>"
		if (prob(33))
			add_blood(M)
			var/turf/location = H.loc
			if (istype(location, /turf))
				location.add_blood(H)

		if (prob(50))
			playsound(M, 'sound/items/trayhit1.ogg', 50, TRUE)
			for (var/mob/O in viewers(M, null))
				O.show_message(text("<span class='danger'>[] slams [] in the face with the tray!</span>", user, M), TRUE)
		else
			playsound(M, 'sound/items/trayhit2.ogg', 50, TRUE)  //sound playin' again
			for (var/mob/O in viewers(M, null))
				O.show_message(text("<span class='danger'>[] slams [] in the face with the tray!</span>", user, M), TRUE)
		if (prob(30))
			M.Stun(rand(2,4))
			M.take_organ_damage(4)
			return
		else
			M.take_organ_damage(8)
			if (prob(30))
				M.Weaken(2)
				return
			return

/obj/item/weapon/tray/var/cooldown = FALSE	//shield bash cooldown. based on world.time

/obj/item/weapon/tray/attackby(obj/item/weapon/W as obj, mob/user as mob)
	if (istype(W, /obj/item/weapon/material/kitchen/rollingpin))
		if (cooldown < world.time - 25)
			user.visible_message("<span class='warning'>[user] bashes [src] with [W]!</span>")
			playsound(user.loc, 'sound/effects/shieldbash.ogg', 50, TRUE)
			cooldown = world.time
	else
		..()

/*
===============~~~~~================================~~~~~====================
=																			=
=  Code for trays carrying things. By Doohl for Doohl erryday Doohl Doohl~  =
=																			=
===============~~~~~================================~~~~~====================
*/
/obj/item/weapon/tray/proc/calc_carry()
	// calculate the weight of the items on the tray
	var/val = FALSE // value to return

	for (var/obj/item/I in carrying)
		if (I.w_class == 1.0)
			val ++
		else if (I.w_class == 2.0)
			val += 3
		else
			val += 5

	return val

/obj/item/weapon/tray/pickup(mob/user)

	if (!isturf(loc))
		return

	for (var/obj/item/I in loc)
		if ( I != src && !I.anchored && !istype(I, /obj/item/clothing/under) && !istype(I, /obj/item/clothing/suit) && !istype(I, /obj/item/projectile) )
			var/add = FALSE
			if (I.w_class == 1.0)
				add = TRUE
			else if (I.w_class == 2.0)
				add = 3
			else
				add = 5
			if (calc_carry() + add >= max_carry)
				break

			I.loc = src
			carrying.Add(I)
			overlays += image("icon" = I.icon, "icon_state" = I.icon_state, "layer" = 30 + I.layer)

/obj/item/weapon/tray/dropped(mob/user)

	var/mob/living/M
	for (M in loc) //to handle hand switching
		return

	var/foundtable = FALSE
	for (var/obj/structure/table/T in loc)
		foundtable = TRUE
		break

	overlays.Cut()

	for (var/obj/item/I in carrying)
		I.loc = loc
		carrying.Remove(I)
		if (!foundtable && isturf(loc))
			// if no table, presume that the person just shittily dropped the tray on the ground and made a mess everywhere!
			spawn()
				for (var/i = TRUE, i <= rand(1,2), i++)
					if (I)
						step(I, pick(NORTH,SOUTH,EAST,WEST))
						sleep(rand(2,4))
