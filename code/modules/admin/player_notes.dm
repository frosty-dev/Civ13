/proc/notes_add(var/key, var/note, var/mob/user)
	if (!key || !note)
		return

	//Loading list of notes for this key
	var/savefile/info = new("[get_player_notes_file_dir()][copytext_char(key, TRUE, 2)]/[key]/info.sav")
	var/list/infos
	info >> infos
	if (!infos) infos = list()

	//Overly complex timestamp creation
	var/modifyer = "th"
	switch(time2text(world.timeofday, "DD"))
		if ("01","21","31")
			modifyer = "st"
		if ("02","22",)
			modifyer = "nd"
		if ("03","23")
			modifyer = "rd"
	var/day_string = "[time2text(world.timeofday, "DD")][modifyer]"
	if (copytext_char(day_string,1,2) == "0")
		day_string = copytext_char(day_string,2)
	var/full_date = time2text(world.timeofday, "DDD, Month DD of YYYY")
	var/day_loc = findtext(full_date, time2text(world.timeofday, "DD"))

	var/datum/player_info/P = new
	if (user)
		P.author = user.key
		P.rank = user.client.holder.rank
	else
		P.author = "Adminbot"
		P.rank = "Friendly Robot"
	P.content = note
	P.timestamp = "[copytext_char(full_date,1,day_loc)][day_string][copytext_char(full_date,day_loc+2)]"

	infos += P
	info << infos

	message_admins("<span class = 'notice'>[key_name_admin(user)] has edited [key]'s notes.</span>")
	log_admin("[key_name(user)] has edited [key]'s notes.")

	del(info) // savefile, so NOT qdel

	//Updating list of keys with notes on them
	var/savefile/note_list = "data/player_notes.sav"
	var/list/note_keys
	if (note_list)
		note_list >> note_keys
	if (!note_keys) note_keys = list()
	if (!note_keys.Find(key)) note_keys += key
	note_list << note_keys
	del(note_list) // savefile, so NOT qdel


/proc/notes_del(var/key, var/index)
	var/savefile/info = new("[get_player_notes_file_dir()][copytext_char(key, TRUE, 2)]/[key]/info.sav")
	var/list/infos
	info >> infos
	if (!infos || infos.len < index) return

	var/datum/player_info/item = infos[index]
	infos.Remove(item)
	info << infos

	message_admins("<span class = 'notice'>[key_name_admin(usr)] deleted one of [key]'s notes.</span>")
	log_admin("[key_name(usr)] deleted one of [key]'s notes.")

	qdel(info)

/proc/show_player_info_irc(var/key as text)
	var/dat = "          Info on [key]\n"
	var/savefile/info = new("[get_player_notes_file_dir()][copytext_char(key, TRUE, 2)]/[key]/info.sav")
	var/list/infos
	info >> infos
	if (!infos)
		dat = "No information found on the given key."
	else
		for (var/datum/player_info/I in infos)
			dat += "[I.content]\nby [I.author] ([I.rank]) on [I.timestamp]\n\n"

	return list2params(list(dat))
