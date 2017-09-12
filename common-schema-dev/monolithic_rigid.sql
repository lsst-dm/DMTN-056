--------------------------------------------------------------------------
-- Camera DataUnits
--------------------------------------------------------------------------

CREATE TABLE Camera (
    camera_id int PRIMARY KEY,
    name varchar NOT NULL,
    UNIQUE (name)
);

CREATE TABLE AbstractFilter (
    abstract_filter_id int PRIMARY KEY,
    name varchar NOT NULL,
    UNIQUE (name)
);

CREATE TABLE PhysicalFilter (
    physical_filter_id int PRIMARY KEY,
    name varchar NOT NULL,
    camera_id int NOT NULL,
    abstract_filter_id int,
    FOREIGN KEY (camera_id) REFERENCES Camera (camera_id),
    FOREIGN KEY (abstract_filter_id) REFERENCES AbstractFilter (abstract_filter_id),
    UNIQUE (name, camera_id)
);

CREATE TABLE PhysicalSensor (
    physical_sensor_id int PRIMARY KEY,
    name varchar NOT NULL,  -- may be stringified int for some cameras
    number varchar NOT NULL,   -- either name or num may be used to identify
    camera_id int NOT NULL,
    group varchar,    -- raft for LSST, rotation group for HSC?
    purpose varchar,  -- science vs. wavefront vs. guide
    FOREIGN KEY (camera_id) REFERENCES Camera (camera_id),
    CONSTRAINT UNIQUE (name, camera_id)
);

CREATE TABLE Visit (
    visit_id int PRIMARY KEY,
    number int NOT NULL,
    camera_id int NOT NULL,
    physical_filter_id int NOT NULL,
    obs_begin datetime NOT NULL,
    obs_end datetime NOT NULL,
    region blob,
    FOREIGN KEY (camera_id) REFERENCES Camera (camera_id),
    FOREIGN KEY (physical_filter_id) REFERENCES PhysicalFilter (physical_filter_id),
    CONSTRAINT UNIQUE (num, camera_id)
);

CREATE TABLE ObservedSensor (
    observed_sensor_id int PRIMARY KEY,
    visit_id int NOT NULL,
    physical_sensor_id int NOT NULL,
    region blob,
    FOREIGN KEY (visit_id) REFERENCES Visit (visit_id),
    FOREIGN KEY (physical_sensor_id) REFERENCES PhysicalSensor (physical_sensor_id),
    CONSTRAINT UNIQUE (visit_id, physical_sensor_id)
);

CREATE TABLE Snap (
    snap_id int PRIMARY KEY,
    visit_id int PRIMARY KEY,
    index int NOT NULL,
    obs_begin datetime NOT NULL,
    obs_end datetime NOT NULL,
    FOREIGN KEY (visit_id) REFERENCES Visit (visit_id)
    CONSTRAINT UNIQUE (visit_id, index)
);


--------------------------------------------------------------------------
-- SkyMap DataUnits
--------------------------------------------------------------------------

CREATE TABLE SkyMap (
    skymap_id int PRIMARY KEY,
    name varchar NOT NULL,
    CONSTRAINT UNIQUE (name)
);

CREATE TABLE Tract (
    tract_id int PRIMARY KEY,
    number int NOT NULL,
    skymap_id int NOT NULL,
    region blob,
    FOREIGN KEY (skymap_id) REFERENCES SkyMap (skymap_id),
    CONSTRAINT UNIQUE (skymap_id, num)
);

CREATE TABLE Patch (
    patch_id int PRIMARY KEY,
    tract_id int NOT NULL,
    index int NOT NULL,
    region blob,
    FOREIGN KEY (tract_id) REFERENCES Tract (tract_id),
    CONSTRAINT UNIQUE (tract_id, index)
);


--------------------------------------------------------------------------
-- Calibration DataUnits
--------------------------------------------------------------------------

CREATE TABLE CalibRange (
    calib_range_id int PRIMARY KEY,
    first_visit int NOT NULL,
    last_visit int,
    camera_id int,
    physical_filter_id int,
    FOREIGN KEY (camera_id) REFERENCES Camera (camera_id),
    FOREIGN KEY (physical_filter_id) REFERENCES PhysicalFilter (physical_filter_id),
    CONSTRAINT UNIQUE (first_visit, last_visit, camera_id, physical_filter_id)
);

CREATE TABLE SensorCalibRange (
    sensor_calib_range_id int PRIMARY KEY,
    first_visit int NOT NULL,
    last_visit int,
    phyiscal_sensor_id int,
    physical_filter_id int,
    FOREIGN KEY (physical_sensor_id) REFERENCES PhysicalSensor (physical_sensor_id),
    FOREIGN KEY (physical_filter_id) REFERENCES Filter (unit_id),
    CONSTRAINT UNIQUE (first_visit, last_visit, camera_id, physical_filter_id)
);


--------------------------------------------------------------------------
-- Other DatasetIdentifiers
--
-- All entries can be computed from calculations on DataUnit tables.
-- These are all some variety of outer product: either a complete one
-- or one limited by spatial overlaps relationships.
--
-- NOT INCLUDED IN COMMON SCHEMA
--------------------------------------------------------------------------

CREATE TABLE ObservedSensorSnapIdentifier (
    unit_id int PRIMARY KEY,
    snap_id int NOT NULL,
    sensor_id int NOT NULL,
    FOREIGN KEY (snap_id) REFERENCES Snap (snap_id),
    FOREIGN KEY (sensor_id) REFERENCES ObservedSensor (observed_sensor_id),
    CONSTRAINT UNIQUE (snap_id, sensor_id),
    -- CONSTRAINT (Snap.visit_id == ObservedSensor.visit_id)
);

CREATE TABLE PatchFilterIdentifier (
    unit_id int PRIMARY KEY,
    patch_id int NOT NULL,
    abstract_filter_id int,
    FOREIGN KEY (patch_id) REFERENCES Patch (patch_id),
    FOREIGN KEY (abstract_filter_id) REFERENCES AbstractFilter (abstract_filter_id),
    CONSTRAINT UNIQUE (patch_id, filter_id),
);

CREATE TABLE SensorTractIdentifier (
    unit_id int PRIMARY KEY,
    observed_sensor_id int NOT NULL,
    tract_id int NOT NULL,
    FOREIGN KEY (observed_sensor_id) REFERENCES ObservedSensor (observed_sensor_id),
    FOREIGN KEY (tract_id) REFERENCES Tract (tract_id),
    CONSTRAINT UNIQUE (observed_sensor_id, tract_id)
);

CREATE TABLE SensorPatchIdentifier (
    unit_id int PRIMARY KEY,
    observed_sensor_id int NOT NULL,
    patch_id int NOT NULL,
    FOREIGN KEY (observed_sensor_id) REFERENCES ObservedSensor (unit_id),
    FOREIGN KEY (patch_id) REFERENCES Patch (unit_id),
    CONSTRAINT UNIQUE (observed_sensor_id, patch_id)
);

CREATE TABLE VisitTractIdentifier (
    unit_id int PRIMARY KEY,
    visit_id int NOT NULL,
    tract_id int NOT NULL,
    FOREIGN KEY (visit_id) REFERENCES Visit (visit_id),
    FOREIGN KEY (tract_id) REFERENCES Tract (tract_id),
    CONSTRAINT UNIQUE (visit_id, tract_id)
);

CREATE TABLE VisitPatchIdentifier (
    unit_id int PRIMARY KEY,
    visit_id int NOT NULL,
    patch_id int NOT NULL,
    FOREIGN KEY (visit_id) REFERENCES Visit (visit_id),
    FOREIGN KEY (patch_id) REFERENCES Patch (patch_id),
    CONSTRAINT UNIQUE (visit_id, patch_id)
);

--------------------------------------------------------------------------
-- Calculated join tables
--
-- Some of these are trivial views that simply omit the primary key field
-- from another table that isn't part of the common schema.  That reflects
-- the fact that those primary keys are only used to tie DataUnits to
-- Datasets, and how that is done is not specified by the common schema.
--------------------------------------------------------------------------

CREATE VIEW CalibRangeJoin AS
    SELECT
        Visit.visit_id,
        CalibRange.calib_range_id
    FROM
        Visit INNER JOIN CalibRange ON (
            (Visit.num BETWEEN CalibRange.first_visit AND CalibRange.last_visit)
            AND Visit.physical_filter_id = CalibRange.physical_filter_id
        );

CREATE VIEW SensorCalibRangeJoin
    SELECT
        ObservedSensor.observed_sensor_id,
        SensorCalibRange.sensor_calib_range_id
    FROM
        ObservedSensor INNER JOIN Visit ON (ObservedSensor.visit_id = Visit.visit_id)
        INNER JOIN SensorCalibRange ON (
            (Visit.num BETWEEN SensorCalibRange.first_visit AND SensorCalibRange.last_visit)
            AND Visit.physical_filter_id = SensorCalibRange.physical_filter_id
        );

CREATE VIEW SensorTractJoin AS
    SELECT
        SensorTractIdentifier.observed_sensor_id,
        SensorTractIdentifier.tract_id
    FROM
        SensorTractIdentifier;

CREATE VIEW SensorPatchJoin AS
    SELECT
        SensorPatchIdentifier.observed_sensor_id,
        SensorPatchIdentifier.patch_id
    FROM
        SensorPatchIdentifier;

CREATE VIEW VisitTractJoin AS
    SELECT
        VisitTractIdentifier.visit_id,
        VisitTractIdentifier.tract_id
    FROM
        VisitTractIdentifier;

CREATE VIEW VisitPatchJoin AS
    SELECT
        VisitPatchIdentifier.visit_id,
        VisitPatchIdentifier.patch_id
    FROM
        VisitPatchIdentifier;

--------------------------------------------------------------------------
-- Dataset and Provenance tables
--------------------------------------------------------------------------

CREATE TABLE DatasetType (
    dataset_type_id int PRIMARY KEY,
    name varchar NOT NULL
);

CREATE TABLE Dataset (
    dataset_id int PRIMARY KEY,
    dataset_type_id NOT NULL,
    uri varchar NOT NULL,
    producer_id int,
    FOREIGN KEY (producer_id) REFERENCES Quantum (quantum_id)
);

CREATE TABLE Quantum (
    quantum_id int PRIMARY KEY,
    task varchar,
    config_id int NOT NULL,
    -- other provenance information
    FOREIGN KEY (config_id) REFERENCES Dataset (dataset_id)
);

CREATE TABLE DatasetConsumers (
    dataset_id int NOT NULL,
    quantum_id int NOT NULL,
    FOREIGN KEY (dataset_id) REFERENCES Dataset (dataset_id),
    FOREIGN KEY (quantum_id) REFERENCES Quantum (quantum_id)
);

--------------------------------------------------------------------------
-- Datasets and Dataset-DataUnit join
--
-- NOT PART OF COMMON SCHEMA
--------------------------------------------------------------------------

CREATE TABLE UnitDatasetJoin (
    unit_id int NOT NULL,
    dataset_id int NOT NULL,
    FOREIGN KEY (dataset_id) REFERENCES Dataset (dataset_id)
);


--------------------------------------------------------------------------
-- Tags for multiple repos in a single database
--
-- NOT PART OF COMMON SCHEMA
--------------------------------------------------------------------------

CREATE TABLE Tag (
    tag_id int PRIMARY KEY,
    name varchar NOT NULL,
    CONSTRAINT UNIQUE (name)
);

CREATE TABLE DatasetTagJoin (
    tag_id int PRIMARY KEY,
    dataset_id int NOT NULL,
    FOREIGN KEY (tag_id) REFERENCES Tag (tag_id),
    FOREIGN KEY (dataset_id) REFERENCES Dataset (dataset_id)
);


--------------------------------------------------------------------------
-- Views for Datasets in a Repo with tag_id=42 (examples)
--------------------------------------------------------------------------

-- Simple case: a single common-schema unit is sufficient to label
-- the Dataset.
CREATE VIEW CalExp AS
    SELECT
        Dataset.dataset_id AS dataset_id,
        Dataset.uri AS uri,
        Dataset.producer_id AS producer_id,
        UnitDatasetJoin.unit_id AS observed_sensor_id
    FROM
        Dataset
        INNER JOIN UnitDatasetJoin ON (Dataset.dataset_id = UnitDatasetJoin.dataset_id)
        INNER JOIN DatasetType ON (Dataset.dataset_type_id = DatasetType.Dataset_type_id)
        INNER JOIN DatasetTagJoin ON (Dataset.dataset_id = DatasetTagJoin.dataset_id)
    WHERE
        DatasetType.name = "CalExp"
        AND DatasetTagJoin.tag_id = 42;

-- Harder case (but still simple here): need multiple common-schema units to
-- label the dataset, but we have a predefined DatasetIdentifer table for that.
CREATE VIEW DeepCoadd AS
SELECT
        Dataset.dataset_id AS dataset_id,
        Dataset.uri AS uri,
        Dataset.producer_id AS producer_id,
        PatchFilterIdentifier.patch_id AS patch_id,
        PatchFilterIdentifier.abstract_filter_id AS abstract_filter_id
    FROM
        Dataset
        INNER JOIN UnitDatasetJoin ON (Dataset.dataset_id = UnitDatasetJoin.dataset_id)
        INNER JOIN DatasetType ON (Dataset.dataset_type_id = DatasetType.Dataset_type_id)
        INNER JOIN DatasetTagJoin ON (Dataset.dataset_id = DatasetTagJoin.dataset_id)
        INNER JOIN PatchFilterIdentifier ON (UnitDatasetJoin.unit_id = PatchFilterIdentifier.unit_id)
    WHERE
        DatasetType.name = "DeepCoadd"
        AND DatasetTagJoin.tag_id = 42;