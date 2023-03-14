import csv
from itertools import islice
import json
from urllib.request import urlopen
import html5lib
import jsonpath_ng


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

id_name_patch = {
    str(c * 1000 + i): (n, str(i + 1)) for (c, (n, m)) in [
        (157, ('Ancient Mine', 10)),
        (155, ('Copper Ingot', 4)),
        (153, ('Copper Armour', 8)),
        (158, ('Steel Ingot', 4)),
        (159, ('Steel Armour', 8)),
        (156, ('Gold Ingot', 4)),
        (154, ('Gold Armour', 8)),
        (160, ("Alchemist Cauldron", 1)),
        (161, ('Fire Potion', 4)),
        (162, ('Poison Bottle', 4))
    ] for i in range(m)
}

item_id_map = id_name_patch | fetch_item_id_map()
# item_id_map = {} # disable name replacing

categories = {int(k) // 1000: v[0]
              for k, v in reversed(item_id_map.items())}
with open('categories.csv', 'w', newline='') as f:
    writer = csv.writer(f)
    writer.writerow(['Category', 'Name'])
    for k, v in sorted(categories.items()):
        writer.writerow([k, v])

int_parser = item_id_int_parser(item_id_map)

with open(in_name, encoding='utf8') as f:
    data = json.load(f, parse_int=int_parser)

# jsonpath_ng.parse('')
# find all the IDs and stuff
# also... find rechargeTimer etc and format as nice hms

data[key_name] = {k: decode_json(v, int_parser) for k, v in data[key_name].items()}

out_name = in_name[4:]
with open(out_name, 'w') as f:
    json.dump(data, f, indent=2)

# fields = ['Category', 'Level', 'Source', 'Drops', 'Charge', 'Stack']
# gens = []
# for item in data[key_name]['boardItemSettings1000']['items']:
#     item_id = item['id']
#     if isinstance(item_id, str):
#         item_id = int(item_id.split('[')[-1][:-1])
#     if 'manualSource' in item:
#         gen = {}
#         gen['Category'] = item_id // 1000
#         gen['Level'] = item['level']
#         assert item['level'] - 1 == item_id % 1000
#         gen['Source'] = 'manual'
#         source = item['manualSource']
#         gen['Drops'] = source['dropsPerRecharge']
#         gen['Charge'] = source['rechargeTimer']
#         gen['Stack'] = source['rechargesStack']
#         gens.append(gen)
#     if 'autoSource' in item:
#         gen = {}
#         gen['Category'] = item_id // 1000
#         gen['Level'] = item['level']
#         assert item['level'] - 1 == item_id % 1000
#         gen['Source'] = 'auto'
#         source = item['autoSource']
#         gen['Drops'] = source['dropsPerRecharge']
#         gen['Charge'] = source['rechargeTimer']
#         gen['Stack'] = source['rechargesStack']
#         gens.append(gen)
# with open('event_generators.csv', 'w', newline='') as f:
#     writer = csv.DictWriter(f, fields, extrasaction='ignore')
#     writer.writeheader()
#     for r in gens:
#         writer.writerow(r)
