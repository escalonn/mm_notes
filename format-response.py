from collections import defaultdict
import csv
from itertools import islice
import json
from urllib.request import urlopen
import html5lib
# import jsonpath_ng
import networkx as nx


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


in_name = 'new_raw_data.json'
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
        (162, ('Poison Bottle', 4)),
        (955, ('Energy', 5)),
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
    data = json.load(f)

# jsonpath_ng.parse('')
# find all the IDs and stuff
# also... find rechargeTimer etc and format as nice hms

data[key_name] = {k: decode_json(v, int_parser)
                  for k, v in data[key_name].items()}

out_name = in_name.replace('raw_', '')
with open(out_name, 'w') as f:
    json.dump(data, f, indent=2)

event_quests = data[key_name]['questSettings1001']['quests']
quest_graph = nx.DiGraph()
for quest in event_quests:
    quest_graph.add_node(quest['uid'])
    if 'requirements' in quest:
        for r in quest['requirements']:
            quest_graph.add_edge(r['requirementValue'], quest['uid'])
min_reward = 50
with open('event_graph.gv', 'w', encoding='utf8') as f:
    print('strict digraph {', file=f)
    print('\tnode [shape=box, fontname="Charter"]', file=f)
    print('\tedge [arrowhead=vee]', file=f)
    for quest in event_quests:
        objective_rows = ''.join(f'<TR><TD>{x["amount"]} × {x["itemId"][:-9]}</TD></TR>'
                                 for x in quest['objectives'])
        reward_rows = ''.join(f'<TR><TD><FONT POINT-SIZE="12">{x["itemReward"]["amount"]} × {x["itemReward"]["itemId"][:-9]}</FONT></TD></TR>'
                              for x in quest['rewards'] if 'itemReward' in x)
        if reward_rows:
            reward_rows = '<HR/>' + reward_rows
        label = f'<TABLE BORDER="0">{objective_rows}{reward_rows}</TABLE>'
        width = sum(r['mapEventReward']['amount']
                    for r in quest['rewards'] if 'mapEventReward' in r) / min_reward if 'rewards' in quest else 0
        print(f'\t{quest["uid"]} [penwidth={width}, label=<{label}>]', file=f)
        if 'requirements' in quest:
            for r in quest['requirements']:
                print(f'\t{r["requirementValue"]} -> {quest["uid"]}', file=f)
    print('}', file=f)

event_item_graph = nx.DiGraph()
for item in data[key_name]['boardItemSettings1001']['items']:
    item_id = int(item['id'][-7:-1]
                  ) if isinstance(item['id'], str) else item['id']
    event_item_graph.add_node(item_id)
    for source in ['manualSource', 'autoSource']:
        if source in item:
            gen_type = 'auto' if source == 'autoSource' else (
                'finite' if 'destroyAfterTaps' in item[source] else 'infinite')
            for drop in item[source]['droppableItems']:
                drop_id = int(
                    drop['dropId'][-7:-1]) if isinstance(drop['dropId'], str) else drop['dropId']
                event_item_graph.add_edge(
                    item_id, drop_id, gen_type=gen_type)
            if drop := item[source].get('droppedItemOnDestroy'):
                drop_id = int(drop[-7:-1]) if isinstance(drop, str) else drop
                event_item_graph.add_edge(
                    item_id, drop_id, gen_type='finite')
    if 'chest' in item and 'forcedDrops' in item['chest']:
        gen_type = 'finite' if 'destroyAfterTaps' in item[source] else 'infinite'
        for drop in item['chest']['forcedDrops']:
            drop_id = int(
                drop['itemId'][-7:-1]) if isinstance(drop['itemId'], str) else drop['itemId']
            event_item_graph.add_edge(item_id, drop_id, gen_type=gen_type)
type_to_style = {
    'infinite': 'solid',
    'finite': 'dashed',
    'auto': 'bold'
}
partition = defaultdict(set)
for node in event_item_graph:
    partition[node // 1000].add(node)
event_item_category_graph = nx.quotient_graph(event_item_graph, partition, relabel=True,
                                              create_using=nx.MultiDiGraph)
with open('event_item_category_graph.gv', 'w', encoding='utf8') as f:
    print('strict digraph {', file=f)
    print('\timagepath="exported-assets\\Sprite"', file=f)
    print('\tnode [shape=box, fontname="Charter", imagescale=true]', file=f)
    print('\tedge [arrowhead=vee, fontname="Charter"]', file=f)
    for node, graph in event_item_category_graph.nodes(data='graph'):
        max_lvl = max(x for x in graph)
        caption = categories.get(max_lvl // 1000, max_lvl // 1000)
        if caption in ['Gift Box', 'Coin Bag', 'Piggybank', 'Ruby', 'Emerald', 'Topaz', 'Sapphire', 'Apple', 'Backpack', 'Energy']:
            continue
        edges = set((node, node, t) for *_, t in graph.edges(data='gen_type')
                    ) | set(event_item_category_graph.edges(node, data='gen_type'))
        width = 3 if any(t != 'finite' for *_, t in edges) else 1
        label = f'<TABLE BORDER="0"><TR><TD FIXEDSIZE="TRUE" HEIGHT="60" WIDTH="60"><IMG SRC="Item-{max_lvl}.png"/></TD></TR><TR><TD>{caption}</TD></TR></TABLE>'
        print(f'\t{node} [penwidth={width}, label=<{label}>]', file=f)
        for c1, c2, gen_type in sorted(edges):
            print(f'\t{c1} -> {c2} [style={type_to_style[gen_type]}]',
                  file=f)
    print('}', file=f)

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
