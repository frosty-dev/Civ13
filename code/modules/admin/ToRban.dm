//By Carnwennan
//fetches an external list and processes it into a list of ip addresses.
//It then stores the processed list into a savefile for later use
#define TOR_UPDATE_INTERVAL 216000	//~6 hours

/proc/get_tor_file_dir()
	return "data/ToR_ban.bdb"

/proc/ToRban_isbanned(var/ip_address)
	var/savefile/F = new(get_tor_file_dir())
	if (F)
		if ( ip_address in F.dir )
			return TRUE
	return FALSE

/proc/ToRban_autoupdate()
	var/savefile/F = new(get_tor_file_dir())
	if (F)
		var/last_update
		F["last_update"] >> last_update
		if ((last_update + TOR_UPDATE_INTERVAL) < world.realtime)	//we haven't updated for a while
			ToRban_update()
	return

/proc/ToRban_update()
	spawn(0)
		log_misc("Downloading updated ToR data...")
		var/http[] = world.Export("https://check.torproject.org/exit-addresses")

		var/list/rawlist = file2list(http["CONTENT"])
		if (rawlist.len)
			fdel(get_tor_file_dir())
			var/savefile/F = new(get_tor_file_dir())
			for ( var/line in rawlist )
				if (!line)	continue
				if ( copytext_char(line,1,12) == "ExitAddress" )
					var/cleaned = copytext_char(line,13,length(line)-19)
					if (!cleaned)	continue
					F[cleaned] << 1
			F["last_update"] << world.realtime
			log_misc("ToR data updated!")
			if (usr)	usr << "ToRban updated."
			return TRUE
		log_misc("ToR data update aborted: no data.")
		return FALSE

/client/proc/ToRban(task in list("update","toggle","show","remove","remove all","find"))
	set name = "ToRban"
	set category = "Server"
	if (!holder)	return
	switch(task)
		if ("update")
			ToRban_update()
		if ("toggle")
			if (config)
				if (config.ToRban)
					config.ToRban = FALSE
					message_admins("<font color='red'>ToR banning disabled.</font>")
				else
					config.ToRban = TRUE
					message_admins("<font colot='green'>ToR banning enabled.</font>")
		if ("show")
			var/savefile/F = new(get_tor_file_dir())
			var/dat
			if ( length(F.dir) )
				for ( var/i=1, i<=length(F.dir), i++ )
					dat += "<tr><td>#[i]</td><td> [F.dir[i]]</td></tr>"
				dat = "<table width='100%'>[dat]</table>"
			else
				dat = "No addresses in list."
			src << browse(dat,"window=ToRban_show")
		if ("remove")
			var/savefile/F = new(get_tor_file_dir())
			var/choice = input(src,"Please select an IP address to remove from the ToR banlist:","Remove ToR ban",null) as null|anything in F.dir
			if (choice)
				F.dir.Remove(choice)
				src << "<b>Address removed</b>"
		if ("remove all")
			src << "<b>[get_tor_file_dir()] was [fdel(get_tor_file_dir())?"":"not "]removed.</b>"
		if ("find")
			var/input = input(src,"Please input an IP address to search for:","Find ToR ban",null) as null|text
			if (input)
				if (ToRban_isbanned(input))
					src << "<font color='green'><b>Address is a known ToR address</b></font>"
				else
					src << "<font color='red'><b>Address is not a known ToR address</b></font>"
	return

#undef TOR_UPDATE_INTERVAL
