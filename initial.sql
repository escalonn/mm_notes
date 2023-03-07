CREATE TABLE
  category (id INTEGER NOT NULL PRIMARY KEY, title TEXT);

CREATE TABLE
  item (
    category INTEGER NOT NULL REFERENCES category (id),
    lvl INTEGER NOT NULL,
    id INTEGER NOT NULL UNIQUE AS (category * 1000 + lvl - 1) STORED,
    title TEXT,
    descr TEXT AS (title || ' lvl' || CAST(lvl AS INTEGER)),
    PRIMARY KEY (category, lvl)
  );

CREATE TABLE
  source (
    item INTEGER NOT NULL REFERENCES item (id),
    kind TEXT NOT NULL,
    charge_drops INTEGER NOT NULL,
    charge_time_s INTEGER NOT NULL,
    charges INTEGER NOT NULL,
    total_drops INTEGER NULL,
    successor INTEGER NULL REFERENCES item (id)
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
  source_drops (
    item INTEGER NOT NULL,
    kind TEXT NOT NULL,

    FOREIGN KEY (item, kind) REFERENCES source (item, kind)
  );
