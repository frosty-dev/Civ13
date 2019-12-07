//HTML ENCODE/DECODE + RUS TO CP1251 TODO: OVERRIDE html_encode after fix
/proc/rhtml_encode(var/msg)
	return msg

/proc/rhtml_decode(var/msg)
	return msg


//UPPER/LOWER TEXT + RUS TO CP1251 TODO: OVERRIDE uppertext
/proc/ruppertext(text)
	var/t = ""
	for(var/i = 1, i <= length(text), i++)
		var/a = text2ascii(text, i)
		if (a == 1105 || a == 1025)
			t += ascii2text(1025)
			continue
		if (a < 1072 || a > 1105)
			t += ascii2text(a)
			continue
		t += ascii2text(a - 32)
	return uppertext(t)

/proc/rlowertext(text as text)
	text = lowertext(text)
	var/t = ""
	for (var/i = TRUE, i <= length(text), i++)
		var/a = text2ascii(text, i)
		if (a > 191 && a < 224)
			t += ascii2text(a + 32)
		else if (a == 168)
			t += ascii2text(184)
		else t += ascii2text(a)
	return t


//TEXT SANITIZATION + RUS TO CP1251
/*
sanitize_simple(var/t,var/list/repl_chars = list("\n"="#","\t"="#","�"="&#255;","<"="(",">"=")"))
	for (var/char in repl_chars)
		var/index = findtext(t, char)
		while (index)
			t = copytext(t, TRUE, index) + repl_chars[char] + copytext(t, index+1)
			index = findtext(t, char)
	return t
*/


//RUS CONVERTERS
/proc/russian_to_cp1251(var/msg)//CHATBOX
	return msg

/proc/russian_to_utf8(var/msg)//PDA PAPER POPUPS
	return msg

/proc/utf8_to_cp1251(msg)
	return msg

/proc/cp1251_to_utf8(msg)
	return msg

var/global/list/rkeys = list(
	"а" = "f", "в" = "d", "г" = "u", "д" = "l",
	"е" = "t", "з" = "p", "и" = "b", "й" = "q",
	"к" = "r", "л" = "k", "м" = "v", "н" = "y",
	"о" = "j", "п" = "g", "р" = "h", "с" = "c",
	"н" = "n", "у" = "e", "ф" = "a", "ц" = "w",
	"ч" = "x", "щ" = "i", "щ" = "o", "ы" = "s",
	"ь" = "m", "я" = "z"
)

//RKEY2KEY
/proc/rkey2key(t)
	if (t in rkeys) return rkeys[t]
	return (t)

//TEXT MODS RUS
/proc/capitalize_cp1251(var/t as text)
    var/first = ascii2text(text2ascii(t))
    return ruppertext(first) + copytext_char(t, length(first) + 1)

/proc/intonation(text)
	if (copytext_char(text,-1) == "!")
		text = "<b>[text]</b>"
	return text