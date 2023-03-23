enable root
    edit C:\ProgramData\BlueStacks_nxt\bluestacks.conf
        set anything related to "root" to "1"
    run android app root checker to verify
enable proxy
    run mitmweb
    install e.g. android app cx file manager, enable system files in settings
    edit /data/system/users/0/settings_global.xml
        https://old.reddit.com/r/BlueStacks/comments/oe2z02/bluestack_5_proxy/hwfpxte/
            <setting id="100" name="global_proxy_pac_url" value="" package="android" />
            <setting id="97" name="global_http_proxy_host" value="192.168.1.8" package="android" />
            <setting id="98" name="global_http_proxy_port" value="8080" package="android" />
            <setting id="99" name="global_http_proxy_exclusion_list" value="" package="android" />
            <setting id="96" name="http_proxy" value="192.168.1.8:8080" package="com.android.shell" />
        (use values from mitmweb console output)
install mitm cert
    mount root fs read/write
        edit C:\ProgramData\BlueStacks_nxt\Engine\Nougat64\Nougat64.bstk
            set type="Normal" for location="Root.vhd" HardDisk
        edit C:\ProgramData\BlueStacks_nxt\Engine\Nougat64\HypervVm.json
            set "ReadOnly" : false for Root.vhd Scsi Attachment
    boot bluestacks
    install android app root certificate manager
    download .cer file from http://mitm.it
    open .cer file in root certificate manager
disable proxy
    with e.g. cx file explorer edit /data/system/users/0/settings_global.xml
    ~50% mark, set global_http_proxy_host and global_http_proxy_port empty
    ~90% mark, set http_proxy empty
get remote config json over the wire
    launch medieval merge app
    check mitmweb page for the response from firebaseremoteconfig.googleapis.com
    copy as raw_response.json in this folder
    run py format-response.py
    inspect response.json
get remote config from disk
    it's in the /data/data/com.pixodust.games.free.rpg.medieval.merge.puzzle.empire/files directory, frc*firebase_activate.json
    bluestacks
        `cp /c/ProgramData/BlueStacks_nxt/Engine/UserData/SharedFolder/frc* raw_bs_data.json`
    phone
        `adb backup -noapk com.pixodust.games.free.rpg.medieval.merge.puzzle.empire`
        `dd if=backup.ab bs=24 skip=1 | openssl zlib -d | tar -xO --wildcards '*activate.json' > raw_data.json && rm backup.ab`
    copy as raw_data.json in this folder
    run py format-response.py
    inspect response.json
get dlls
    download Il2CppDumper
    get /data/lib directory
    /c/tools/Il2CppDumper-net6-v6.7.25/Il2CppDumper mmerge/lib/lib/arm64/libil2cpp.so mmerge/unzipped/assets/bin/Data/Managed/Metadata/global-metadata.dat mmerge/dumper
    use ilspy but no code b/c Il2CppDumper can't make that i guess...
    it wants System.Private.CoreLib v6.0.0.0 despite being .net framework 4?? maybe some mono thing?
        dotnet new console -f net6.0
        dotnet publish --sc
        ./bin/Debug/net6.0/win-x64/publish/System.Private.CoreLib.dll
getting assets
    https://medieval-merge-game-fanbase.fandom.com/wiki/How_To:_View_Game_Assets
    the .net 6 version of assetstudio is bugged, use .net framework version
    get the apk from the /data/app folder
    open it in assetstudio
    the text assets appear to be in base64 and encrypted
    in case of changed images, `for f in *#*; do mv "$f" "${f%% *}.png"; done`
converting images
    https://medieval-merge-game-fanbase.fandom.com/wiki/How_To:_Format_Images
    cd C:\nonwork\mmerge\data-repo\exported-assets\Sprite
    FOR %i IN (*.png) DO magick "%i" -background #F3E0AD -gravity center -extent 220x220 "converted\%i"
adb shell
    `watch stat -c %y sdcard/Android/data/*medieval.merge*/files/GameSaves/Cloud/CloudSave.json`
    `adb shell 'stat -c %y sdcard/Android/data/*medieval.merge*/files/GameSaves/Cloud/CloudSave.json'`
    `adb pull sdcard/Android/data/com.pixodust.games.free.rpg.medieval.merge.puzzle.empire/files/GameSaves/Cloud/CloudSave.json && npx -y prettier --end-of-line auto --write CloudSave.json`
    `adb shell pm clear com.pixodust.games.free.rpg.medieval.merge.puzzle.empire`
        ^ might require root?
cloud saves
    are triggered on the first action taken after the last cloud save is 5 min old.
    actions include: app startup, moving an item on the board
    actions do not include: selecting different items on the board, switching between map and board
todo
    complete the datamine from the apk
    see if theres anything interesting in the sdcard/files/il2cpp .dats
    missing strings
        https://medieval-merge-game-fanbase.fandom.com/wiki/Tools
        https://medieval-merge-game-fanbase.fandom.com/wiki/Crystal_Dice
        https://medieval-merge-game-fanbase.fandom.com/wiki/Coins
        https://medieval-merge-game-fanbase.fandom.com/wiki/Mine
        https://medieval-merge-game-fanbase.fandom.com/wiki/Magical_Instrument
    missing config data
        https://medieval-merge-game-fanbase.fandom.com/wiki/Fairy_Fountain
        https://medieval-merge-game-fanbase.fandom.com/wiki/Royal_Chest
    missing row in generators page
        green box
    missing pages on wiki
        mimic box
    reformat generators page
        it's silly that tinderbox is in one area but fairy fountain is in another, they work the same
        probably organize as: (1a) manual infinite, (1b) manual finite, (2) automatic.
    maybe redo game ID page to have categories and max level instead of a row for every item?
    make python script to read cloudsave and output reward inventory contents
        .model.boardContextsData.mainBoard.rewardInventoryData.items
        .model.boardContextsData.eventBoard.rewardInventoryData.items
            look up .model.boardContextsData.eventBoard.id to know which data
            to decode gift boxes with from raw_data.json
        (including gift box contents)
        factor id_name_map into separate module to import, i guess

fonts
    franklin gothic
    garamond
    century schoolbook
    gill sans mt
graphviz fonts
    Bell MT
    Book Antiqua
    Californian FB
    Calisto MT
    Century Schoolbook
    Garamond
    Gill Sans MT
    Goudy Old Style
ad algorithms
    after ad finishes
    look at board
    look at shop
    mark time
    spend >=2m total (doesnt have to be sequential) looking at shop and >=3m45s total
    receive ad
    watching a charge ad resets the 2m timer, not the 4m timer.
explore config with jq
    `jq '.configs_key | .[] |= fromjson' raw_data.json`
    (all quest gift box ad rewards:)
        `jq '.configs_key | .[] |= fromjson | [.randomTreasureSettings0.giftRewardSettings[].giftBox] as $gifts | .boardItemSettings0.items[] | select(.id ==$gifts[]) | .manualSource | {destroyAfterTaps, dropId: .droppableItems[0].dropId}' raw_data.json`
    (all items on all boards indiscriminately)
        `jq '.configs_key | .[] |= fromjson | [to_entries[] | select(.key | startswith("boardItemSettings")).value.items] | add' raw_data.json`
explore new board/event
    `sqlite3 -box event_items.db "select * from item_equiv_v where m > 1"`
    `sqlite3 -box event_items.db "select * from recipe_times_v"`
"test suite" on config json
    empty if all items' level = id % 1000 + 1
        `jq '.configs_key | .[] |= fromjson | [to_entries[] | select(.key | startswith("boardItemSettings")).value.items] | add[] | select(.level != .id % 1000 + 1)' raw_data.json`
    empty if all main-board items that have a next-lvl version can merge into that higher version
        `jq '.configs_key | .[] |= fromjson | .boardItemSettings0.items | [.[].id] as $items | .[] | select(.mergeable.nextItemId != .id + 1) | select(.id + 1 == $items[]) | .id' raw_data.json`
next event
    working on quest graph
    make item (category/family) graph
        use images from exported_assets in the graph
            update exported_assets and look for changes
        increase node distance or dpi so i can annotate with image editor
    query for all quest objectives
        `sqlite3 -box event_items.db "select item.descr as item, sum(qo.n) as n from quest_objective as qo join item on qo.item = item.id group by qo.item order by item"`
    all objectives that a particular source item can make
        `sqlite3 -box event_items.db "select item.descr as item, sum(qo.n) as n, recipe.avg_energy * sum(qo.n) as energy from quest_objective as qo join item on qo.item = item.id join recipe on recipe.item = qo.item where recipe.source_item = (select id from item where descr like 'tree%6') group by qo.item"`
    todo: i should be able to write a query that tells me "i need this many alchemist cauldrons in total for all quests", but item_equiv is a little shoddy right now
        see eg: `sqlite3 -box event_items.db "select * from item_equiv_v where a like '%cauldron%'"`
        it doesn't know about equivalency to higher level potions
    total point reward from event quests
        `jq '.configs_key | .[] |= fromjson | [.questSettings1001.quests[].rewards[].mapEventReward.amount] | add' new_raw_data.json`
    looking at charge time / energy usage for specified amount of item
        `sqlite3 -markdown event_items.db "select source_item % 1000 + 1 as gen, round(avg_charge_s * 19 / 3600 / 24,1) as charge_d, cast(round(avg_energy * 19) as int) as energy, round(energy_usage,2) as energy_usage from recipe where item = (select id from item where descr like 'rope%4') and source_item < 900000"`
        user-defined functions sure would be nice for stuff like interval formatting...
    total quest objective of an item category
        `sqlite3 -box event_items.db "with item_obj as (select c.id, c.title, lvl, sum(n) as n from quest_objective as qo join item on item = item.id join category as c on c.id = item.category group by item) select title, max(lvl) as lvl, round(sum(n*pow(2,lvl))/pow(2,max(lvl)),3) as n from item_obj group by id order by id"`
        distinguishing sidequests
            `sqlite3 -box event_items.db "with item_obj as (select c.id, c.title, lvl, sum(n) as n from quest_objective join item on item = item.id join category as c on c.id = item.category join quest on quest.id = quest where quest.side group by item) select title, max(lvl) as lvl, round(sum(n*pow(2,lvl))/pow(2,max(lvl)),3) as n from item_obj group by id order by id"`
    recursive cte to handle forge drops in event. infinite loop if there's a cycle..
        can't just "where not exists" since i guess you can only reference the recursive table once
        `sqlite3 -box event_items.db "with edge (a, energy, b) as (select item, total_drops, successor from source where item in (select id from item where descr like 'sword%' or descr like '%axe%' or descr like '%armour%')), equiv (a, energy, b) as (select a, 0, a from edge union all select x.a, x.energy+y.energy, y.b from equiv as x join edge as y on x.b = y.a) select * from equiv order by a, b"`
        with descrs
            `sqlite3 -box event_items.db "with edge (a, energy, b) as (select item, total_drops, successor from source where item in (select id from item where descr like 'sword%' or descr like '%axe%' or descr like '%armour%')), equiv (a, energy, b) as (select a, 0, a from edge union all select x.a, x.energy+y.energy, y.b from equiv as x join edge as y on x.b = y.a) select i1.descr as a, energy, i2.descr as b from equiv join item as i1 on i1.id = a join item as i2 on i2.id = b order by a, b"`
    todo decide whether rushing forge makes sense
    todo with generator assumptions in place, compute energy requirement for
        each quest, then represent it somehow (log scale on penwidth? but then how to show pt value?)
        border for energy, bgcolor for pt value, [something else] to show skippability
        maybe just leave pt value for a different version of the graph entirely.
    todo determine which quests are charge-time limited. consider the potions & staffs.
    todo add up energy requirements for everything, probably put them on the item category graph
        have python ask sqlite to find out about quest energy usage.
            just go ahead and hardcode more aspects of it.
    [done] have python spit out a csv for what it knows about the quests that sqlite doesnt
        whether quest is sidequest.
        so we can get a version of the query at the end of event-plan.txt
            but for only main quests or for only sidequests, to see what's more easily delayed.
