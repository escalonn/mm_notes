import json
import os
import sys
import arrow
from rich import print
import mm_lib


def load_json(path):
    with open(path, encoding='utf8') as f:
        return json.load(f)


def load_config(paths):
    most_recent = max(range(len(paths)),
                      key=lambda i: os.stat(paths[i]).st_mtime)
    return load_json(paths[most_recent])


def print_save_summary(path):
    file_time = arrow.get(os.stat(path).st_mtime)
    print(f'{path} modified {file_time.humanize()}')


def build_item_namer(item_id_to_info):
    def f(item_id):
        name, level = item_id_to_info[str(item_id)]
        return f'{name} lvl{level} [{item_id}]'
    return f


def main():
    # need to load old config too when new config doesn't have info....
    config = load_config(['raw_data_new.json', 'raw_data_new_bs.json'])
    save_path = 'CloudSave.json'
    save = load_json(save_path)
    item_id_to_info = mm_lib.load_item_info()
    item_namer = build_item_namer(item_id_to_info)
    print_save_summary(save_path)
    main_board = save['model']['boardContextsData']['mainBoard']
    main_entries = sum(main_board['boardData']['entries'], [])
    for command in sys.argv[1:]:
        print()
        print(command)
        match command:
            case 'rewards':
                rewards = main_board['rewardInventoryData']['items']
                print([item_namer(r) for r in rewards])
            case 'bubbles':
                for key, name in [
                    ('bubbleData', 'bubble'),
                    ('randomTreasureData', 'random treasure')
                ]:
                    bubbles = main_board[key]
                    refresh_time = arrow.get(bubbles['nextStacksRefresh'])
                    time_display = refresh_time.humanize(
                        granularity=["hour", "minute"])
                    print(f'{bubbles.get("stacks", "_")} {name} stacks, '
                          f'refresh {time_display}')


if __name__ == '__main__':
    main()
