/*
Asset cache quick users guide:

Make a datum at the bottom of this file with your assets for your thing.
The simple subsystem will most like be of use for most cases.
Then call get_asset_datum() with the type of the datum you created and store the return
Then call .send(client) on that stored return value.

You can set verify to TRUE if you want send() to sleep until the client has the assets.
*/


// Amount of time(ds) MAX to send per asset, if this get exceeded we cancel the sleeping.
// This is doubled for the first asset, then added per asset after
#define ASSET_CACHE_SEND_TIMEOUT 7

//When sending mutiple assets, how many before we give the client a quaint little sending resources message
#define ASSET_CACHE_TELL_CLIENT_AMOUNT 8

/client
	var/list/cache = list() // List of all assets sent to this client by the asset cache.
	var/list/completed_asset_jobs = list() // List of all completed jobs, awaiting acknowledgement.
	var/list/sending = list()
	var/last_asset_job = FALSE // Last job done.

//This proc sends the asset to the client, but only if it needs it.
//This proc blocks(sleeps) unless verify is set to false
/proc/send_asset(var/client/client, var/asset_name, var/verify = TRUE)
	if (!istype(client))
		if (ismob(client))
			var/mob/M = client
			if (M.client)
				client = M.client

			else
				return FALSE

		else
			return FALSE

	if (client.cache.Find(asset_name) || client.sending.Find(asset_name))
		return FALSE

	client << browse_rsc(asset_cache.cache[asset_name], asset_name)
	if (!verify || !winexists(client, "asset_cache_browser")) // Can't access the asset cache browser, rip.
		if (client)
			client.cache += asset_name
		return TRUE
	if (!client)
		return FALSE

	client.sending |= asset_name
	var/job = ++client.last_asset_job

	client << browse({"
	<script>
		window.location.href="?asset_cache_confirm_arrival=[job]"
	</script>
	"}, "window=asset_cache_browser")

	var/t = FALSE
	var/timeout_time = (ASSET_CACHE_SEND_TIMEOUT * client.sending.len) + ASSET_CACHE_SEND_TIMEOUT
	while (client && !client.completed_asset_jobs.Find(job) && t < timeout_time) // Reception is handled in Topic()
		sleep(1) // Lock up the caller until this is received.
		t++

	if (client)
		client.sending -= asset_name
		client.cache |= asset_name
		client.completed_asset_jobs -= job

	return TRUE

//This proc blocks(sleeps) unless verify is set to false
/proc/send_asset_list(var/client/client, var/list/asset_list, var/verify = TRUE)
	if (!istype(client))
		if (ismob(client))
			var/mob/M = client
			if (M.client)
				client = M.client
			else
				return FALSE
		else
			return FALSE

	var/list/unreceived = asset_list - (client.cache + client.sending)
	if (!unreceived || !unreceived.len)
		return FALSE
	if (unreceived.len >= ASSET_CACHE_TELL_CLIENT_AMOUNT)
		client << "Sending Resources..."
	for (var/asset in unreceived)
		if (asset in asset_cache.cache)
			client << browse_rsc(asset_cache.cache[asset], asset)

	if (!verify || !winexists(client, "asset_cache_browser")) // Can't access the asset cache browser, rip.
		if (client)
			client.cache += unreceived
		return TRUE
	if (!client)
		return FALSE
	client.sending |= unreceived
	var/job = ++client.last_asset_job

	client << browse({"
	<script>
		window.location.href="?asset_cache_confirm_arrival=[job]"
	</script>
	"}, "window=asset_cache_browser")

	var/t = FALSE
	var/timeout_time = ASSET_CACHE_SEND_TIMEOUT * client.sending.len
	while (client && !client.completed_asset_jobs.Find(job) && t < timeout_time) // Reception is handled in Topic()
		sleep(1) // Lock up the caller until this is received.
		t++

	if (client)
		client.sending -= unreceived
		client.cache |= unreceived
		client.completed_asset_jobs -= job

	return TRUE

//This proc will download the files without clogging up the browse() queue, used for passively sending files on connection start.
//The proc calls procs that sleep for long times.
/proc/getFilesSlow(var/client/client, var/list/files, var/register_asset = TRUE)
	for (var/file in files)
		if (!client)
			break
		if (register_asset)
			register_asset(file,files[file])
		send_asset(client,file)
		sleep(0) //queuing calls like this too quickly can cause issues in some client versions

//This proc "registers" an asset, it adds it to the cache for further use, you cannot touch it from this point on or you'll fuck things up.
//if it's an icon or something be careful, you'll have to copy it before further use.
/proc/register_asset(var/asset_name, var/asset)
	asset_cache.cache[asset_name] = asset

//These datums are used to populate the asset cache, the proc "register()" does this.

//all of our asset datums, used for referring to these later
/var/global/list/asset_datums = list()

//get a assetdatum or make a new one
/proc/get_asset_datum(var/type)
	if (!(type in asset_datums))
		return new type()
	return asset_datums[type]

/datum/asset/New()
	asset_datums[type] = src

/datum/asset/proc/register()
	return

/datum/asset/proc/send(client)
	return

//If you don't need anything complicated.
/datum/asset/simple
	var/assets = list()
	var/verify = FALSE

/datum/asset/simple/register()
	for (var/asset_name in assets)
		register_asset(asset_name, assets[asset_name])
/datum/asset/simple/send(client)
	send_asset_list(client,assets,verify)


//DEFINITIONS FOR ASSET DATUMS START HERE.

/datum/asset/nanoui
	var/list/common = list()

	var/list/common_dirs = list(
		"UI/css/",
		"UI/images/",
		"UI/images/status_icons/",
		"UI/js/"
	)
	var/list/uncommon_dirs = list(
		"UI/templates/"
	)

/datum/asset/nanoui/register()
	// Crawl the directories to find files.
	for (var/path in common_dirs)
		var/list/filenames = flist(path)
		for (var/filename in filenames)
			if (copytext_char(filename, length(filename)) != "/") // Ignore directories.
				if (fexists(path + filename))
					common[filename] = fcopy_rsc(path + filename)
					register_asset(filename, common[filename])
	for (var/path in uncommon_dirs)
		var/list/filenames = flist(path)
		for (var/filename in filenames)
			if (copytext_char(filename, length(filename)) != "/") // Ignore directories.
				if (fexists(path + filename))
					register_asset(filename, fcopy_rsc(path + filename))

/datum/asset/nanoui/send(client, uncommon)
	if (!islist(uncommon))
		uncommon = list(uncommon)

	send_asset_list(client, uncommon, FALSE)
	send_asset_list(client, common, TRUE)

/*
	Asset cache
*/
var/decl/asset_cache/asset_cache = new()

/decl/asset_cache
	var/list/cache

/decl/asset_cache/New()
	..()
	cache = new

/hook/roundstart/proc/send_assets()
	for (var/type in typesof(/datum/asset) - list(/datum/asset, /datum/asset/simple))
		var/datum/asset/A = new type()
		A.register()

	for (var/client/C in clients)
		// Doing this to a client too soon after they've connected can cause issues, also the proc we call sleeps.
		spawn(10)
			getFilesSlow(C, asset_cache.cache, FALSE)

	return TRUE
