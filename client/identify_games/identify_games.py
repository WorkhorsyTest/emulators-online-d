
import sys
import json


if len(sys.argv) < 3:
	print("Usage: python identify_games.py console game")
	print("Example: python identify_games.py playstation2 armored_core_3.iso")
	sys.exit(1)

console = sys.argv[1]
game_bin = sys.argv[2]
info = None

if console == 'playstation2':
	from identify_playstation2_games import get_playstation2_game_info
	info = get_playstation2_game_info(game_bin)

if info:
	# Convert any binary strings to normal strings to be JSON friendly
	for key in info.keys():
		#print(key)
		value = info[key]
		if type(value) is bytes:
			#print('!!!!!!!!!!!!!!!!!!!!!!!!!!!', value, '??????????')
			value = value.decode('cp1252', 'ignore').encode('utf-8').decode('utf-8')
		info[key] = value

	print(json.dumps(info))
