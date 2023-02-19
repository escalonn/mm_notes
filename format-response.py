from itertools import islice
import json
from urllib.request import urlopen
import html5lib


def fetch_item_id_map():
    item_id_map = {}
    url = 'https://medieval-merge-game-fanbase.fandom.com/wiki/Game_Asset_Item_Ids'
    ns = '{http://www.w3.org/1999/xhtml}'
    with urlopen(url) as f:
        document = html5lib.parse(
            f, transport_encoding=f.info().get_content_charset())
    table = document.find('.//*[@id="mw-content-text"]//{*}table')
    for row in islice(table.iter(ns + 'tr'), 1, None):
        data = [''.join(td.itertext()).strip() for td in row.iter(ns + 'td')]
        item_id, item_name, item_level = data
        item_id_map[item_id] = item_name, item_level
    return item_id_map


def item_id_int_parser(item_id_map):
    def f(num_str):
        if num_str not in item_id_map:
            return int(num_str)
        name, level = item_id_map[num_str]
        return f'{name} lvl{level} [{num_str}]'
    return f


def decode_json(s, int_parser):
    try:
        return json.loads(s, parse_int=int_parser)
    except json.JSONDecodeError:
        return s


in_name = 'raw_data.json'
key_name = 'configs_key'
# in_name = 'raw_response.json'
# key_name = 'entries'

item_id_map = fetch_item_id_map()
int_parser = item_id_int_parser(item_id_map)

with open(in_name, encoding='utf8') as f:
    o = json.load(f, parse_int=int_parser)

o[key_name] = {k: decode_json(v, int_parser) for k, v in o[key_name].items()}

out_name = in_name[4:]
with open(out_name, 'w') as f:
    json.dump(o, f, indent=2)
