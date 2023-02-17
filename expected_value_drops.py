from collections import defaultdict
import numpy as np

item = 'cauldron', 1 # edit to set which item will be modelled
collect_immediately = True # whether drops will be collected asap or later at max lvl
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
            (('energy', 1), 0.5),
            (('energy', 2), 0.35),
            (('energy', 3), 0.15)
        ]
    )
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
        if collect_immediately:
            # could just precompute up to max possible in advance
            r = 0
            for i, v in reversed(list(enumerate(equivalents[d]))):
                if q := n // 2 ** i:
                    r += q * v
                    n %= 2 ** i
        else:
            r = n * equivalents[d][-1] / 2 ** (len(equivalents[d]) - 1)
        total_results[d] += r

for d, n in total_results.items():
    print(d, n / num_simulations)
