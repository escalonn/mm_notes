connect-e:
	for d in $$(adb devices | grep offline | cut -d " " -f1); do adb disconnect $d; done
	"C:/Program Files/BlueStacks_nxt/HD-Player.exe" --instance Nougat64 &
	while adb connect localhost:$$(sed -nE '/status.adb/ { s/[^"]*"(.*)"/\1/; p }' C:/ProgramData/BlueStacks_nxt/bluestacks.conf) | grep -q cannot; do :; done

launch-e: connect-e
	adb -e shell monkey -p com.pixodust.games.free.rpg.medieval.merge.puzzle.empire 1

pull-e-config:
	@read -p "press enter when app is loaded"
	adb -e shell 'su -c "stat -c %y /data/data/*medieval.merge*/files/frc*"'
	adb -e shell 'su -c "cp /data/data/*medieval.merge*/files/frc* /mnt/windows/BstSharedFolder"'
	cp /c/ProgramData/BlueStacks_nxt/Engine/UserData/SharedFolder/frc* raw_data_new_bs.json
	py format-response.py raw_data_new_bs.json

check-e-cloud:
	adb -e shell 'stat -c %y sdcard/Android/data/*medieval.merge*/files/GameSaves/Cloud/CloudSave.json'

watch-e-cloud:
	while true; do adb -e shell 'stat -c %y sdcard/Android/data/*medieval.merge*/files/GameSaves/Cloud/CloudSave.json'; sleep 4; done

pull-e-cloud: check-e-cloud
	adb -e pull sdcard/Android/data/com.pixodust.games.free.rpg.medieval.merge.puzzle.empire/files/GameSaves/Cloud/CloudSave.json

clear-e-data:
	adb -e shell pm clear com.pixodust.games.free.rpg.medieval.merge.puzzle.empire

pull-d-config:
	adb -d backup -noapk com.pixodust.games.free.rpg.medieval.merge.puzzle.empire
	dd if=backup.ab bs=24 skip=1 | openssl zlib -d | tar -xO --wildcards '*activate.json' > raw_data_new.json && rm backup.ab
	py format-response.py

check-d-cloud:
	adb -d shell 'stat -c %y sdcard/Android/data/*medieval.merge*/files/GameSaves/Cloud/CloudSave.json'

watch-d-cloud:
	while true; do adb -d shell 'stat -c %y sdcard/Android/data/*medieval.merge*/files/GameSaves/Cloud/CloudSave.json'; sleep 4; done

pull-d-cloud: check-d-cloud
	adb -d pull sdcard/Android/data/com.pixodust.games.free.rpg.medieval.merge.puzzle.empire/files/GameSaves/Cloud/CloudSave.json

clear-d-data:
	adb -d shell pm clear com.pixodust.games.free.rpg.medieval.merge.puzzle.empire

rewards:
	yq '.model.boardContextsData.mainBoard.rewardInventoryData.items' CloudSave.json

# do date math to figure out how many there really are NOW, and
# show time until next, time until full, time when next, time when full
needle:
	jq '[.model.boardContextsData.mainBoard.boardData.entries[][].item | select(.id == 131005) | .autoSource | {currentItemCharges, lastEvaluationTime, minutesSinceLast: ((.crescentRechargeTimer // 0) / 60), minutesUntilNext: ((1980 - (.crescentRechargeTimer // 0)) / 60)}]' CloudSave.json | yq -P

tree:
	yq '.model.boardContextsData.mainBoard.boardData.entries[][].item | select(.id == 103005) | .manualSource' CloudSave.json

gtree:
	yq '.model.boardContextsData.mainBoard.boardData.entries[][].item | select(.id > 107005 and .id < 108000) | .manualSource' CloudSave.json

flower:
	jq '[.model.boardContextsData.mainBoard.boardData.entries[][].item | select(.id == 109005) | .autoSource | {currentItemCharges, lastEvaluationTime, minutesSinceLast: ((.crescentRechargeTimer // 0) / 60), minutesUntilNext: ((900 - (.crescentRechargeTimer // 0)) / 60)}]' CloudSave.json | yq -P

fountain:
	@echo "(lvl8: 3 charges of 36, total 108)"
	yq '.model.boardContextsData.mainBoard.boardData.entries[][].item | select(.id > 135004 and .id < 136000) | {id, manualSource}' CloudSave.json

barn:
	yq '.model.boardContextsData.mainBoard.boardData.entries[][].item | select(.id > 129002 and .id < 130000) | .manualSource' CloudSave.json

forge:
	yq '.model.boardContextsData.mainBoard.boardData.entries[][].item | select(.id > 105003 and .id < 106000) | .autoSource' CloudSave.json

format-cloud:
	npx -y prettier --end-of-line auto --write CloudSave.json

data_new.json:
	py format-response.py

items.db:
	rm -f items.db
	sqlite3 items.db < initial.sql

event_items.db:
	rm -f event_items.db
	sed 's/Settings0/Settings1001/;s/raw_data/raw_data_new/;s/720/1700/' initial.sql | sqlite3 event_items.db

event_graph.png:
	dot -Tpng event_graph.gv > event_graph.png

event_item_category_graph.png:
	dot -Tpng event_item_category_graph.gv > event_item_category_graph.png

# dot -Tpng -Gdpi=150 event_graph.gv > event_graph.png

.PHONY: data_new.json items.db event_items.db event_graph.png event_item_category_graph.png
