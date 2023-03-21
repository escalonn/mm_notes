from collections import defaultdict
import numpy as np

item = 'special chest', 2 # edit to set which item will be modelled
collect_immediately = False # whether drops will be collected asap or later at max lvl
num_simulations = 10000

equivalents = {
    'coins': [1, 3, 8, 20, 50, 120],
    'gemstone': [1, 3, 8, 20],
    'energy': [1, 6, 15, 40, 100]
}

all_drop_data = {
    # name, level
    ('piggy bank', 1): (
        15, # number of drops
        [
            (('coins', 1), 0.75),
            (('coins', 2), 0.2),
            (('gemstone', 1), 0.05)
        ]
    ),
    ('piggy bank', 2): (
        18,
        [
            (('coins', 1), 0.5),
            (('coins', 2), 0.25),
            (('coins', 3), 0.1),
            (('coins', 4), 0.05),
            (('gemstone', 1), 0.1)
        ]
    ),
    ('piggy bank', 3): (
        23,
        [
            (('gemstone', 1), 0.13),
            (('coins', 3), 0.32),
            (('coins', 4), 0.3),
            (('coins', 5), 0.15),
            (('gemstone', 2), 0.1)
        ]
    ),
    ('coin bag', 1): (
        9,
        [
            (('coins', 1), 0.65),
            (('coins', 2), 0.2),
            (('coins', 3), 0.1),
            (('gemstone', 1), 0.05)
        ]
    ),
    ('cauldron', 1): (
        5,
        [
            (('energy', 1), 0.65),
            (('energy', 2), 0.25),
            (('energy', 3), 0.1)
        ]
    ),
    ('regular chest', 1): (
        10,
        [
            (('barrel', 1), 0.1),
            (('barn', 1), 0.1),
            (('nether portal', 1), 0.1),
            (('energy', 1), 0.04),
            (('energy', 2), 0.03),
            (('coins', 1), 0.63)
        ]
    ),
    ('regular chest', 2): (
        22,
        [
            (('barrel', 1), 0.1),
            (('barn', 1), 0.1),
            (('nether portal', 1), 0.15),
            (('coins', 1), 0.26),
            (('energy', 2), 0.06),
            (('pocket watch', 1), 0.12),
            (('pocket watch', 2), 0.08),
            (('gemstone', 1), 0.13),
        ]
    ),
    ('special chest', 1): (
        12,
        [
            (('toolbox', 1), 0.12),
            (('mine', 1), 0.12),
            (('forge', 1), 0.12),
            (('energy', 1), 0.08),
            (('energy', 2), 0.04),
            (('coins', 1), 0.24),
            (('coins', 2), 0.28),
        ]
    ),
    ('special chest', 2): (
        28,
        [
            (('toolbox', 1), 0.12),
            (('mine', 1), 0.12),
            (('forge', 1), 0.12),
            (('hourglass', 1), 0.14),
            (('hourglass', 2), 0.08),
            (('energy', 2), 0.06),
            (('coins', 3), 0.24),
            (('gemstone', 1), 0.12),
        ]
    ),
}

num_reps, drop_data = all_drop_data[item]
drops, probabilities = [x[0] for x in drop_data], [x[1] for x in drop_data]
rng = np.random.default_rng()
total_results = {d[0]: 0 for d in drops}

for _ in range(num_simulations):
    results = defaultdict(int)
    for c in rng.choice(drops, num_reps, p=probabilities):
        results[c[0]] += 2 ** (int(c[1]) - 1)
    for d, n in results.items():
        e = equivalents.get(d, [1])
        if collect_immediately:
            # could just precompute up to max possible in advance
            r = 0
            for i, v in reversed(list(enumerate(e))):
                if q := n // 2 ** i:
                    r += q * v
                    n %= 2 ** i
        else:
            r = n * e[-1] / 2 ** (len(e) - 1)
        total_results[d] += r

print(item)
for d, n in total_results.items():
    print(d, n / num_simulations)
