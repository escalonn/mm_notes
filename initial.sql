CREATE TABLE
  category (id INTEGER PRIMARY KEY NOT NULL, title TEXT);

-- the only time merge_result is something that's not id+1
-- is empty seed bags -> crystal shards and shards -> dice
CREATE TABLE
  item (
    category INTEGER NOT NULL REFERENCES category (id),
    lvl INTEGER NOT NULL,
    id INTEGER NOT NULL UNIQUE AS (category * 1000 + lvl - 1) STORED,
    title TEXT NULL,
    merge_result INTEGER NULL REFERENCES item (id),
    descr TEXT AS (title || ' lvl' || CAST(lvl AS INTEGER)),
    PRIMARY KEY (category, lvl)
  );

CREATE INDEX item_merge_result ON item (merge_result);

CREATE TABLE
  source (
    item INTEGER NOT NULL REFERENCES item (id),
    kind TEXT NOT NULL,
    charge_drops INTEGER NOT NULL,
    charge_time_s INTEGER NOT NULL,
    charge_stack INTEGER NOT NULL,
    drop_stack INTEGER NOT NULL AS (charge_drops * charge_stack),
    stack_time_s INTEGER NOT NULL AS (charge_time_s * charge_stack),
    drops_per_s REAL NOT NULL AS (charge_drops / charge_time_s),
    total_drops INTEGER NULL,
    successor INTEGER NULL REFERENCES item (id),
    spend_energy INTEGER NOT NULL DEFAULT 0,
    start_empty INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (item, kind)
  );

CREATE TABLE
  source_drop (
    item INTEGER NOT NULL,
    kind TEXT NOT NULL,
    drop_item INTEGER NOT NULL,
    rate REAL NOT NULL,
    PRIMARY KEY (item, kind, drop_item),
    FOREIGN KEY (item, kind) REFERENCES source (item, kind),
    FOREIGN KEY (drop_item) REFERENCES item (id)
  );

CREATE INDEX source_drop_drop_item ON source_drop (drop_item);

-- figure out what table knows "barrel drops 90% knife lvl1"
-- and what table knows "barrel drops 120% knife lvl1 because of lvl2 drops"
-- right now source_drop and source_drop_v are the former.
-- maybe no table knows the latter?
CREATE VIEW
  source_drop_v AS
SELECT
  item,
  kind,
  drop_item,
  rate,
  drops_per_s * rate AS drops_per_s,
  spend_energy,
  total_drops,
  successor
FROM
  source_drop
  NATURAL JOIN source
  JOIN item ON drop_item = id;

-- a * n - energy = b * m
-- we also put into here "armour lvl7 = 44 iron ingot via 44 energy"
-- i think every item need to be in here as itself too
-- also, this doesnt model time delays on equivalence (tinderbox, hay)
CREATE TABLE
  item_equiv (
    a INTEGER NOT NULL REFERENCES item (id),
    n INTEGER NOT NULL DEFAULT 1,
    energy INTEGER NOT NULL DEFAULT 0,
    b INTEGER NOT NULL REFERENCES item (id),
    m INTEGER NOT NULL DEFAULT 1,
    ratio REAL NOT NULL AS m / n,
    PRIMARY KEY (a, b)
  );

CREATE INDEX item_equiv_b ON item_equiv (b);

-- should this table think about "2 tree lvl6s" as a source, or another table
-- it shouldn't, b/c just as valid to think about 1 lvl6 and 1 lvl5.
CREATE TABLE
  recipe (
    item INTEGER NOT NULL REFERENCES item (id),
    source_item INTEGER NOT NULL,
    source_kind TEXT NOT NULL,
    avg_charge_s REAL NOT NULL,
    avg_energy REAL NOT NULL DEFAULT 0,
    avg_energy_s REAL NOT NULL AS (avg_energy * 120),
    energy_usage REAL NOT NULL AS (avg_energy_s / avg_charge_s),
    overall_time_s REAL NOT NULL AS (max(avg_charge_s, avg_energy_s)) STORED,
    PRIMARY KEY (item, source_item, source_kind),
    FOREIGN KEY (source_item, source_kind) REFERENCES source (item, kind)
  );

CREATE INDEX recipe_item ON recipe (item);

CREATE VIEW
  recipe_v AS
SELECT
  result.descr,
  source.descr,
  source_kind,
  avg_charge_s,
  avg_energy,
  avg_energy_s,
  energy_usage,
  overall_time_s,
  item,
  source
FROM
  recipe
  JOIN item AS result ON item = id
  JOIN item AS source ON source_item = source.id;

-- TODO fill item_equiv - with attn to both infinite and finite generators
-- i think it needs row for "lvl5 tool = 8 * lvl2 tool"
INSERT INTO
  item_equiv (a, n, b)
SELECT
  item_a.id,
  pow (2, item_b.lvl - item_a.lvl),
  item_b.id
FROM
  item AS item_a
  JOIN item AS item_b USING (category)
WHERE
  item_a.lvl <= item_b.lvl;

-- issue: this tells it that armour = metal scraps
-- but not that armour = iron/steel (indirection).
-- tells it that fountains = lvl1 staffs, but not lvl5.
-- (that second one's maybe ok though?)
INSERT INTO
  item_equiv (a, energy, b, m)
SELECT
  item,
  spend_energy * total_drops,
  drop_item,
  total_drops * rate
FROM
  source_drop_v
WHERE
  total_drops IS NOT NULL;

-- maybe should have table for the slices of each recipe...
-- or maybe rather a table representing the effective rates like 120%...
--    but i think that couldnt generalize to complex recipes like steel
INSERT INTO
  recipe (
    item,
    source_item,
    source_kind,
    avg_charge_s,
    avg_energy
  )
SELECT
  id,
  item,
  kind,
  1 / sum(drops_per_s * ratio),
  spend_energy * (1 + sum(rate * ratio * energy)) / sum(rate * ratio)
FROM
  item
  JOIN item_equiv ON id = b
  JOIN source_drop_v ON a = drop_item
GROUP BY
  id,
  item,
  kind;

-- possible improvements
-- relative value of purchaseable item costs
-- model "1 lvl8 and 2 lvl7s" source sets
-- maybe some way to model using 4 ads/4 hrs for charges
--    (equiv to drops_per_s increasing by charge_drops / 3600)
--    maybe recipe gets an extra column for this
