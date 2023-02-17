import json


def decode(s):
    try:
        return json.loads(s)
    except json.JSONDecodeError:
        return s


in_name = 'raw_data.json'
key_name = 'configs_key'
# in_name = 'raw_response.json'
# key_name = 'entries'

with open(in_name, encoding='utf8') as f:
    o = json.load(f)

o[key_name] = {k: decode(v) for k, v in o[key_name].items()}

out_name = in_name[4:]
with open(out_name, 'w') as f:
    json.dump(o, f, indent=2)
