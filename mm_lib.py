from itertools import islice
from urllib.request import urlopen
import html5lib


def load_wiki_item_info():
    item_id_to_name = {}
    url = 'https://medieval-merge-game-fanbase.fandom.com/wiki/Game_Asset_Item_Ids'
    ns = '{http://www.w3.org/1999/xhtml}'
    with urlopen(url) as f:
        document = html5lib.parse(
            f, transport_encoding=f.info().get_content_charset())
    table = document.find('.//*[@id="mw-content-text"]//{*}table')
    for row in islice(table.iter(ns + 'tr'), 1, None):
        data = [''.join(td.itertext()).strip() for td in row.iter(ns + 'td')]
        item_id, item_name, item_level = data
        item_id_to_name[item_id] = item_name, item_level
    return item_id_to_name


def load_fallback_item_info():
    return {
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

def load_item_info():
    return load_fallback_item_info() | load_wiki_item_info()
