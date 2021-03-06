
.. _dataunit_joins:

DataUnit Joins
==============

The tables (which of course may be views) in this section define many-to-many joins between :ref:`DataUnits <DataUnit>`.
Each consists of only the (compound) primary key fields of the tables being joined.

These join tables have no direct representation in Python, though the connections they define appear in a :py:class:`DataUnitMap`.

The following direct connections exist:

.. graph:: dataunit_joins
    :align: center

    VisitRange -- Visit;
    Visit -- Visit;
    Visit -- Patch;
    Visit -- Tract;
    Sensor -- Patch;
    Sensor -- Tract;

Calibration-Observation Joins
-----------------------------

.. _sql_VisitRangeJoin:

VisitRangeJoin
^^^^^^^^^^^^^^
Fields:
    +-------------------------+---------+----------+
    | visit_begin             | int     | NOT NULL |
    +-------------------------+---------+----------+
    | visit_end               | int     | NOT NULL |
    +-------------------------+---------+----------+
    | visit_number            | int     | NOT NULL |
    +-------------------------+---------+----------+
    | camera_name             | varchar | NOT NULL |
    +-------------------------+---------+----------+
Foreign Keys:
    - (visit_begin, visit_end, camera_name) references :ref:`VisitRange` (visit_begin, visit_end, camera_name)
    - (visit_number, camera_name) references :ref:`Visit` (visit_number, camera_name)

Whether the :ref:`VisitRangeJoin <sql_VisitRangeJoin>` table is calculated is TBD; it could be considered the source of truth (overriding the ranges in the :ref:`VisitRange table <sql_VisitRange>`).

If this table is calculated, it can be defined with the following view:

.. code:: sql

    CREATE VIEW VisitRangeJoin AS
    SELECT
        VisitRange.visit_begin AS visit_begin,
        VisitRange.visit_end AS visit_end,
        Visit.visit_number AS visit_number,
        Visit.camera_name AS camera_name
    FROM
        Visit INNER JOIN VisitRange ON (
            Visit.camera_name == VisitRange.camera_name
            AND
            Visit.visit_number >= VisitRange.visit_begin
            AND (
                Visit.visit_number < VisitRange.visit_end
                OR
                VisitRange.visit_end < 0
            )
        );

.. _sql_VisitSelfJoin:

VisitSelfJoin
^^^^^^^^^^^^^
Visits can be joined to Visits from other Cameras primarily to represent simultaneous observations taken for calibration purposes:

 - matching Collimated Beam Projector (CBP) configuration states to main-camera observations of the CBP;
 - matching CBP spectrograph observations to CBP configuration states.

This join table will probably only be used indirectly to relate auxilliary telescope observations with main camera observations, because that mapping may involve a spatial component as well.
Instead, we expect to aggregate all reduced auxilliary telescope observations for a night into a single :ref:`Dataset` that is associated with a :ref:`VisitRange` for the night; these are then related to raw science exposures by the :ref:`sql_VisitRangeJoin` table and interpolated temporally and spatially by science code.

Fields:
    +-------------------------+---------+----------+
    | visit_number_1          | int     | NOT NULL |
    +-------------------------+---------+----------+
    | visit_number_2          | int     | NOT NULL |
    +-------------------------+---------+----------+
    | camera_name_1           | varchar | NOT NULL |
    +-------------------------+---------+----------+
    | camera_name_2           | varchar | NOT NULL |
    +-------------------------+---------+----------+
Foreign Keys:
    - (visit_number_1, camera_name_1) references :ref:`Visit` (visit_number, camera_name)
    - (visit_number_2, camera_name_2) references :ref:`Visit` (visit_number, camera_name)

Spatial Joins
-------------

The spatial join tables below are calculated from the ``region`` fields in the tables they join, and may all be implemented as views if those calculations can be done within the database efficiently.
All but :ref:`SensorPatchJoin <sql_SensorPatchJoin>` may be implemented as views against it, but it may be more efficient to materialize all of them.

.. _sql_SensorPatchJoin:

SensorPatchJoin
^^^^^^^^^^^^^^^
Fields:
    +------------------------+---------+----------+
    | visit_number           | int     | NOT NULL |
    +------------------------+---------+----------+
    | physical_sensor_number | int     | NOT NULL |
    +------------------------+---------+----------+
    | camera_name            | varchar | NOT NULL |
    +------------------------+---------+----------+
    | tract_number           | int     | NOT NULL |
    +------------------------+---------+----------+
    | patch_index            | int     | NOT NULL |
    +------------------------+---------+----------+
    | skymap_name            | varchar | NOT NULL |
    +------------------------+---------+----------+

Foreign Keys:
    - (visit_number, physical_sensor_number, camera_name) references :ref:`ObservedSensor` (visit_number, physical_sensor_number, camera_name)
    - (tract_number, patch_index, skymap_name) references :ref:`Patch` (tract_number, patch_index, skymap_name)


.. _sql_SensorTractJoin:

SensorTractJoin
^^^^^^^^^^^^^^^
Fields:
    +------------------------+---------+----------+
    | visit_number           | int     | NOT NULL |
    +------------------------+---------+----------+
    | physical_sensor_number | int     | NOT NULL |
    +------------------------+---------+----------+
    | camera_name            | varchar | NOT NULL |
    +------------------------+---------+----------+
    | tract_number           | int     | NOT NULL |
    +------------------------+---------+----------+
    | skymap_name            | varchar | NOT NULL |
    +------------------------+---------+----------+

Foreign Keys:
    - (visit_number, physical_sensor_number, camera_name) references :ref:`ObservedSensor` (visit_number, physical_sensor_number, camera_name)
    - (tract_number, skymap_name) references :ref:`Tract` (tract_number, skymap_name)

May be implemented as:

.. code:: sql

    CREATE VIEW SensorTractJoin AS
    SELECT DISTINCT
        visit_number,
        physical_sensor_number,
        camera_name,
        tract_number,
        skymap_name
    FROM
        SensorPatchJoin;


.. _sql_VisitPatchJoin:

VisitPatchJoin
^^^^^^^^^^^^^^
Fields:
    +------------------------+---------+----------+
    | visit_number           | int     | NOT NULL |
    +------------------------+---------+----------+
    | camera_name            | varchar | NOT NULL |
    +------------------------+---------+----------+
    | tract_number           | int     | NOT NULL |
    +------------------------+---------+----------+
    | patch_index            | int     | NOT NULL |
    +------------------------+---------+----------+
    | skymap_name            | varchar | NOT NULL |
    +------------------------+---------+----------+

Foreign Keys:
    - (visit_number, camera_name) references :ref:`Visit` (visit_number, camera_name)
    - (tract_number, patch_index, skymap_name) references :ref:`Patch` (tract_number, patch_index, skymap_name)

May be implemented as:

.. code:: sql

    CREATE VIEW VisitPatchJoin AS
    SELECT DISTINCT
        visit_number,
        camera_name,
        tract_number,
        patch_index,
        skymap_name
    FROM
        SensorPatchJoin;


.. _sql_VisitTractJoin:

VisitTractJoin
^^^^^^^^^^^^^^
Fields:
    +------------------------+---------+----------+
    | visit_number           | int     | NOT NULL |
    +------------------------+---------+----------+
    | camera_name            | varchar | NOT NULL |
    +------------------------+---------+----------+
    | tract_number           | int     | NOT NULL |
    +------------------------+---------+----------+
    | skymap_name            | varchar | NOT NULL |
    +------------------------+---------+----------+

Foreign Keys:
    - (visit_number, camera_name) references :ref:`Visit` (visit_number, camera_name)
    - (tract_number, skymap_name) references :ref:`Tract` (tract_number, skymap_name)

May be implemented as:

.. code:: sql

    CREATE VIEW VisitTractJoin AS
    SELECT DISTINCT
        visit_number,
        camera_name,
        tract_number,
        skymap_name
    FROM
        SensorPatchJoin;
