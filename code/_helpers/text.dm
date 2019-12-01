/*
 * Holds procs designed to help with filtering text
 * Contains groups:
 *			SQL sanitization
 *			Text sanitization
 *			Text searches
 *			Text modification
 *			Misc
 */


/*
 * SQL sanitization
 */

/proc/sanitizeSQL(var/input as text, var/max_length = MAX_MESSAGE_LEN)
	if (!input)
		input = ""

	input = remove_characters(input, list("~", "|", "@", ":", "#", "$", "%", "&",  "'",  "*", "+", "\"", ",", "-", "<", ">", "(", ")", "=", "/", "\\", "!", "^"))

	if (length(input) > max_length)
		input = copytext(input, TRUE, max_length+1)
	return input
/*
 * Text sanitization
 */

//Used for preprocessing entered text
/proc/sanitize(var/input, var/max_length = MAX_MESSAGE_LEN, var/encode = TRUE, var/trim = TRUE, var/extra = TRUE)
	if (!input)
		return

	if (max_length)
		input = copytext(input,1,max_length)

	if (extra)
		input = replace_characters(input, list("\n"=" ","\t"=" "))

	if (encode)
		// The below \ escapes have a space inserted to attempt to enable Travis auto-checking of span class usage. Please do not remove the space.
		//In addition to processing html, html_encode removes byond formatting codes like "\ red", "\ i" and other.
		//It is important to avoid double-encode text, it can "break" quotes and some other characters.
		//Also, keep in mind that escaped characters don't work in the interface (window titles, lower left corner of the main window, etc.)
		input = rhtml_encode(input)
	else
		//If not need encode text, simply remove < and >
		//note: we can also remove here byond formatting codes: 0xFF + next byte
		input = replace_characters(input, list("<"=" ", ">"=" "))

	if (trim)
		//Maybe, we need trim text twice? Here and before copytext?
		input = trim(input)

	return input

//Run sanitize(), but remove <, >, " first to prevent displaying them as &gt; &lt; &34; in some places, after html_encode().
//Best used for sanitize object names, window titles.
//If you have a problem with sanitize() in chat, when quotes and >, < are displayed as html entites -
//this is a problem of double-encode(when & becomes &amp;), use sanitize() with encode=0, but not the sanitizeSafe()!
/proc/sanitizeSafe(var/input, var/max_length = MAX_MESSAGE_LEN, var/encode = TRUE, var/trim = TRUE, var/extra = TRUE)
	return sanitize(replace_characters(input, list(">"=" ","<"=" ", "\""="'")), max_length, encode, trim, extra)

//Filters out undesirable characters from names
/proc/sanitizeName(var/input, var/max_length = MAX_NAME_LEN, var/allow_numbers = FALSE)
	if (!input || length(input) > max_length)
		return //Rejects the input if it is null or if it is longer then the max length allowed

	var/number_of_alphanumeric	= FALSE
	var/last_char_group			= FALSE
	var/output = ""

	for (var/i=1, i<=length(input), i++)
		var/ascii_char = text2ascii(input,i)
		switch(ascii_char)
			// A  .. Z
			if (65 to 90)			//Uppercase Letters
				output += ascii2text(ascii_char)
				number_of_alphanumeric++
				last_char_group = 4

			// a  .. z
			if (97 to 122)			//Lowercase Letters
				if (last_char_group<2)		output += ascii2text(ascii_char-32)	//Force uppercase first character
				else						output += ascii2text(ascii_char)
				number_of_alphanumeric++
				last_char_group = 4

			// FALSE  .. 9
			if (48 to 57)			//Numbers
				if (!last_char_group)		continue	//suppress at start of string
				if (!allow_numbers)			continue
				output += ascii2text(ascii_char)
				number_of_alphanumeric++
				last_char_group = 3

			// '  -  .
			if (39,45,46)			//Common name punctuation
				if (!last_char_group) continue
				output += ascii2text(ascii_char)
				last_char_group = 2

			// ~   |   @  :  #  $  %  &  *  +
			if (126,124,64,58,35,36,37,38,42,43)			//Other symbols that we'll allow (mainly for AI)
				if (!last_char_group)		continue	//suppress at start of string
				if (!allow_numbers)			continue
				output += ascii2text(ascii_char)
				last_char_group = 2

			//Space
			if (32)
				if (last_char_group <= 1)	continue	//suppress double-spaces and spaces at start of string
				output += ascii2text(ascii_char)
				last_char_group = TRUE
			else
				return

	if (number_of_alphanumeric < 2)	return		//protects against tiny names like "A" and also names like "' ' ' ' ' ' ' '"

	if (last_char_group == TRUE)
		output = copytext(output,1,length(output))	//removes the last character (in this case a space)

	for (var/bad_name in list("space","floor","wall","r-wall","monkey","unknown","inactive ai","plating"))	//prevents these common metagamey names
		if (cmptext(output,bad_name))	return	//(not case sensitive)

	return output

//Returns null if there is any bad text in the string
/proc/reject_bad_text(var/text, var/max_length=512)
	if (length(text) > max_length)	return			//message too long
	var/non_whitespace = FALSE
	for (var/i=1, i<=length(text), i++)
		switch(text2ascii(text,i))
			if (62,60,92,47)	return			//rejects the text if it contains these bad characters: <, >, \ or /
			if (127 to 255)	return			//rejects weird letters like �
			if (0 to 31)		return			//more weird stuff
			if (32)			continue		//whitespace
			else			non_whitespace = TRUE
	if (non_whitespace)		return text		//only accepts the text if it has some non-spaces


//Old variant. Haven't dared to replace in some places.
/proc/sanitize_old(var/t,var/list/repl_chars = list("\n"="#","\t"="#"))
	return html_encode(replace_characters(t,repl_chars))

/*
 * Text searches
 */

//Checks the beginning of a string for a specified sub-string
//Returns the position of the substring or FALSE if it was not found
/proc/dd_hasprefix(text, prefix)
	var/start = TRUE
	var/end = length(prefix) + 1
	return findtext(text, prefix, start, end)

//Checks the beginning of a string for a specified sub-string. This proc is case sensitive
//Returns the position of the substring or FALSE if it was not found
/proc/dd_hasprefix_case(text, prefix)
	var/start = TRUE
	var/end = length(prefix) + 1
	return findtextEx(text, prefix, start, end)

//Checks the end of a string for a specified substring.
//Returns the position of the substring or FALSE if it was not found
/proc/dd_hassuffix(text, suffix)
	var/start = length(text) - length(suffix)
	if (start)
		return findtext(text, suffix, start, null)
	return

//Checks the end of a string for a specified substring. This proc is case sensitive
//Returns the position of the substring or FALSE if it was not found
/proc/dd_hassuffix_case(text, suffix)
	var/start = length(text) - length(suffix)
	if (start)
		return findtextEx(text, suffix, start, null)

/*
 * Text modification
 */


/proc/replace_characters(var/t,var/list/repl_chars)
	for (var/char in repl_chars)
		t = replacetext(t, char, repl_chars[char])
	return t

/proc/remove_characters(var/t, var/list/chars)
	var/list/repl_chars = list()
	for (var/val in chars)
		repl_chars[val] = ""
	return replace_characters(t, repl_chars)

//Adds 'u' number of zeros ahead of the text 't'
/proc/add_zero(t, u)
	while (length(t) < u)
		t = "0[t]"
	return t

//Adds 'u' number of spaces ahead of the text 't'
/proc/add_lspace(t, u)
	while (length(t) < u)
		t = " [t]"
	return t

//Adds 'u' number of spaces behind the text 't'
/proc/add_tspace(t, u)
	while (length(t) < u)
		t = "[t] "
	return t

//Returns a string with reserved characters and spaces before the first letter removed
/proc/trim_left(text)
	for (var/i = TRUE to length(text))
		if (text2ascii(text, i) > 32)
			return copytext(text, i)
	return ""

//Returns a string with reserved characters and spaces after the last letter removed
/proc/trim_right(text)
	for (var/i = length(text), i > 0, i--)
		if (text2ascii(text, i) > 32)
			return copytext(text, TRUE, i + 1)
	return ""

//Returns a string with reserved characters and spaces before the first word and after the last word removed.
/proc/trim(text)
	return trim_left(trim_right(text))

//Returns a string with the first element of the string capitalized.
/proc/capitalize(var/t as text)
	return uppertext(copytext(t, TRUE, 2)) + copytext(t, 2)

//This proc strips html properly, remove < > and all text between
//for complete text sanitizing should be used sanitize()
/proc/strip_html_properly(var/input)
	if (!input)
		return
	var/opentag = TRUE //These store the position of < and > respectively.
	var/closetag = TRUE
	while (1)
		opentag = findtext(input, "<")
		closetag = findtext(input, ">")
		if (closetag && opentag)
			if (closetag < opentag)
				input = copytext(input, (closetag + 1))
			else
				input = copytext(input, TRUE, opentag) + copytext(input, (closetag + 1))
		else if (closetag || opentag)
			if (opentag)
				input = copytext(input, TRUE, opentag)
			else
				input = copytext(input, (closetag + 1))
		else
			break

	return input

//This proc fills in all spaces with the "replace" var (* by default) with whatever
//is in the other string at the same spot (assuming it is not a replace char).
//This is used for fingerprints
/proc/stringmerge(var/text,var/compare,replace = "*")
	var/newtext = text
	if (length(text) != length(compare))
		return FALSE
	for (var/i = TRUE, i < length(text), i++)
		var/a = copytext(text,i,i+1)
		var/b = copytext(compare,i,i+1)
		//if it isn't both the same letter, or if they are both the replacement character
		//(no way to know what it was supposed to be)
		if (a != b)
			if (a == replace) //if A is the replacement char
				newtext = copytext(newtext,1,i) + b + copytext(newtext, i+1)
			else if (b == replace) //if B is the replacement char
				newtext = copytext(newtext,1,i) + a + copytext(newtext, i+1)
			else //The lists disagree, Uh-oh!
				return FALSE
	return newtext

//This proc returns the number of chars of the string that is the character
//This is used for detective work to determine fingerprint completion.
/proc/stringpercent(var/text,character = "*")
	if (!text || !character)
		return FALSE
	var/count = FALSE
	for (var/i = TRUE, i <= length(text), i++)
		var/a = copytext(text,i,i+1)
		if (a == character)
			count++
	return count

/proc/reverse_text(var/text = "")
	var/new_text = ""
	for (var/i = length(text); i > 0; i--)
		new_text += copytext(text, i, i+1)
	return new_text
	
// Converts seconds to display "less than a minute", "around 1 minute", "around x minutes"
/proc/convert_to_textminute(displaytime)
	displaytime = round(displaytime/600)
	var/text = displaytime
	if(displaytime > 1)
		text = "around [text] minutes"
	else if(displaytime == 1)
		text = "around 1 minute"
	else
		text = "less than a minute"
	return text
	
//Used in preferences' SetFlavorText and human's set_flavor verb
//Previews a string of len or less length
proc/TextPreview(var/string,var/len=40)
	if (length(string) <= len)
		if (!length(string))
			return "\[...\]"
		else
			return string
	else
		return "[copytext_preserve_html(string, TRUE, 37)]..."

//alternative copytext() for encoded text, doesn't break html entities (&#34; and other)
/proc/copytext_preserve_html(var/text, var/first, var/last)
	return rhtml_encode(copytext(rhtml_decode(text), first, last))

//For generating neat chat tag-images
//The icon var could be local in the proc, but it's a waste of resources
//	to always create it and then throw it out.
/var/icon/text_tag_icons = new('./icons/chattags.dmi')
/proc/create_text_tag(var/tagname, var/tagdesc = tagname, var/client/C = null)
	if (!(C && C.is_preference_enabled(/datum/client_preference/chat_tags)))
		return tagdesc
	return "<IMG src='\ref[text_tag_icons.icon]' class='text_tag' iconstate='[tagname]'" + (tagdesc ? " alt='[tagdesc]'" : "") + ">"

/proc/contains_az09(var/input)
	for (var/i=1, i<=length(input), i++)
		var/ascii_char = text2ascii(input,i)
		switch(ascii_char)
			// A  .. Z
			if (65 to 90)			//Uppercase Letters
				return TRUE
			// a  .. z
			if (97 to 122)			//Lowercase Letters
				return TRUE

			// FALSE  .. 9
			if (48 to 57)			//Numbers
				return TRUE
	return FALSE

/**
 * Strip out the special beyond characters for \proper and \improper
 * from text that will be sent to the browser.
 */
/proc/strip_improper(var/text)
	return replacetext(replacetext(text, "\proper", ""), "\improper", "")

#define gender2text(gender) capitalize(gender)