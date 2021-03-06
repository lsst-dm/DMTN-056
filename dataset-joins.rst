
.. _dataset_joins:

Dataset-DataUnit Joins
======================

The join tables in this section relate concrete :ref:`DataUnit <DataUnit>` to :ref:`Datasets <Dataset>`.
They thus hold the information necessary to relate :ref:`DatasetRefs <DatasetRef>` to :ref:`Datasets <Dataset>`.

The following direct connections exist:

.. graph:: dataset_dataunit_joins
    :align: center

    Visit -- Dataset
    Snap -- Dataset
    Tract -- Dataset
    Patch -- Dataset
    AbstractFilter -- Dataset
    PhysicalFilter -- Dataset
    PhysicalSensor -- Dataset

.. note::

    There is no join table to relate :ref:`Datasets <Dataset>` to :ref:`ObservedSensors <ObservedSensor>`, because the latter is itself a join table.

.. _sql_PhysicalFilterDatasetJoin:

PhysicalFilterDatasetJoins
^^^^^^^^^^^^^^^^^^^^^^^^^^
Fields:
    +----------------------+---------+----------+
    | physical_filter_name | varchar | NOT NULL |
    +----------------------+---------+----------+
    | camera_name          | varchar | NOT NULL |
    +----------------------+---------+----------+
    | dataset_id           | int     | NOT NULL |
    +----------------------+---------+----------+
    | registry_id          | int     | NOT NULL |
    +----------------------+---------+----------+
Foreign Keys:
     - (physical_filter_name, camera_name) references :ref:`sql_PhysicalFilter` (physical_filter_name, camera_name)
     - (dataset_id, registry_id) references :ref:`sql_Dataset` (dataset_id, registry_id)

.. _sql_PhysicalSensorDatasetJoin:

PhysicalSensorDatasetJoin
^^^^^^^^^^^^^^^^^^^^^^^^^
Fields:
    +------------------------+---------+----------+
    | physical_sensor_number | int     | NOT NULL |
    +------------------------+---------+----------+
    | camera_name            | varchar | NOT NULL |
    +------------------------+---------+----------+
    | dataset_id             | int     | NOT NULL |
    +------------------------+---------+----------+
    | registry_id            | int     | NOT NULL |
    +------------------------+---------+----------+
Foreign Keys:
     - (physical_sensor_number, camera_name) references :ref:`sql_PhysicalSensor` (physical_sensor_number, camera_name)
     - (dataset_id, registry_id) references :ref:`sql_Dataset` (dataset_id, registry_id)

.. _sql_VisitDatasetJoin:

VisitDatasetJoin
^^^^^^^^^^^^^^^^
Fields:
    +------------------------+---------+----------+
    | visit_number           | int     | NOT NULL |
    +------------------------+---------+----------+
    | camera_name            | varchar | NOT NULL |
    +------------------------+---------+----------+
    | dataset_id             | int     | NOT NULL |
    +------------------------+---------+----------+
    | registry_id            | int     | NOT NULL |
    +------------------------+---------+----------+
Foreign Keys:
     - (visit_number, camera_name) references :ref:`sql_Visit` (number, camera_name)
     - (dataset_id, registry_id) references :ref:`sql_Dataset` (dataset_id, registry_id)

.. _sql_SnapDatasetJoin:

SnapDatasetJoin
^^^^^^^^^^^^^^^^
Fields:
    +------------------------+---------+----------+
    | snap_index             | int     | NOT NULL |
    +------------------------+---------+----------+
    | visit_number           | int     | NOT NULL |
    +------------------------+---------+----------+
    | camera_name            | varchar | NOT NULL |
    +------------------------+---------+----------+
    | dataset_id             | int     | NOT NULL |
    +------------------------+---------+----------+
    | registry_id            | int     | NOT NULL |
    +------------------------+---------+----------+
Foreign Keys:
     - (snap_index, visit_number, camera_name) references :ref:`sql_Snap` (snap_index, visit_number, camera_name)
     - (dataset_id, registry_id) references :ref:`sql_Dataset` (dataset_id, registry_id)

.. _sql_VisitRangeDatasetJoin:

VisitRangeDatasetJoin
^^^^^^^^^^^^^^^^^^^^^
Fields:
    +------------------------+---------+----------+
    | visit_begin            | int     | NOT NULL |
    +------------------------+---------+----------+
    | visit_end              | int     | NOT NULL |
    +------------------------+---------+----------+
    | dataset_id             | int     | NOT NULL |
    +------------------------+---------+----------+
    | registry_id            | int     | NOT NULL |
    +------------------------+---------+----------+
Foreign Keys:
     - (visit_begin, visit_end, camera_name) references :ref:`sql_VisitRange` (visit_begin, visit_end, camera_name)
     - (dataset_id, registry_id) references :ref:`sql_Dataset` (dataset_id, registry_id)

.. _sql_AbstractFilterDatasetJoin:

AbstractFilterDatasetJoin
^^^^^^^^^^^^^^^^^^^^^^^^^
Fields:
    +----------------------+---------+----------+
    | abstract_filter_name | varchar | NOT NULL |
    +----------------------+---------+----------+
    | dataset_id           | int     | NOT NULL |
    +----------------------+---------+----------+
    | registry_id          | int     | NOT NULL |
    +----------------------+---------+----------+
Foreign Keys:
     - (abstract_filter_name) references :ref:`sql_AbstractFilter` (abstract_filter_name)
     - (dataset_id, registry_id) references :ref:`sql_Dataset` (dataset_id, registry_id)

.. _sql_TractDatasetJoin:

TractDatasetJoin
^^^^^^^^^^^^^^^^
Fields:
    +----------------------+---------+----------+
    | tract_number         | int     | NOT NULL |
    +----------------------+---------+----------+
    | skymap_name          | varchar | NOT NULL |
    +----------------------+---------+----------+
    | dataset_id           | int     | NOT NULL |
    +----------------------+---------+----------+
    | registry_id          | int     | NOT NULL |
    +----------------------+---------+----------+
Foreign Keys:
     - (tract_number, skymap_name) references :ref:`sql_Tract` (number, skymap_name)
     - (dataset_id, registry_id) references :ref:`sql_Dataset` (dataset_id, registry_id)

.. _sql_PatchDatasetJoin:

PatchDatasetJoin
^^^^^^^^^^^^^^^^
Fields:
    +----------------------+---------+----------+
    | patch_index          | int     | NOT NULL |
    +----------------------+---------+----------+
    | tract_number         | int     | NOT NULL |
    +----------------------+---------+----------+
    | skymap_name          | varchar | NOT NULL |
    +----------------------+---------+----------+
    | dataset_id           | int     | NOT NULL |
    +----------------------+---------+----------+
    | registry_id          | int     | NOT NULL |
    +----------------------+---------+----------+
Foreign Keys:
     - (patch_index, tract_number, skymap_name) references :ref:`sql_Patch` (patch_index, tract_number, skymap_name)
     - (dataset_id, registry_id) references :ref:`sql_Dataset` (dataset_id, registry_id)
