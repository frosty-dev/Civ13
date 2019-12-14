import sys
import os
import shutil
import time
import psutil
import signal

if len(sys.argv) == 1:
	print("Not enough args provided.")
	sys.exit()
	
currdir = os.path.dirname(os.path.abspath(__file__))
lines = open(os.path.join(currdir,"paths.txt"))
print("Updating git...")

os.chdir("/home/tgstation/repos/civ")
os.system("git pull")
os.system("git reset --hard origin/master")

map = sys.argv[1]
dmms = []
if map == "ISLAND":
	dmms.append("#include \"maps\\1713\\island.dmm\"")

elif map == "NAVAL":
	dmms.append("#include \"maps\\1713\\naval.dmm\"")

elif map == "ROBUSTA":
	dmms.append("#include \"maps\\1713\\robusta.dmm\"")

elif map == "SUPPLY_RAID":
	dmms.append("#include \"maps\\1713\\Supply_Raid.dmm\"")

elif map == "COLONY":
	dmms.append("#include \"maps\\1713\\colony.dmm\"")

elif map == "JUNGLE_COLONY":
	dmms.append("#include \"maps\\1713\\jungle_colony.dmm\"")

elif map == "FOUR_COLONIES":
	dmms.append("#include \"maps\\1713\\four_colonies.dmm\"")

elif map == "RECIFE":
	dmms.append("#include \"maps\\1713\\recife.dmm\"")

elif map == "BATTLEROYALE":
	dmms.append("#include \"maps\\special\\battleroyale.dmm\"")

elif map == "TRIBES":
	dmms.append("#include \"maps\\5000bc\\tribes.dmm\"")

elif map == "CURSED_ISLAND":
	dmms.append("#include \"maps\\1713\\cursed_island.dmm\"")

elif map == "FIELDS":
	dmms.append("#include \"maps\\1713\\fields.dmm\"")

elif map == "HUNT":
	dmms.append("#include \"maps\\1713\\hunt.dmm\"")

elif map == "HERACLEA":
	dmms.append("#include \"maps\\313bc\\heraclea.dmm\"")

elif map == "SIEGE":
	dmms.append("#include \"maps\\313bc\\siege.dmm\"")

elif map == "CAMP":
	dmms.append("#include \"maps\\1013\\camp.dmm\"")

elif map == "KARAK":
	dmms.append("#include \"maps\\1013\\karak.dmm\"")

elif map == "CIVILIZATIONS":
	dmms.append("#include \"maps\\special\\civilizations.dmm\"")

elif map == "NOMADS":
	dmms.append("#include \"maps\\special\\nomads.dmm\"")

elif map == "NOMADS_DESERT":
	dmms.append("#include \"maps\\special\\nomads_desert.dmm\"")
elif map == "NOMADS_ICE_AGE":
	dmms.append("#include \"maps\\special\\nomads_ice_age.dmm\"")
elif map == "NOMADS_JUNGLE":
	dmms.append("#include \"maps\\special\\nomads_jungle.dmm\"")
elif map == "NOMADS_DIVIDE":
	dmms.append("#include \"maps\\special\\nomads_divide.dmm\"")
elif map == "NOMADS_CONTINENTAL":
	dmms.append("#include \"maps\\special\\nomads_continental.dmm\"")
elif map == "NOMADS_PANGEA":
	dmms.append("#include \"maps\\special\\nomads_pangea.dmm\"")
elif map == "NOMADS_WASTELAND":
	dmms.append("#include \"maps\\special\\nomads_wasteland.dmm\"")

elif map == "LITTLE_CREEK":
	dmms.append("#include \"maps\\1873\\little_creek.dmm\"")

elif map == "LITTLE_CREEK_TDM":
	dmms.append("#include \"maps\\1873\\little_creek_tdm.dmm\"")

elif map == "HILL203":
	dmms.append("#include \"maps\\1903\\hill_203.dmm\"")
elif map == "YPRES":
	dmms.append("#include \"maps\\1903\\ypres.dmm\"")
elif map == "COMPOUND":
	dmms.append("#include \"maps\\1969\\compound.dmm\"")
elif map == "HOSTAGES":
	dmms.append("#include \"maps\\1969\\hostages.dmm\"")
elif map == "REICHSTAG":
	dmms.append("#include \"maps\\1943\\reichstag.dmm\"")
elif map == "KHALKHYN_GOL":
	dmms.append("#include \"maps\\1943\\khalkhyn_gol.dmm\"")
elif map == "ARAB_TOWN":
	dmms.append("#include \"maps\\1969\\arab_town.dmm\"")
elif map == "ARAB_TOWN_2":
	dmms.append("#include \"maps\\1969\\arab_town_2.dmm\"")
elif map == "GLADIATORS":
	dmms.append("#include \"maps\\313bc\\gladiators.dmm\"")
elif map == "OMAHA":
	dmms.append("#include \"maps\\1943\\omaha.dmm\"")
elif map == "TSARITSYN":
	dmms.append("#include \"maps\\1903\\tsaritsyn.dmm\"")
elif map == "ROAD_TO_DAK_TO":
	dmms.append("#include \"maps\\1969\\road_to_dak_to.dmm\"")
elif map == "NANJING":
	dmms.append("#include \"maps\\1943\\nanjing.dmm\"")
elif map == "PIONEERS":
	dmms.append("#include \"maps\\1873\\pioneers.dmm\"")
elif map == "KURSK":
	dmms.append("#include \"maps\\1943\\kursk.dmm\"")
elif map == "GULAG13":
	dmms.append("#include \"maps\\1943\\gulag13.dmm\"")
elif map == "NOMADS_NEW_WORLD":
	dmms.append("#include \"maps\\special\\nomads_new_world.dmm\"")
elif map == "STALINGRAD":
	dmms.append("#include \"maps\\WIP\\Stalingrad.dmm\"")
else:
	print("Invalid argument.")
	sys.exit()

DME = "/home/tgstation/repos/civ/civ13.dme"

lines = []
with open(DME, "r") as search:
	for line in search:
		lines.append(line)
	search.close()

wroteDMMs = False
DME = open(DME, "w")
for line in lines:
	if ".dmm" in line:
		if not wroteDMMs:
			for line2 in dmms:
				DME.write(line2)
				DME.write("\n")
			dmms = []
			wroteDMMs = True
	else:
		DME.write(line)

DME.close()

t1 = time.time()

print("Rebuilding binaries...")

os.system("DreamMaker /home/tgstation/repos/civ/civ13.dme")

t2 = time.time() - t1

print("Finished rebuilding in {} seconds".format(t2))

print("Moving into reboot in 30 seconds!")

time.sleep(30)

os.system("cd /home/tgstation/repos/civ && sh deploy.sh /home/tgstation/production/server_third")

print("Done!")
