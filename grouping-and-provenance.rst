
Grouping and Provenance
=======================

.. _Collection:

Collection
----------

An entity that contains :ref:`Datasets <Dataset>`, with the following conditions:

- Has at most one :ref:`Dataset` per :ref:`DatasetRef`.
- Has a unique, human-readable identifier string.
- Can be combined with a :ref:`DatasetRef` to obtain a globally unique :ref:`URI`.

Most :ref:`Registries <Registry>` contain multiple Collections.

Transition
^^^^^^^^^^

The v14 Butler's Data Repository concept plays a similar role in many contexts, but with a very different implementation and a very different relationship to the :ref:`Registry` concept.

Python API
^^^^^^^^^^

Collections are simply Python strings.

A :ref:`QuantumGraph` may be constructed to hold exactly the contents of a single :ref:`Collection`, but does not do so in general.

SQL Representation
^^^^^^^^^^^^^^^^^^

Collections are defined by a many-to-many "join" table that links :ref:`sql_Dataset` to Collections.
Because Collections are just strings, we have no independent Collection table.

.. _sql_DatasetCollectionJoin:

DatasetCollections
""""""""""""""""""
Fields:
    +-------------+---------+----------+
    | collection  | varchar | NOT NULL |
    +-------------+---------+----------+
    | dataset_id  | int     | NOT NULL |
    +-------------+---------+----------+
    | registry_id | int     | NOT NULL |
    +-------------+---------+----------+
Primary Key:
    - (collection, dataset_id, registry_id)
Foreign Keys:
    - (dataset_id, registry_id) references :ref:`sql_Dataset` (dataset_id, registry_id)


This table should be present even in :ref:`Registries <Registry>` that only represent a single Collection (though in this case it may of course be a trivial view on :ref:`sql_Dataset`).

.. todo::

    Storing the collection for every :ref:`Dataset` is costly (but may be mitigated by compression).
    Perhaps better to have a separate :ref:`Collection` table and reference by ``collection_id`` instead?

.. _Run:

Run
---

An action that produces :ref:`Datasets <Dataset>`, usually associated with a well-defined software environment.

Most Runs will correspond to a launch of a SuperTask Pipeline.

Every :ref:`Dataset` must be associated with a Run, though :ref:`Registries <Registry>` may define one or more special Runs to act as defaults or label continuous operations (e.g. raw data ingest).

Transition
^^^^^^^^^^

A Run is at least initially associated with a :ref:`Collection`, making it (like :ref:`Collection`) similar to the v14 Data Repository concept.  Again like :ref:`Collection`, its implementation is entirely different.

Python API
^^^^^^^^^^

.. py:class:: Run

    A concrete, final class representing a Run.

    Run instances in Python can only be created by :py:meth:`Registry.makeRun`.

    .. py:attribute:: collection

        The :ref:`Collection` associated with a Run.
        While a new collection is created for a Run when the Run is created, that collection may later be deleted, so this attribute may be None.

    .. py:attribute:: environment

        A :py:class:`DatasetHandle` that can be used to retreive a description of the software environment used to create the Run.

    .. py:attribute:: pipeline

        A :py:class:`DatasetHandle` that can be used to retreive the Pipeline (including configuration) used during this Run.

    .. py:attribute:: pkey

        The ``(run_id, registry_id)`` tuple used to uniquely identify this Run.

.. todo::

    If a :ref:`Collection` table is adopted, the ``collection`` can be replaced by a ``collection_id`` for increased space efficiency.

SQL Representation
^^^^^^^^^^^^^^^^^^

.. _sql_Run:

Run
"""
Fields:
    +---------------------+---------+----------+
    | run_id              | int     | NOT NULL |
    +---------------------+---------+----------+
    | registry_id         | int     | NOT NULL |
    +---------------------+---------+----------+
    | collection          | varchar |          |
    +---------------------+---------+----------+
    | environment_id      | int     |          |
    +---------------------+---------+----------+
    | pipeline_id         | int     |          |
    +---------------------+---------+----------+
Primary Key:
    run_id, registry_id
Foreign Keys:
    - (environment_id, registry_id) references :ref:`sql_Dataset` (dataset_id, registry_id)
    - (pipeline_id, registry_id) references :ref:`sql_Dataset` (dataset_id, registry_id)

Run uses the same compound primary key approach as :ref:`sql_Dataset`.

.. _Quantum:

Quantum
-------

A discrete unit of work that may depend on one or more :ref:`Datasets <Dataset>` and produces one or more :ref:`Datasets <Dataset>`.

Most Quanta will be executions of a particular SuperTask's ``runQuantum`` method, but they can also be used to represent discrete units of work performed manually by human operators or other software agents.

Transition
^^^^^^^^^^

The Quantum concept does not exist in the v14 Butler.

A Quantum is analogous to an Open Provenance Model "process".

Python API
^^^^^^^^^^

.. py:class:: Quantum

    .. py:attribute:: run

        The :py:class:`Run` this Quantum is a part of.

    .. py:attribute:: predictedInputs

        A dictionary of input datasets that were expected to be used, with :ref:`DatasetType` names as keys and a :py:class:`set` of :py:class:`DatasetRef` instances as values.

        Input :ref:`Datasets <Dataset>` that have already been stored may be :py:class:`DatasetHandles <DatasetHandle>`, and in many contexts may be guaranteed to be.

        Read-only; update via :py:meth:`addPredictedInput`.

    .. py:attribute:: actualInputs

        A dictionary of input datasets that were actually used, with the same form as :py:attr:`predictedInputs`.

        All returned sets must be subsets of those in :py:attr:`predictedInputs`.

        Read-only; update via :py:meth:`Registry.markInputUsed`.

    .. py:method:: addPredictedInput(ref)

        Add an input :ref:`DatasetRef` to the :ref:`Quantum`.

        This does not automatically update a :ref:`Registry`; all ``predictedInputs`` must be present before a :py:meth:`Registry.addQuantum` is called.

    .. py:attribute:: outputs

        A dictionary of output datasets, with the same form as :py:attr:`predictedInputs`.

        Read-only; update via :py:meth:`Registry.addDataset`, :py:meth:`QuantumGraph.addDataset`, or :py:meth:`Butler.put`.

    .. py:attribute:: task

        If the Quantum is associated with a SuperTask, this is the SuperTask instance that produced and should execute this set of inputs and outputs.
        If not, a human-readable string identifier for the operation.
        Some :ref:`Registries <Registry>` may permit the value to be None, but are not required to in general.

    .. py:attribute:: pkey

        The ``(quantum_id, registry_id)`` tuple used to uniquely identify this Run, or ``None`` if it has not yet been inserted into a :ref:`Registry`.


SQL Representation
^^^^^^^^^^^^^^^^^^

Quanta are stored in a single table that records its scalar attributes:

 .. _sql_Quantum:

Quantum
"""""""
Fields:
    +-----------------+---------+----------+
    | quantum_id      | int     | NOT NULL |
    +-----------------+---------+----------+
    | registry_id     | int     | NOT NULL |
    +-----------------+---------+----------+
    | run_id          | int     | NOT NULL |
    +-----------------+---------+----------+
    | task            | varchar |          |
    +-----------------+---------+----------+

Primary Key:
    quantum_id, registry_id
Foreign Keys:
    - (run_id, registry_id) references :ref:`sql_Run` (run_id, registry_id)

Quantum uses the same compound primary key approach as :ref:`sql_Dataset`.

The :ref:`Datasets <Dataset>` produced by a Quantum (the :py:attr:`Quantum.outputs` attribute in Python) is stored in the producer_id field in the :ref:`Dataset table <sql_Dataset>`.
The inputs, both predicted and actual, are stored in an additional join table:

.. _sql_DatasetConsumers:

DatasetConsumers
""""""""""""""""
Fields:
    +---------------------+------+----------+
    | quantum_id          | int  | NOT NULL |
    +---------------------+------+----------+
    | quantum_registry_id | int  | NOT NULL |
    +---------------------+------+----------+
    | dataset_id          | int  | NOT NULL |
    +---------------------+------+----------+
    | dataset_registry_id | int  | NOT NULL |
    +---------------------+------+----------+
    | actual              | bool | NOT NULL |
    +---------------------+------+----------+
Primary Key:
    None
Foreign Keys:
    - (quantum_id, quantum_registry_id) references :ref:`sql_Quantum` (quantum_id, registry_id)
    - (dataset_id, dataset_registry_id) references :ref:`sql_Dataset` (dataset_id, registry_id)


There is no guarantee that the full provenance of a :ref:`Dataset` is captured by these tables in all :ref:`Registries <Registry>`, because subset and transfer operations do not require provenance information to be included.  Furthermore, :ref:`Registries <Registry>` may or may not require a :ref:`Quantum` to be provided when calling :py:meth:`Registry.addDataset` (which is called by :py:meth:`Butler.put`), making it the callers responsibility to add provenance when needed.
However, all :ref:`Registries <Registry>` (including *limited* Registries) are required to record provenance information when it is provided.

.. note::

   As with everything else in the common Registry schema, the provenance system used in the operations data backbone will almost certainly involve additional fields and tables, and what's in the schema will just be a view.  But the provenance tables here are even more of a blind straw-man than the rest of the schema (which is derived more directly from SuperTask requirements), and I certainly expect it to change based on feedback; I think this reflects all that we need outside the operations system, but how operations implements their system should probably influence the details.


.. _QuantumGraph:

QuantumGraph
------------

A graph in which the nodes are :ref:`DatasetRefs <DatasetRef>` and :ref:`Quanta <Quantum>` and the edges are the producer/consumer relations between them.

Python API
^^^^^^^^^^

.. py:class:: QuantumGraph

    .. py:attribute:: datasets

        A dictionary with :ref:`DatasetType` names as keys and sets of :py:class:`DatasetRefs <DatasetRef>` of those types as values.

        Read-only (possibly only by convention); use :py:meth:`addDataset` to insert new :py:class:`DatasetRefs <DatasetRef>`.

    .. py:attribute:: quanta

        A sequence of :py:class:`Quantum` instances whose order is consistent with their dependency ordering.

        Read-only (possibly only by convention); use :py:meth:`addQuantum` to insert new :py:class:`Quanta <Quantum>`.

    .. py:method:: addQuantum(quantum)

        Add a :py:class:`Quantum` to the graph.

        Any entries in :py:attr:`Quantum.predictedInputs` or :py:attr:`Quantum.actualInputs` must already be present in the graph.
        The :py:attr:`Quantum.outputs` attribute should be empty.

    .. py:method:: addDataset(ref, producer)

        Add a :py:class:`DatasetRef` to the graph.

        :param DatasetRef ref: a pointer to the :ref:`Dataset` to be added.

        :param Quantum producer: the :py:class:`Quantum` responsible for producing the :ref:`Dataset`.  Must already be present in the graph.

    .. py:attribute:: units

        A :py:class:`DataUnitMap` that describes the relationships between the :ref:`DataUnits <DataUnit>` that label the graph's :ref:`Datasets <Dataset>`.

        May be ``None`` in some QuantumGraphs.