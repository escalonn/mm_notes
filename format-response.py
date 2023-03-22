from collections import defaultdict
import csv
import json
import sys
# import jsonpath_ng
import networkx as nx
import mm_lib


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


in_name = sys.argv[1] if len(sys.argv) > 1 else 'raw_data_new.json'

item_id_map = mm_lib.load_item_names()
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

data['configs_key'] = {k: decode_json(v, int_parser)
                  for k, v in data['configs_key'].items()}

out_name = in_name.replace('raw_', '')
assert in_name != out_name
with open(out_name, 'w') as f:
    json.dump(data, f, indent=2)

event_quests = data['configs_key']['questSettings1001']['quests']
quest_graph = nx.DiGraph()
for quest in event_quests:
    uid = quest['uid']
    quest_graph.add_node(uid)
    for r in quest.get('requirements', []):
        quest_graph.add_edge(r['requirementValue'], uid)
quest_graph.add_edge(2202, 2208) # necessary forge reward
# remove redundant requirements (in quadratic time cause it's easier)
for u, v in list(quest_graph.edges()):
    quest_graph.remove_edge(u, v)
    if not nx.has_path(quest_graph, u, v):
        quest_graph.add_edge(u, v)
last_quest = max(quest_graph)
main_path = nx.ancestors(quest_graph, last_quest) | {last_quest}
min_reward = 50
with open('event_graph.gv', 'w', encoding='utf8') as f:
    print('digraph {', file=f)
    print('\tnode [shape=box, fontname="Charter", fontsize=14, fillcolor=gray90]',
          file=f)
    print('\tedge [arrowhead=vee]', file=f)
    for quest in event_quests:
        uid = quest["uid"]
        objective_rows = ''.join(f'<TR><TD>{x["amount"]} × {x["itemId"][:-9]}</TD></TR>'
                                 for x in quest['objectives'])
        reward_rows = ''.join(f'<TR><TD><FONT POINT-SIZE="12">{x["itemReward"]["amount"]} × {x["itemReward"]["itemId"][:-9]}</FONT></TD></TR>'
                              for x in quest['rewards'] if 'itemReward' in x)
        if reward_rows:
            reward_rows = '<HR/>' + reward_rows
        label = f'<TABLE BORDER="0">{objective_rows}{reward_rows}</TABLE>'
        xlabel = '<FONT POINT-SIZE="7"><B>\\N</B></FONT>'
        width = sum(r['mapEventReward']['amount']
                    for r in quest['rewards'] if 'mapEventReward' in r) / min_reward if 'rewards' in quest else 0
        style = '\"\"' if uid in main_path else 'filled'
        print(f'\t{uid} [penwidth={width}, label=<{label}>, xlabel=<{xlabel}>, style={style}]', file=f)
        for r in quest_graph.adj[uid]:
            print(f'\t{uid} -> {r}', file=f)
    print('}', file=f)

def extract_id(label):
    return label if isinstance(label, int) else int(label[-7:-1])

event_item_graph = nx.DiGraph()
for item in data['configs_key']['boardItemSettings1001']['items']:
    item_id = int(item['id'][-7:-1]
                  ) if isinstance(item['id'], str) else item['id']
    event_item_graph.add_node(item_id)
    for source in ['manualSource', 'autoSource']:
        if source in item:
            gen_type = 'auto' if source == 'autoSource' else (
                'finite' if 'destroyAfterTaps' in item[source] else 'infinite')
            for drop in item[source]['droppableItems']:
                event_item_graph.add_edge(
                    item_id, extract_id(drop['dropId']), gen_type=gen_type)
            if drop := item[source].get('droppedItemOnDestroy'):
                event_item_graph.add_edge(
                    item_id, extract_id(drop), gen_type='destroy')
    if 'mergeable' in item:
        next_id = extract_id(item['mergeable']['nextItemId'])
        if next_id != item_id + 1:
            event_item_graph.add_edge(item_id, next_id, gen_type='merge')
    if 'chest' in item and 'forcedDrops' in item['chest']:
        gen_type = 'finite' if 'destroyAfterTaps' in item['manualSource'] else 'infinite'
        for drop in item['chest']['forcedDrops']:
            drop_id = extract_id(drop['itemId'])
            event_item_graph.add_edge(item_id, drop_id, gen_type=gen_type)
gen_type_to_attrs = {
    'auto': 'style=bold',
    'infinite': 'style=solid',
    'finite': 'style=dashed',
    'destroy': 'style=dashed,arrowtail=invempty',
    'merge': 'style=dashed,arrowtail=inv'
}
not_accessible = ['Gift Box', 'Regular Chest', 'Special Chest', 'Coin Bag', 'Piggybank',
                  'Ruby', 'Emerald', 'Topaz', 'Apple', 'Energy', 'Gemstone', 'Pocket Watch']
unmergeable = ['Tree', 'Sword', 'Battle Axe', 'Copper Armour'] # todo use this.. dashed border looks bad though
partition = defaultdict(set)
for node in event_item_graph:
    partition[node // 1000].add(node)
event_item_category_graph = nx.quotient_graph(event_item_graph, partition, relabel=True,
                                              create_using=nx.MultiDiGraph)
with open('event_item_category_graph.gv', 'w', encoding='utf8') as f:
    print('digraph {', file=f)
    print('\tgraph [imagepath="exported-assets\\Sprite"]', file=f)
    print('\tnode [shape=box, fontname="Charter", fontsize=11, imagescale=true]',
          file=f)
    print('\tedge [arrowsize=0.7, dir=both, arrowhead=vee, arrowtail=none]', file=f)
    for node, graph in event_item_category_graph.nodes(data='graph'):
        max_lvl = max(x for x in graph)
        caption = categories.get(max_lvl // 1000, max_lvl // 1000)
        if caption in not_accessible:
            continue
        edges = set((node, node, t) for *_, t in graph.edges(data='gen_type')
                    ) | set(event_item_category_graph.edges(node, data='gen_type'))
        width = 3 if any(t in ['auto', 'infinite'] for *_, t in edges) else 1
        label = f'<TABLE BORDER="0"><TR><TD FIXEDSIZE="TRUE" HEIGHT="50" WIDTH="50"><IMG SRC="Item-{max_lvl}.png"/></TD></TR><TR><TD>{caption}</TD></TR></TABLE>'
        print(f'\t{node} [penwidth={width}, label=<{label}>]', file=f)
        for c1, c2, gen_type in sorted(edges):
            print(f'\t{c1} -> {c2} [{gen_type_to_attrs[gen_type]}]',
                  file=f)
    print('}', file=f)

# fields = ['Category', 'Level', 'Source', 'Drops', 'Charge', 'Stack']
# gens = []
# for item in data['configs_key']['boardItemSettings1000']['items']:
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
