data.json:
	py format-response.py

pull-d-config:
	adb -d backup -noapk com.pixodust.games.free.rpg.medieval.merge.puzzle.empire
	dd if=backup.ab bs=24 skip=1 | openssl zlib -d | tar -xO --wildcards '*activate.json' > raw_data.json && rm backup.ab

pull-d-cloud: check-d-cloud
	adb -d pull sdcard/Android/data/com.pixodust.games.free.rpg.medieval.merge.puzzle.empire/files/GameSaves/Cloud/CloudSave.json
	npx -y prettier --end-of-line auto --write CloudSave.json

cloud-check-needle:
	jq '.model.boardContextsData.mainBoard.boardData.entries[][].item | select(.id == 131005) | .autoSource' CloudSave.json

cloud-check-fountain:
	@echo "(lvl8: 3 charges of 36, total 108)"
	jq '.model.boardContextsData.mainBoard.boardData.entries[][].item | select(.id | tostring | .[:3] == "135") | {id, manualSource}' CloudSave.json

e-clear-data:
	adb -e shell pm clear com.pixodust.games.free.rpg.medieval.merge.puzzle.empire

check-d-cloud:
	adb -d shell 'stat -c %y sdcard/Android/data/*medieval.merge*/files/GameSaves/Cloud/CloudSave.json'

check-e-cloud:
	adb -e shell 'stat -c %y sdcard/Android/data/*medieval.merge*/files/GameSaves/Cloud/CloudSave.json'

items.db:
	rm -f items.db
	sqlite3 items.db < initial.sql

event_items.db:
	rm -f event_items.db
	sed 's/Settings0/Settings1001/' initial.sql | sqlite3 event_items.db

.PHONY: data.json items.db event_items.db
