/////////////////XVIII CENTURY STUFF/////////////////////////////
/obj/item/ammo_casing/musketball
	name = "musketball cartridge"
	icon_state = "musketball_gunpowder"
	spent_icon = null
	projectile_type = /obj/item/projectile/bullet/rifle/musketball
	weight = 0.02
	caliber = "musketball"
	value = 3

/obj/item/ammo_casing/musketball_pistol
	name = "pistol cartridge"
	projectile_type = /obj/item/projectile/bullet/rifle/musketball_pistol
	weight = 0.015
	icon_state = "musketball_pistol_gunpowder"
	spent_icon = null
	caliber = "musketball_pistol"
	value = 2

/obj/item/ammo_casing/blunderbuss
	name = "blunderbuss cartridge"
	icon_state = "blunderbuss_gunpowder"
	spent_icon = null
	projectile_type = /obj/item/projectile/bullet/rifle/blunderbuss
	weight = 0.035
	caliber = "blunderbuss"
	value = 3

/obj/item/ammo_casing/arrow
	name = "arrow"
	desc = "Use a bow to fire it."
	icon = 'icons/obj/weapons.dmi'
	icon_state = "arrow"
	spent_icon = null
	projectile_type = /obj/item/projectile/bullet/arrow
	weight = 0.15
	caliber = "arrow"
	slot_flags = SLOT_BELT
	value = 2


///////TO MAKE AMMO WITH GUNPOWDER
/obj/item/weapon/ammopart
	var/resultpath = /obj/item/ammo_casing/musketball

/obj/item/weapon/ammopart/musketball
	name = "musketball projectile"
	desc = "A round musketball, to be used in flintlock muskets."
	icon = 'icons/obj/ammo.dmi'
	icon_state = "musketball"
	force = WEAPON_FORCE_HARMLESS
	throwforce = WEAPON_FORCE_HARMLESS
	resultpath = /obj/item/ammo_casing/musketball
	value = 2
	weight = 0.08

/obj/item/weapon/ammopart/musketball_pistol
	name = "pistol projectile"
	desc = "A small, round musketball, to be used in flintlock pistols."
	icon = 'icons/obj/ammo.dmi'
	icon_state = "musketball_pistol"
	force = WEAPON_FORCE_HARMLESS
	throwforce = WEAPON_FORCE_HARMLESS
	resultpath = /obj/item/ammo_casing/musketball_pistol
	value = 1
	weight = 0.05

/obj/item/weapon/ammopart/blunderbuss
	name = "blunderbuss projectiles"
	desc = "A bunch of small iron projectiles. Can fill blunderbusses."
	icon = 'icons/obj/ammo.dmi'
	icon_state = "blunderbuss"
	force = WEAPON_FORCE_HARMLESS
	throwforce = WEAPON_FORCE_HARMLESS
	resultpath = /obj/item/ammo_casing/blunderbuss
	value = 2
	weight = 0.1

/obj/item/weapon/ammopart/attack_self(mob/user)
	if (!istype(user.l_hand, /obj/item/weapon/reagent_containers) && !istype(user.r_hand, /obj/item/weapon/reagent_containers))
		return
	else
		if (!user.l_hand.reagents.has_reagent("gunpowder",1) && !user.r_hand.reagents.has_reagent("gunpowder",1))
			user << "<span class = 'warning'>You need to a gunpowder container in your hands to make a cartridge.</span>"
			return
		else
			if (user.l_hand.reagents.has_reagent("gunpowder",1))
				user.l_hand.reagents.remove_reagent("gunpowder",1)
				qdel(user.r_hand)
				new resultpath(user.r_hand)
				return
			else if (user.r_hand.reagents.has_reagent("gunpowder",1))
				user.r_hand.reagents.remove_reagent("gunpowder",1)
				qdel(user.l_hand)
				new resultpath(user.l_hand)
				return