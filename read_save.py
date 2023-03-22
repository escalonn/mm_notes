import json
import os
import mm_lib


def load_json(path):
    with open(path, encoding='utf8') as f:
        return json.load(f)


def load_config(paths):
    most_recent = max(range(len(paths)),
                      key=lambda i: os.stat(paths[i]).st_mtime)
    return load_json(paths[most_recent])

def main():
    config = load_config(['raw_data_new.json', 'raw_data_new_bs.json'])
    save = load_json('CloudSave.json')
    item_id_to_name = mm_lib.load_item_names()


if __name__ == '__main__':
    main()
