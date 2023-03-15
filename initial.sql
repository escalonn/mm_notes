-- sqlite
.mode csv
.import --csv categories.csv categories_csv

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
    descr TEXT AS (title || ' lvl' || lvl),
    PRIMARY KEY (category, lvl)
  );

CREATE INDEX item_merge_result ON item (merge_result);

CREATE INDEX item_descr ON item (descr);

CREATE TABLE
  source (
    item INTEGER NOT NULL REFERENCES item (id),
    kind TEXT NOT NULL,
    charge_drops INTEGER NOT NULL,
    charge_time_s INTEGER NOT NULL DEFAULT 0,
    charge_stack INTEGER NOT NULL,
    drop_stack INTEGER NOT NULL AS (charge_drops * charge_stack),
    stack_time_s INTEGER NOT NULL AS (charge_time_s * charge_stack),
    drops_per_s REAL NULL AS (CAST(charge_drops AS REAL) / charge_time_s),
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
-- we also need to put into here "armour lvl7 = 44 iron ingot via 44 energy"
-- every item needs to be in here as itself too
-- also, this doesnt model time delays on equivalence (tinderbox, hay)
CREATE TABLE
  item_equiv (
    a INTEGER NOT NULL REFERENCES item (id),
    n INTEGER NOT NULL DEFAULT 1,
    energy INTEGER NOT NULL DEFAULT 0,
    b INTEGER NOT NULL REFERENCES item (id),
    m INTEGER NOT NULL DEFAULT 1,
    ratio REAL NOT NULL AS (CAST(m AS REAL) / n),
    PRIMARY KEY (a, b)
  );

CREATE INDEX item_equiv_b ON item_equiv (b);

CREATE VIEW
  item_equiv_v AS
SELECT
  item_a.descr AS a,
  n,
  energy,
  item_b.descr AS b,
  m
FROM
  item_equiv
  LEFT JOIN item AS item_a ON a = item_a.id
  LEFT JOIN item AS item_b ON b = item_b.id;

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
    energy_usage REAL NULL AS (avg_energy_s / avg_charge_s),
    overall_time_s REAL NOT NULL AS (max(avg_charge_s, avg_energy_s)) STORED,
    PRIMARY KEY (item, source_item, source_kind),
    FOREIGN KEY (source_item, source_kind) REFERENCES source (item, kind)
  );

CREATE INDEX recipe_item ON recipe (item);

CREATE VIEW
  recipe_v AS
SELECT
  result.descr AS result,
  source.descr AS source,
  source_kind,
  avg_charge_s,
  avg_energy,
  avg_energy_s,
  energy_usage,
  overall_time_s,
  item,
  source_item
FROM
  recipe
  LEFT JOIN item AS result ON item = result.id
  LEFT JOIN item AS source ON source_item = source.id;

INSERT INTO
  category (id, title)
SELECT
  "Category",
  "Name"
FROM
  categories_csv;

CREATE TABLE
  configs_json (k TEXT PRIMARY KEY NOT NULL, v TEXT NOT NULL);

INSERT INTO
  configs_json (k, v)
SELECT
  key,
  value ->> '$'
FROM
  json_each(readfile ('raw_data.json') -> '$.configs_key');

CREATE TABLE
  items_json (
    id INTEGER PRIMARY KEY NOT NULL,
    lvl INTEGER NOT NULL,
    mergeable INTEGER NULL,
    manual_source_json TEXT NULL,
    auto_source_json TEXT NULL
  );

INSERT INTO
  items_json (
    id,
    lvl,
    mergeable,
    manual_source_json,
    auto_source_json
  )
SELECT
  value ->> '$.id',
  value ->> '$.level',
  value ->> '$.mergeable.nextItemId',
  value ->> '$.manualSource',
  value ->> '$.autoSource'
FROM
  json_each(
    (
      SELECT
        v
      FROM
        configs_json
      WHERE
        k = 'boardItemSettings0'
    ),
    '$.items'
  );

INSERT INTO
  item (category, lvl, title, merge_result)
SELECT
  items_json.id / 1000,
  items_json.id % 1000 + 1,
  CASE coalesce(title, '')
    WHEN '' THEN items_json.id / 1000
    ELSE title
  END,
  mergeable
FROM
  items_json
  LEFT JOIN category ON items_json.id / 1000 = category.id;

CREATE TABLE
  source_json (
    item INTEGER NOT NULL,
    kind TEXT NOT NULL,
    json TEXT NOT NULL,
    PRIMARY KEY (item, kind)
  );

INSERT INTO
  source_json
SELECT
  id,
  'manual' AS kind,
  manual_source_json AS source_json
FROM
  items_json
WHERE
  manual_source_json IS NOT NULL
UNION ALL
SELECT
  id,
  'auto' AS kind,
  auto_source_json AS source_json
FROM
  items_json
WHERE
  auto_source_json IS NOT NULL;

INSERT INTO
  source (
    item,
    kind,
    charge_drops,
    charge_time_s,
    charge_stack,
    total_drops,
    successor,
    spend_energy,
    start_empty
  )
SELECT
  item,
  kind,
  "json" ->> '$.dropsPerRecharge',
  "json" ->> '$.rechargeTimer',
  "json" ->> '$.rechargesStack',
  "json" ->> '$.destroyAfterTaps',
  "json" ->> '$.droppedItemOnDestroy',
  coalesce("json" ->> '$.spendsEnergy', 0),
  coalesce("json" ->> '$.startEmpty', 0)
FROM
  source_json;

INSERT INTO
  source_drop (item, kind, drop_item, rate)
SELECT
  source_json.item,
  source_json.kind,
  json_each.value ->> '$.dropId',
  sum(json_each.value ->> '$.dropRate')
FROM
  source_json,
  json_each(source_json.json, '$.droppableItems')
WHERE
  json_each.value ->> '$.dropId' IS NOT NULL -- to handle event Stone lvl6 dropping nothing
GROUP BY
  source_json.item,
  source_json.kind,
  json_each.value ->> '$.dropId';

-- has rows for "lvl5 tool = 8 * lvl2 tool"
-- merges:
INSERT INTO
  item_equiv (a, n, b)
SELECT
  item_a.id,
  pow(2, item_b.lvl - item_a.lvl),
  item_b.id
FROM
  item AS item_a
  JOIN item AS item_b USING (category)
WHERE
  item_a.lvl <= item_b.lvl;

-- missing crystals shards/dice transitions
-- missing armour = steel, fountains = lvl5 staffs, seed bags = lvl6 shieldmaiden
-- issue: this tells it that armour = metal scraps
--     but not that armour = iron/steel (indirection).
--     tells it that fountains = lvl1 staffs, but not lvl5.
--     (that second one's maybe ok though?)
-- issue: it doesn't know that for cauldron making energy3, energy1s help,
--     nor that cauldrons can make energy4s or 5s
-- finite generators:
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
  coalesce(1 / sum(drops_per_s * ratio), 0),
  spend_energy * (1 + sum(rate * ratio * energy)) / sum(rate * ratio)
FROM
  item
  JOIN item_equiv ON id = b
  JOIN source_drop_v ON a = drop_item
GROUP BY
  id,
  item,
  kind;

CREATE VIEW
  recipe_times_v AS
SELECT
  result,
  source,
  iif(
    avg_charge_s,
    iif(
      CAST(avg_charge_s / 86400 AS INTEGER),
      CAST(avg_charge_s / 86400 AS INTEGER) || 'd ',
      ''
    ) || iif(
      CAST(avg_charge_s / 3600 % 24 AS INTEGER),
      CAST(avg_charge_s / 3600 % 24 AS INTEGER) || 'h ',
      ''
    ) || iif(
      CAST(avg_charge_s / 60 % 60 AS INTEGER),
      CAST(avg_charge_s / 60 % 60 AS INTEGER) || 'm ',
      ''
    ) || iif(
      CAST(round(avg_charge_s % 60) AS INTEGER),
      CAST(round(avg_charge_s % 60) AS INTEGER) || 's',
      ''
    ),
    '0s'
  ) AS charge,
  CAST(round(avg_energy) AS INTEGER) AS energy,
  CAST(round(100 * energy_usage) AS INTEGER) || '%' AS energy_usage,
  iif(
    overall_time_s,
    iif(
      CAST(overall_time_s / 86400 AS INTEGER),
      CAST(overall_time_s / 86400 AS INTEGER) || 'd ',
      ''
    ) || iif(
      CAST(overall_time_s / 3600 % 24 AS INTEGER),
      CAST(overall_time_s / 3600 % 24 AS INTEGER) || 'h ',
      ''
    ) || iif(
      CAST(overall_time_s / 60 % 60 AS INTEGER),
      CAST(overall_time_s / 60 % 60 AS INTEGER) || 'm ',
      ''
    ) || iif(
      CAST(round(overall_time_s % 60) AS INTEGER),
      CAST(round(overall_time_s % 60) AS INTEGER) || 's',
      ''
    ),
    '0s'
  ) AS overall_time
FROM
  recipe_v;

-- CAST(avg_charge_s / 86400 AS INTEGER) AS charge_d,
-- CAST(avg_charge_s / 3600 % 24 AS INTEGER) AS charge_h,
-- CAST(avg_charge_s / 60 % 60 AS INTEGER) AS charge_m,
-- round(avg_charge_s % 60, 2) AS charge_s,
--
CREATE TABLE
  source_set (
    title TEXT,
    item INTEGER NOT NULL REFERENCES source (item),
    n INTEGER NOT NULL DEFAULT 1,
    PRIMARY KEY (title, item)
  );

CREATE VIEW
  source_set_v AS
SELECT
  source_set.title,
  item.descr AS item,
  source_set.n
FROM
  source_set
  JOIN item ON source_set.item = item.id;

INSERT INTO
  source_set (title, item)
SELECT
  '1 max all infinite',
  item.id
FROM
  item
  JOIN source ON item.id = source.item
WHERE
  source.total_drops IS NULL
GROUP BY
  item.category
HAVING
  max(item.lvl);

CREATE TABLE
  gift_box (
    quest_category INTEGER NOT NULL REFERENCES category (id),
    item INTEGER NOT NULL REFERENCES item (id),
    drop_item INTEGER NOT NULL REFERENCES item (id),
    total_drops INTEGER NOT NULL,
    PRIMARY KEY (quest_category, item)
  );

INSERT INTO
  gift_box (quest_category, item, drop_item, total_drops)
WITH
  gift (category, item) AS (
    SELECT
      json_each.value ->> '$.itemFamily',
      json_each.value ->> '$.giftBox'
    FROM
      configs_json,
      json_each(configs_json.v, '$.giftRewardSettings')
    WHERE
      configs_json.k = 'randomTreasureSettings0'
  )
SELECT
  gift.category,
  item,
  source_drop_v.drop_item,
  source_drop_v.total_drops
FROM
  gift
  JOIN source_drop_v USING (item);

-- DROP TABLE categories_csv;
-- DROP TABLE configs_json;
-- DROP TABLE items_json;
-- DROP TABLE source_json;
--
-- possible improvements:
-- relative value of purchaseable item costs
-- charge or energy value of gift boxes (in progress, gift_box table)
-- model "1 lvl8 and 2 lvl7s" source sets (in progress, source_set table)
-- maybe some way to model using 4 ads/4 hrs for charges
--    (equiv to drops_per_s increasing by charge_drops / 3600)
--    maybe recipe gets an extra column for this
-- maybe add logic to not show s if >1h or m if >1d
-- filter out gift boxes from recipe_v etc (use gift_box table?)
-- could use sexy recursive CTE on item_equiv to find indirect relationships....
