
////////////////////////FUEL PUMP//////////////////////////////////
/obj/structure/fuelpump
	name = "fuel pump"
	desc = "A fuel pump. You need to pay to use it."
	icon = 'icons/obj/modern_structures.dmi'
	icon_state = "oilpump1"
	flammable = FALSE
	not_movable = TRUE
	not_disassemblable = TRUE

	var/price = 0 //price per unit
	var/fueltype = "none"

	var/maxvol = 300 //maximum fuel inside
	var/vol = 0 //current fuel inside
	var/unlockedvol = 0 //fuel that can be withdrown, after purchase
	var/list/storedval = list() //money inside
	var/unlocked = 0

	var/customcolor = 0
	var/owner = "Global"

/obj/structure/fuelpump/premade
	name = "UngOil fuel pump"
	price = 0.3
	owner = "Global"
	icon_state = "oilpump3"
	customcolor = "#3cb44b"
/obj/structure/fuelpump/premade/New()
	..()
	fueltype = pick("gasoline","diesel","biodiesel","ethanol","petroleum")
	vol = rand(140,290)
	do_color()
	name = "UngOil [fueltype] pump"
	price = rand(0.25,0.45)
	updatedesc()

/obj/structure/fuelpump/n
	icon_state = "oilpump3"

/obj/structure/fuelpump/s
	icon_state = "oilpump4"

/obj/structure/fuelpump/small
	icon_state = "oilpump2"

/obj/structure/fuelpump/star
	icon_state = "oilpump1"

/obj/structure/fuelpump/proc/updatedesc()
	desc = "This pump has [vol] units of [fueltype] available. Price: [price*10] silver coins per unit. Copper and Gold accepted too."

/obj/structure/fuelpump/proc/do_color()
	if (customcolor)
		var/image/colorov = image("icon" = icon, "icon_state" = "[icon_state]mask")
		colorov.color = customcolor
		overlays += colorov

/obj/structure/fuelpump/attack_hand(var/mob/living/carbon/human/user)
	if (unlocked)
		if (unlockedvol>0)
			var/ch3 = WWinput("This pump still has [unlockedvol] inside! Are you sure you want to finish?","[name]","No",list("No","Yes"))
			if (ch3 == "Yes")
				unlocked = 0
				unlockedvol = 0
				return
			else
				return
		else
			user << "You lock the pump, finishing the transaction."
			unlocked = 0
			unlockedvol = 0
			return
	else
		user << "Put money on the pump to use it."
		return

/obj/structure/fuelpump/attackby(obj/item/weapon/W as obj, mob/user as mob)

	if (istype(W, /obj/item/stack/money))
		if (unlocked)
			user << "The pump is being used! Finish it first."
			return
		var/obj/item/stack/money/MN = W
		var/valp = MN.amount*MN.value
		if (price > 0 && (valp/price) <= vol)
			var/ch2 = WWinput(user, "You can buy [(valp/price)] units of [fueltype] with this amount. Confirm?", "[name]", "No", list("No","Yes"))
			if (ch2 == "No")
				return
			else if (ch2 == "Yes" && (user.l_hand == W || user.r_hand == W))
				user.drop_from_inventory(W)
				storedval += W
				W.forceMove(locate(0,0,0))
				unlockedvol = (valp/price)
				user << "<span class = 'notice'>You can now withdraw [unlockedvol] units of [fueltype] from this pump.</span>"
				unlocked = 1
				return
			else
				return
		else
			user << "<span class = 'notice'>The fuelpump doesn't have that much fuel inside! Try with a smaller amount. This pump has [vol] units of [fueltype] inside.</span>"

	else if (istype(W, /obj/item/weapon/reagent_containers/glass))
		var/obj/item/weapon/reagent_containers/glass/GC = W
		if (fueltype == "none")
			user << "This fuel pump has no associated fuel type."
			return
		if (unlocked && unlockedvol<=0)
			unlockedvol = 0
			user << "All the paid for fuel has been used. Finish the transaction."
			updatedesc()
			return
		if (unlocked && unlockedvol>0)
			var/avvol = GC.reagents.maximum_volume-GC.reagents.total_volume
			if (unlockedvol <= avvol)
				vol -= unlockedvol
				GC.reagents.add_reagent(fueltype,unlockedvol)
				user << "You fill the [GC] with all the purchased [fueltype]."
				unlockedvol = 0
				updatedesc()
				return
			else if (unlockedvol > avvol)
				unlockedvol -= avvol
				vol -= avvol
				GC.reagents.add_reagent(fueltype,avvol)
				user << "You fill the [GC] completely. There are [unlockedvol] units remanining in the pump."
				updatedesc()
				return

		if (!unlocked)
			if (vol < maxvol)
				if (GC.reagents.has_reagent(fueltype))
					if (GC.reagents.get_reagent_amount(fueltype)<= maxvol-vol)
						vol += (GC.reagents.get_reagent_amount(fueltype))
						GC.reagents.del_reagent(fueltype)
						user << "You empty \the [W] into \the [src]."
						updatedesc()
						return
					else
						var/amttransf = maxvol-vol
						vol += amttransf
						GC.reagents.remove_reagent(fueltype,amttransf)
						user << "You fill \the [src] completly with \the [W]."
						updatedesc()
						return
				else
					user << "\The [W] has no [fueltype] in it."
					return
			else
				user << "\The [src] is already full."
				return
	else
		..()


/obj/structure/fuelpump/verb/Manage()
	set category = null
	set src in range(1, usr)

	var/mob/living/carbon/human/user

	if (ishuman(usr))
		user = usr
	else
		return

	if (find_company_member(user, owner))
		if (unlocked)
			user << "The pump is being used! Finish it first."
			return
		var/input = WWinput(user, "What do you want to do?", "Fuel Pump Management", "Cancel", list("Change Name", "Change Fuel", "Change Price", "Cancel"))
		if (input == "Cancel")
			return

		else if (input == "Change Name")
			var/custn = input(user, "Choose a name for this pump:") as text|null
			if (custn == "" || custn == null)
				return
			else
				name = custn
				updatedesc()
				return

		else if (input == "Change Fuel")
			if (vol > 0)
				user << "<span class = 'notice'>The [src] still has fuel inside! Empty it before changing!</span>"
				return
			else
				var/choice = WWinput(user, "What fuel to set this pump to?", "Fuel Pump Management", "cancel", list("cancel","gasoline","diesel","biodiesel","ethanol","petroleum"))
				if (choice == "cancel")
					return
				else
					fueltype = choice
					updatedesc()
					return

		else if (input == "Change Price")
			var/custp = input(user, "What should the price be, in silver coins? Will be automatically converted. (Default: 3. Min: 0, Max: 500):") as num|null
			if (!isnum(custp))
				return
			if (custp < 0)
				custp = 0
			else if (custp > 500)
				custp = 500
			price = (custp/10) //to standartize
			updatedesc()
		else
			return
	else
		user << "<span class = 'notice'>You are not part of [owner]!</span>"
		return