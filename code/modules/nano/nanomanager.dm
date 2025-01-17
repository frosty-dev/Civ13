//GLOBAL_DATUM_INIT(nanomanager, /datum/nanomanager, new) // NanoManager, the manager for Nano UIs.

// This is the window/UI manager for Nano UI
// There should only ever be one (global) instance of nanomanger
/datum/nanomanager
	// a list of current open /nanoui UIs, grouped by src_object and ui_key
	var/open_uis[0]
	// a list of current open /nanoui UIs, not grouped, for use in processing
	var/list/processing_uis = list()
	// a list of asset filenames which are to be sent to the client on user logon
	var/list/asset_files = list()

 /**
  * Create a new nanomanager instance.
  * This proc generates a list of assets which are to be sent to each client on connect
  *
  * @return /nanomanager new nanomanager object
  */
/datum/nanomanager/New()
	var/list/nano_asset_dirs = list(\
		"UI/css/",\
		"UI/images/",\
		"UI/images/modular_computers/",\
		"UI/images/status_icons/",\
		"UI/js/",\
		"UI/templates/"\
	)

	var/list/filenames = null
	for (var/path in nano_asset_dirs)
		filenames = flist(path)
		for (var/filename in filenames)
			if (copytext_char(filename, length(filename)) != "/") // filenames which end in "/" are actually directories, which we want to ignore
				if (fexists(path + filename))
					asset_files.Add(fcopy_rsc(path + filename)) // add this file to asset_files for sending to clients when they connect

	return

 /**
  * Get an open /nanoui ui for the current user, src_object and ui_key and try to update it with data
  *
  * @param user /mob The mob who opened/owns the ui
  * @param src_object /obj|/mob The obj or mob which the ui belongs to
  * @param ui_key string A string key used for the ui
  * @param ui /datum/nanoui An existing instance of the ui (can be null)
  * @param data list The data to be passed to the ui, if it exists
  * @param force_open boolean The ui is being forced to (re)open, so close ui if it exists (instead of updating)
  *
  * @return /nanoui Returns the found ui, for null if none exists
  */
/datum/nanomanager/proc/try_update_ui(var/mob/user, src_object, ui_key, var/datum/nanoui/ui, data, var/force_open = FALSE)
	if (isnull(ui)) // no ui has been passed, so we'll search for one
	{
		ui = get_open_ui(user, src_object, ui_key)
	}
	if (!isnull(ui))
		// The UI is already open
		if (!force_open)
			ui.push_data(data)
			return ui
		else
			ui.reinitialise(new_initial_data=data)
			return ui

	return null

 /**
  * Get an open /nanoui ui for the current user, src_object and ui_key
  *
  * @param user /mob The mob who opened/owns the ui
  * @param src_object /obj|/mob The obj or mob which the ui belongs to
  * @param ui_key string A string key used for the ui
  *
  * @return /nanoui Returns the found ui, or null if none exists
  */
/datum/nanomanager/proc/get_open_ui(var/mob/user, src_object, ui_key)
	var/src_object_key = "\ref[src_object]"
	if (isnull(open_uis[src_object_key]) || !istype(open_uis[src_object_key], /list))
		//testing("nanomanager/get_open_ui mob [user.name] [src_object:name] [ui_key] - there are no uis open")
		return null
	else if (isnull(open_uis[src_object_key][ui_key]) || !istype(open_uis[src_object_key][ui_key], /list))
		//testing("nanomanager/get_open_ui mob [user.name] [src_object:name] [ui_key] - there are no uis open for this object")
		return null

	for (var/datum/nanoui/ui in open_uis[src_object_key][ui_key])
		if (ui.user == user)
			return ui

	//testing("nanomanager/get_open_ui mob [user.name] [src_object:name] [ui_key] - ui not found")
	return null

 /**
  * Update all /nanoui uis attached to src_object
  *
  * @param src_object /obj|/mob The obj or mob which the uis are attached to
  *
  * @return int The number of uis updated
  */
/datum/nanomanager/proc/update_uis(src_object)
	var/src_object_key = "\ref[src_object]"
	if (isnull(open_uis[src_object_key]) || !istype(open_uis[src_object_key], /list))
		return FALSE

	var/update_count = FALSE
	for (var/ui_key in open_uis[src_object_key])
		for (var/datum/nanoui/ui in open_uis[src_object_key][ui_key])
			if (ui && ui.src_object && ui.user && ui.src_object.nano_host())
				ui.process(1)
				update_count++
	return update_count

 /**
  * Close all /nanoui uis attached to src_object
  *
  * @param src_object /obj|/mob The obj or mob which the uis are attached to
  *
  * @return int The number of uis close
  */
/datum/nanomanager/proc/close_uis(src_object)
	var/src_object_key = "\ref[src_object]"
	if (isnull(open_uis[src_object_key]) || !istype(open_uis[src_object_key], /list))
		return FALSE

	var/close_count = FALSE
	for (var/ui_key in open_uis[src_object_key])
		for (var/datum/nanoui/ui in open_uis[src_object_key][ui_key])
			if (ui && ui.src_object && ui.user && ui.src_object.nano_host())
				ui.close()
				close_count++
	return close_count

 /**
  * Update /nanoui uis belonging to user
  *
  * @param user /mob The mob who owns the uis
  * @param src_object /obj|/mob If src_object is provided, only update uis which are attached to src_object (optional)
  * @param ui_key string If ui_key is provided, only update uis with a matching ui_key (optional)
  *
  * @return int The number of uis updated
  */
/datum/nanomanager/proc/update_user_uis(var/mob/user, src_object = null, ui_key = null)
	if (isnull(user.open_uis) || !istype(user.open_uis, /list) || open_uis.len == FALSE)
		return FALSE // has no open uis

	var/update_count = FALSE
	for (var/datum/nanoui/ui in user.open_uis)
		if ((isnull(src_object) || !isnull(src_object) && ui.src_object == src_object) && (isnull(ui_key) || !isnull(ui_key) && ui.ui_key == ui_key))
			ui.process(1)
			update_count++

	return update_count

 /**
  * Close /nanoui uis belonging to user
  *
  * @param user /mob The mob who owns the uis
  * @param src_object /obj|/mob If src_object is provided, only close uis which are attached to src_object (optional)
  * @param ui_key string If ui_key is provided, only close uis with a matching ui_key (optional)
  *
  * @return int The number of uis closed
  */
/datum/nanomanager/proc/close_user_uis(var/mob/user, src_object = null, ui_key = null)
	if (isnull(user.open_uis) || !istype(user.open_uis, /list) || open_uis.len == FALSE)
		//testing("nanomanager/close_user_uis mob [user.name] has no open uis")
		return FALSE // has no open uis

	var/close_count = FALSE
	for (var/datum/nanoui/ui in user.open_uis)
		if ((isnull(src_object) || !isnull(src_object) && ui.src_object == src_object) && (isnull(ui_key) || !isnull(ui_key) && ui.ui_key == ui_key))
			ui.close()
			close_count++

	//testing("nanomanager/close_user_uis mob [user.name] closed [open_uis.len] of [close_count] uis")

	return close_count

 /**
  * Add a /nanoui ui to the list of open uis
  * This is called by the /nanoui open() proc
  *
  * @param ui /nanoui The ui to add
  *
  * @return nothing
  */
/datum/nanomanager/proc/ui_opened(var/datum/nanoui/ui)
	var/src_object_key = "\ref[ui.src_object]"
	if (isnull(open_uis[src_object_key]) || !istype(open_uis[src_object_key], /list))
		open_uis[src_object_key] = list(ui.ui_key = list())
	else if (isnull(open_uis[src_object_key][ui.ui_key]) || !istype(open_uis[src_object_key][ui.ui_key], /list))
		open_uis[src_object_key][ui.ui_key] = list();

	ui.user.open_uis |= ui
	var/list/uis = open_uis[src_object_key][ui.ui_key]
	uis |= ui
	processing_uis |= ui
	//testing("nanomanager/ui_opened mob [ui.user.name] [ui.src_object:name] [ui.ui_key] - user.open_uis [ui.user.open_uis.len] | uis [uis.len] | processing_uis [processing_uis.len]")

 /**
  * Remove a /nanoui ui from the list of open uis
  * This is called by the /nanoui close() proc
  *
  * @param ui /nanoui The ui to remove
  *
  * @return int FALSE if no ui was removed, TRUE if removed successfully
  */
/datum/nanomanager/proc/ui_closed(var/datum/nanoui/ui)
	var/src_object_key = "\ref[ui.src_object]"
	if (isnull(open_uis[src_object_key]) || !istype(open_uis[src_object_key], /list))
		return FALSE // wasn't open
	else if (isnull(open_uis[src_object_key][ui.ui_key]) || !istype(open_uis[src_object_key][ui.ui_key], /list))
		return FALSE // wasn't open

	processing_uis.Remove(ui)
	if (ui.user)	// Sanity check in case a user has been deleted
		ui.user.open_uis.Remove(ui)
	var/list/uis = open_uis[src_object_key][ui.ui_key]
	uis.Remove(ui)

	//testing("nanomanager/ui_closed mob [ui.user.name] [ui.src_object:name] [ui.ui_key] - user.open_uis [ui.user.open_uis.len] | uis [uis.len] | processing_uis [processing_uis.len]")

	return TRUE

 /**
  * This is called on user logout
  * Closes/clears all uis attached to the user's /mob
  *
  * @param user /mob The user's mob
  *
  * @return nothing
  */

//
/datum/nanomanager/proc/user_logout(var/mob/user)
	//testing("nanomanager/user_logout user [user.name]")
	return close_user_uis(user)

 /**
  * This is called when a player transfers from one mob to another
  * Transfers all open UIs to the new mob
  *
  * @param oldMob /mob The user's old mob
  * @param newMob /mob The user's new mob
  *
  * @return nothing
  */
/datum/nanomanager/proc/user_transferred(var/mob/oldMob, var/mob/newMob)
	//testing("nanomanager/user_transferred from mob [oldMob.name] to mob [newMob.name]")
	if (!oldMob || isnull(oldMob.open_uis) || !istype(oldMob.open_uis, /list) || open_uis.len == FALSE)
		//testing("nanomanager/user_transferred mob [oldMob.name] has no open uis")
		return FALSE // has no open uis

	if (isnull(newMob.open_uis) || !istype(newMob.open_uis, /list))
		newMob.open_uis = list()

	for (var/datum/nanoui/ui in oldMob.open_uis)
		ui.user = newMob
		newMob.open_uis.Add(ui)

	oldMob.open_uis.Cut()

	return TRUE // success