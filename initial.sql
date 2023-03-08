CREATE TABLE
  category (id INTEGER NOT NULL PRIMARY KEY, title TEXT);

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
    spend_energy INTEGER NOT NULL DEFAULT (
      CASE kind
        WHEN 'manual' THEN 1
        WHEN 'auto' THEN 0
      END
    ),
    start_empty INTEGER NOT NULL DEFAULT (
      CASE kind
        WHEN 'manual' THEN 0
        WHEN 'auto' THEN 1
      END
    ),
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
-- recipe wants to reference the latter, but is referencing source_drop right now.
CREATE VIEW
  source_drop_v AS
SELECT
  item,
  kind,
  drop_item,
  rate,
  drops_per_s / rate AS drops_per_s,
  spend_energy
FROM
  source_drop
  NATURAL JOIN source
  JOIN item ON source_drop.drop_item = item.id;

CREATE TABLE
  merge_equiv (
    a INTEGER NOT NULL REFERENCES item (id),
    b INTEGER NOT NULL REFERENCES item (id),
    n INTEGER NOT NULL,
    PRIMARY KEY (a, b)
  );

CREATE TABLE
  recipe (
    item INTEGER NOT NULL REFERENCES item (id),
    source_item INTEGER NOT NULL,
    source_kind TEXT NOT NULL,
    drop_item INTEGER NOT NULL REFERENCES item (id),
    num_drops INTEGER NOT NULL,
    avg_charge_s REAL NOT NULL,
    avg_energy REAL NOT NULL,
    avg_energy_s REAL NOT NULL AS (avg_energy * 120),
    energy_usage REAL NOT NULL AS (avg_energy_s / avg_charge_s),
    overall_time_s REAL NOT NULL AS (MAX(avg_charge_s, avg_energy_s)) STORED,
    PRIMARY KEY (item, source_item, source_kind, drop_item),
    FOREIGN KEY (source_item, source_kind, drop_item) REFERENCES source (item, kind, drop_item)
  );

CREATE INDEX recipe_item ON recipe_item (item);
