data.json:
	py format-response.py

check-d-cloud:
	adb -d shell 'stat -c %y sdcard/Android/data/*medieval.merge*/files/GameSaves/Cloud/CloudSave.json'

check-e-cloud:
	adb -e shell 'stat -c %y sdcard/Android/data/*medieval.merge*/files/GameSaves/Cloud/CloudSave.json'

watch-d-cloud:
	while true; do adb -d shell 'stat -c %y sdcard/Android/data/*medieval.merge*/files/GameSaves/Cloud/CloudSave.json'; sleep 2; done

pull-d-config:
	adb -d backup -noapk com.pixodust.games.free.rpg.medieval.merge.puzzle.empire
	dd if=backup.ab bs=24 skip=1 | openssl zlib -d | tar -xO --wildcards '*activate.json' > raw_data.json && rm backup.ab

pull-d-cloud: check-d-cloud
	adb -d pull sdcard/Android/data/com.pixodust.games.free.rpg.medieval.merge.puzzle.empire/files/GameSaves/Cloud/CloudSave.json
	npx -y prettier --end-of-line auto --write CloudSave.json

cloud-check-needle:
	jq '[.model.boardContextsData.mainBoard.boardData.entries[][].item | select(.id == 131005) | .autoSource | {currentItemCharges, lastEvaluationTime, minutesSinceLast: (.crescentRechargeTimer / 60), minutesUntilNext: ((1980 - .crescentRechargeTimer) / 60)}]' CloudSave.json | yq -P

cloud-check-tree:
	yq '.model.boardContextsData.mainBoard.boardData.entries[][].item | select(.id == 103005) | .manualSource' CloudSave.json

cloud-check-gtree:
	yq '.model.boardContextsData.mainBoard.boardData.entries[][].item | select(.id > 107005 and .id < 108000) | .manualSource' CloudSave.json

# 6174
cloud-check-fountain:
	@echo "(lvl8: 3 charges of 36, total 108)"
	yq '.model.boardContextsData.mainBoard.boardData.entries[][].item | select(.id > 135004 and .id < 136000) | {id, manualSource}' CloudSave.json

e-clear-data:
	adb -e shell pm clear com.pixodust.games.free.rpg.medieval.merge.puzzle.empire

items.db:
	rm -f items.db
	sqlite3 items.db < initial.sql

event_items.db:
	rm -f event_items.db
	sed 's/Settings0/Settings1001/' initial.sql | sqlite3 event_items.db

.PHONY: data.json items.db event_items.db
