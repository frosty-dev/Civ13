/* Filing cabinets!
 * Contains:
 *		Filing Cabinets
 *		Security Record Cabinets
 *		Medical Record Cabinets
 */


/*
 * Filing Cabinets
 */
/obj/structure/filingcabinet
	name = "filing cabinet"
	desc = "A large cabinet with drawers."
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "filingcabinet"
	density = TRUE
	anchored = TRUE
	flammable = TRUE
	not_movable = FALSE
	not_disassemblable = TRUE

/obj/structure/filingcabinet/chestdrawer
	name = "chest drawer"
	icon_state = "chestdrawer"


/obj/structure/filingcabinet/filingcabinet	//not changing the path to avoid unecessary map issues, but please don't name stuff like this in the future -Pete
	icon_state = "tallcabinet"


/obj/structure/filingcabinet/initialize()
	for (var/obj/item/I in loc)
		if (istype(I, /obj/item/weapon/paper) || istype(I, /obj/item/weapon/paper_bundle))
			I.loc = src


/obj/structure/filingcabinet/attackby(obj/item/P as obj, mob/user as mob)
	if (istype(P, /obj/item/weapon/paper) || istype(P, /obj/item/weapon/paper_bundle))
		user << "<span class='notice'>You put [P] in [src].</span>"
		user.drop_item()
		P.loc = src
		icon_state = "[initial(icon_state)]-open"
		sleep(5)
		icon_state = initial(icon_state)
		updateUsrDialog()
	else if (istype(P, /obj/item/weapon/wrench))
		playsound(loc, 'sound/items/Ratchet.ogg', 50, TRUE)
		anchored = !anchored
		user << "<span class='notice'>You [anchored ? "wrench" : "unwrench"] \the [src].</span>"
	else
		user << "<span class='notice'>You can't put [P] in [src]!</span>"


/obj/structure/filingcabinet/attack_hand(mob/user as mob)
	if (contents.len <= 0)
		user << "<span class='notice'>\The [src] is empty.</span>"
		return

	user.set_using_object(src)
	var/dat = "<center><table>"
	for (var/obj/item/P in src)
		dat += "<tr><td><a href='?src=\ref[src];retrieve=\ref[P]'>[P.name]</a></td></tr>"
	dat += "</table></center>"
	user << browse("<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"><title>[name]</title></head><body>[dat]</body></html>", "window=filingcabinet;size=350x300")

	return
/*
/obj/structure/filingcabinet/attack_tk(mob/user)
	if (anchored)
		attack_self_tk(user)
	else
		..()

/obj/structure/filingcabinet/attack_self_tk(mob/user)
	if (contents.len)
		if (prob(40 + contents.len * 5))
			var/obj/item/I = pick(contents)
			I.loc = loc
			if (prob(25))
				step_rand(I)
			user << "<span class='notice'>You pull \a [I] out of [src] at random.</span>"
			return
	user << "<span class='notice'>You find nothing in [src].</span>"
*/
/obj/structure/filingcabinet/Topic(href, href_list)
	if (href_list["retrieve"])
		usr << browse("", "window=filingcabinet") // Close the menu

		//var/retrieveindex = text2num(href_list["retrieve"])
		var/obj/item/P = locate(href_list["retrieve"])//contents[retrieveindex]
		if (istype(P) && (P.loc == src) && Adjacent(usr))
			usr.put_in_hands(P)
			updateUsrDialog()
			icon_state = "[initial(icon_state)]-open"
			spawn(0)
				sleep(5)
				icon_state = initial(icon_state)

/*
/*
 * Security Record Cabinets
 */
/obj/structure/filingcabinet/security
	var/virgin = TRUE


/obj/structure/filingcabinet/security/proc/populate()
	if (virgin)
		for (var/datum/data/record/G in data_core.general)
			var/datum/data/record/S
			for (var/datum/data/record/R in data_core.security)
				if ((R.fields["name"] == G.fields["name"] || R.fields["id"] == G.fields["id"]))
					S = R
					break
			var/obj/item/weapon/paper/P = new /obj/item/weapon/paper(src)
			P.info = "<CENTER><b>Security Record</b></CENTER><BR>"
			P.info += "Name: [G.fields["name"]] ID: [G.fields["id"]]<BR>\nSex: [G.fields["sex"]]<BR>\nAge: [G.fields["age"]]<BR>\nFingerprint: [G.fields["fingerprint"]]<BR>\nPhysical Status: [G.fields["p_stat"]]<BR>\nMental Status: [G.fields["m_stat"]]<BR>"
			P.info += "<BR>\n<CENTER><b>Security Data</b></CENTER><BR>\nCriminal Status: [S.fields["criminal"]]<BR>\n<BR>\nMinor Crimes: [S.fields["mi_crim"]]<BR>\nDetails: [S.fields["mi_crim_d"]]<BR>\n<BR>\nMajor Crimes: [S.fields["ma_crim"]]<BR>\nDetails: [S.fields["ma_crim_d"]]<BR>\n<BR>\nImportant Notes:<BR>\n\t[S.fields["notes"]]<BR>\n<BR>\n<CENTER><b>Comments/Log</b></CENTER><BR>"
			var/counter = TRUE
			while (S.fields["com_[counter]"])
				P.info += "[S.fields["com_[counter]"]]<BR>"
				counter++
			P.info += "</TT>"
			P.name = "Security Record ([G.fields["name"]])"
			virgin = FALSE	//tabbing here is correct- it's possible for people to try and use it
						//before the records have been generated, so we do this inside the loop.
	..()

/obj/structure/filingcabinet/security/attack_hand()
	populate()
	..()

/obj/structure/filingcabinet/security/attack_tk()
	populate()
	..()

/*
 * Medical Record Cabinets
 */
/obj/structure/filingcabinet/medical
	var/virgin = TRUE

/obj/structure/filingcabinet/medical/proc/populate()
	if (virgin)
		for (var/datum/data/record/G in data_core.general)
			var/datum/data/record/M
			for (var/datum/data/record/R in data_core.medical)
				if ((R.fields["name"] == G.fields["name"] || R.fields["id"] == G.fields["id"]))
					M = R
					break
			if (M)
				var/obj/item/weapon/paper/P = new /obj/item/weapon/paper(src)
				P.info = "<CENTER><b>Medical Record</b></CENTER><BR>"
				P.info += "Name: [G.fields["name"]] ID: [G.fields["id"]]<BR>\nSex: [G.fields["sex"]]<BR>\nAge: [G.fields["age"]]<BR>\nFingerprint: [G.fields["fingerprint"]]<BR>\nPhysical Status: [G.fields["p_stat"]]<BR>\nMental Status: [G.fields["m_stat"]]<BR>"

				P.info += "<BR>\n<CENTER><b>Medical Data</b></CENTER><BR>\nBlood Type: [M.fields["b_type"]]<BR>\nDNA: [M.fields["b_dna"]]<BR>\n<BR>\nMinor Disabilities: [M.fields["mi_dis"]]<BR>\nDetails: [M.fields["mi_dis_d"]]<BR>\n<BR>\nMajor Disabilities: [M.fields["ma_dis"]]<BR>\nDetails: [M.fields["ma_dis_d"]]<BR>\n<BR>\nAllergies: [M.fields["alg"]]<BR>\nDetails: [M.fields["alg_d"]]<BR>\n<BR>\nCurrent Diseases: [M.fields["cdi"]] (per disease info placed in log/comment section)<BR>\nDetails: [M.fields["cdi_d"]]<BR>\n<BR>\nImportant Notes:<BR>\n\t[M.fields["notes"]]<BR>\n<BR>\n<CENTER><b>Comments/Log</b></CENTER><BR>"
				var/counter = TRUE
				while (M.fields["com_[counter]"])
					P.info += "[M.fields["com_[counter]"]]<BR>"
					counter++
				P.info += "</TT>"
				P.name = "Medical Record ([G.fields["name"]])"
			virgin = FALSE	//tabbing here is correct- it's possible for people to try and use it
						//before the records have been generated, so we do this inside the loop.
	..()

/obj/structure/filingcabinet/medical/attack_hand()
	populate()
	..()

/obj/structure/filingcabinet/medical/attack_tk()
	populate()
	..()
*/