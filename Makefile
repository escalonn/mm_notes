new_data.json:
	py format-response.py

connect-e:
	adb connect localhost:60551

check-e-cloud:
	adb -e shell 'stat -c %y sdcard/Android/data/*medieval.merge*/files/GameSaves/Cloud/CloudSave.json'

clear-e-data:
	adb -e shell pm clear com.pixodust.games.free.rpg.medieval.merge.puzzle.empire

pull-d-config:
	adb -d backup -noapk com.pixodust.games.free.rpg.medieval.merge.puzzle.empire
	dd if=backup.ab bs=24 skip=1 | openssl zlib -d | tar -xO --wildcards '*activate.json' > new_raw_data.json && rm backup.ab

check-d-cloud:
	adb -d shell 'stat -c %y sdcard/Android/data/*medieval.merge*/files/GameSaves/Cloud/CloudSave.json'

watch-d-cloud:
	while true; do adb -d shell 'stat -c %y sdcard/Android/data/*medieval.merge*/files/GameSaves/Cloud/CloudSave.json'; sleep 4; done

pull-d-cloud: check-d-cloud
	adb -d pull sdcard/Android/data/com.pixodust.games.free.rpg.medieval.merge.puzzle.empire/files/GameSaves/Cloud/CloudSave.json
	npx -y prettier --end-of-line auto --write CloudSave.json

check-cloud-needle:
	jq '[.model.boardContextsData.mainBoard.boardData.entries[][].item | select(.id == 131005) | .autoSource | {currentItemCharges, lastEvaluationTime} * if has("crescentRechargeTimer") then {minutesSinceLast: (.crescentRechargeTimer / 60), minutesUntilNext: ((1980 - .crescentRechargeTimer) / 60)} else {} end]' CloudSave.json | yq -P

check-cloud-tree:
	yq '.model.boardContextsData.mainBoard.boardData.entries[][].item | select(.id == 103005) | .manualSource' CloudSave.json

check-cloud-gtree:
	yq '.model.boardContextsData.mainBoard.boardData.entries[][].item | select(.id > 107005 and .id < 108000) | .manualSource' CloudSave.json

check-cloud-fountain:
	@echo "(lvl8: 3 charges of 36, total 108)"
	yq '.model.boardContextsData.mainBoard.boardData.entries[][].item | select(.id > 135004 and .id < 136000) | {id, manualSource}' CloudSave.json

items.db:
	rm -f items.db
	sqlite3 items.db < initial.sql

event_items.db:
	rm -f event_items.db
	sed 's/Settings0/Settings1001/;s/raw_data/new_raw_data/' initial.sql | sqlite3 event_items.db

event_graph.png:
	dot -Tpng event_graph.gv > event_graph.png

event_item_category_graph.png:
	dot -Tpng event_item_category_graph.gv > event_item_category_graph.png

# dot -Tpng -Gdpi=150 event_graph.gv > event_graph.png

event_graph.svg:
	dot -Tsvg event_graph.gv > event_graph.svg

.PHONY: new_data.json items.db event_items.db event_graph.png event_graph.svg event_item_category_graph.png
