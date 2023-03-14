data.json:
	py format-response.py

pull-d-cloud: check-d-cloud
	adb -d pull sdcard/Android/data/com.pixodust.games.free.rpg.medieval.merge.puzzle.empire/files/GameSaves/Cloud/CloudSave.json
	npx -y prettier --end-of-line auto --write CloudSave.json

cloud-check-needle:
	jq '.model.boardContextsData.mainBoard.boardData.entries[][].item | select(.id == 131005) | .autoSource' CloudSave.json

e-clear-data:
	adb -e shell pm clear com.pixodust.games.free.rpg.medieval.merge.puzzle.empire

check-d-cloud:
	adb -d shell 'stat -c %y sdcard/Android/data/*medieval.merge*/files/GameSaves/Cloud/CloudSave.json'

check-e-cloud:
	adb -e shell 'stat -c %y sdcard/Android/data/*medieval.merge*/files/GameSaves/Cloud/CloudSave.json'

items.db:
	rm items.db
	sqlite3 items.db < initial.sql

.PHONY: items.db
