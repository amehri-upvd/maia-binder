.. code:: ipython3

    """
    The idea of this activity is to write an algorithm in a "distributed way", ie. operating on
    a distributed tree. 
    
    We highlight the differences with the sequential (or partitioned) version
    and compare the execution times.
    
    This is typically what you would do if you develop new functionnalities in maia.
    
    """




.. parsed-literal::

    '\nThe idea of this activity is to write an algorithm in a "distributed way", ie. operating on\na distributed tree. \n\nWe highlight the differences with the sequential (or partitioned) version\nand compare the execution times.\n\nThis is typically what you would do if you develop new functionnalities in maia.\n\n'



.. code:: ipython3

    import time
    import numpy as np
    from mpi4py import MPI
    comm = MPI.COMM_WORLD

.. code:: ipython3

    import maia
    import maia.pytree as PT

.. code:: ipython3

    class DIndexer:
        def __init__(self, distri, indices, comm):
            from maia.transfer import protocols as EP
            self.btp = EP.BlockToPart(distri, [indices], comm)
    
        def take(self, data_in):
            _, data_out = self.btp.exchange_field(data_in)
            return data_out[0]

.. code:: ipython3

    def compute_cc_seq(tree):
        zone = PT.get_node_from_label(tree, 'Zone_t')
    
        cx, cy, cz = PT.Zone.coordinates(zone)
        connec = PT.get_node_from_name(zone, 'ElementConnectivity')[1]
    
        n_elem = connec.size // 4
        connec_idx = 4*np.arange(n_elem+1)
    
        mean_x = np.add.reduceat(np.take(cx, connec-1), connec_idx[:-1]) / 4
        mean_y = np.add.reduceat(np.take(cy, connec-1), connec_idx[:-1]) / 4
        mean_z = np.add.reduceat(np.take(cz, connec-1), connec_idx[:-1]) / 4
    
        PT.new_FlowSolution('Centers',
                            loc='CellCenter',
                            fields={'CCX' : mean_x, 'CCY' : mean_y, 'CCZ' : mean_z},
                            parent=zone)

.. code:: ipython3

    def compute_cc_dist(dist_tree, comm):
        zone = PT.get_node_from_label(dist_tree, 'Zone_t')
    
        cx, cy, cz = PT.Zone.coordinates(zone)
        connec = PT.get_node_from_name(zone, 'ElementConnectivity')[1]
    
        vtx_distri = PT.maia.getDistribution(zone, 'Vertex')[1]
        indexer = DIndexer(vtx_distri, connec, comm)
        
    
        dn_elem = connec.size // 4
        connec_idx = 4*np.arange(dn_elem+1)
    
        mean_x = np.add.reduceat(indexer.take(cx), connec_idx[:-1]) / 4
        mean_y = np.add.reduceat(indexer.take(cy), connec_idx[:-1]) / 4
        mean_z = np.add.reduceat(indexer.take(cz), connec_idx[:-1]) / 4
        
        PT.new_FlowSolution('Centers',
                            loc='CellCenter',
                            fields={'CCX' : mean_x, 'CCY' : mean_y, 'CCZ' : mean_z},
                            parent=zone)
    # NB : you can try with bigger meshes, first you need to generate it using
    #dist_tree = maia.factory.generate_dist_block(101, 'TETRA_4', comm)
    #maia.io.dist_tree_to_file(dist_tree, 'tetra100.hdf', comm)

.. code:: ipython3

    FILENAME = 'tetra10.hdf'

.. code:: ipython3

    # Sequential
    if comm.rank == 0:
        tree = maia.io.read_tree('tetra10.hdf')
        compute_cc_seq(tree)
        maia.io.write_tree(tree, 'sol.hdf')
        PT.print_tree(tree)


.. parsed-literal::

    [1m[38;5;33mCGNSTree[0m [38;5;246mCGNSTree_t[0m 
    ├───CGNSLibraryVersion [38;5;246mCGNSLibraryVersion_t[0m R4 [4.2]
    └───[1m[38;5;33mBase[0m [38;5;246mCGNSBase_t[0m I4 [3 3]
        └───[1m[38;5;33mzone[0m [38;5;246mZone_t[0m I4 [[1331 5000    0]]
            ├───[1m[38;5;183mZoneType[0m [38;5;246mZoneType_t[0m "Unstructured"
            ├───[1m[38;5;183mGridCoordinates[0m [38;5;246mGridCoordinates_t[0m 
            │   ├───CoordinateX [38;5;246mDataArray_t[0m R8 (1331,)
            │   ├───CoordinateY [38;5;246mDataArray_t[0m R8 (1331,)
            │   └───CoordinateZ [38;5;246mDataArray_t[0m R8 (1331,)
            ├───[1m[38;5;183mTETRA_4.0[0m [38;5;246mElements_t[0m I4 [10  0]
            │   ├───ElementRange [38;5;246mIndexRange_t[0m I4 [   1 5000]
            │   └───ElementConnectivity [38;5;246mDataArray_t[0m I4 (20000,)
            ├───[1m[38;5;183mTRI_3.0[0m [38;5;246mElements_t[0m I4 [5 0]
            │   ├───ElementRange [38;5;246mIndexRange_t[0m I4 [5001 6200]
            │   └───ElementConnectivity [38;5;246mDataArray_t[0m I4 (3600,)
            ├───[1m[38;5;183mZoneBC[0m [38;5;246mZoneBC_t[0m 
            │   ├───Zmin [38;5;246mBC_t[0m "Null"
            │   │   ├───GridLocation [38;5;246mGridLocation_t[0m "FaceCenter"
            │   │   └───PointList [38;5;246mIndexArray_t[0m I4 (1, 200)
            │   ├───Zmax [38;5;246mBC_t[0m "Null"
            │   │   ├───GridLocation [38;5;246mGridLocation_t[0m "FaceCenter"
            │   │   └───PointList [38;5;246mIndexArray_t[0m I4 (1, 200)
            │   ├───Xmin [38;5;246mBC_t[0m "Null"
            │   │   ├───GridLocation [38;5;246mGridLocation_t[0m "FaceCenter"
            │   │   └───PointList [38;5;246mIndexArray_t[0m I4 (1, 200)
            │   ├───Xmax [38;5;246mBC_t[0m "Null"
            │   │   ├───GridLocation [38;5;246mGridLocation_t[0m "FaceCenter"
            │   │   └───PointList [38;5;246mIndexArray_t[0m I4 (1, 200)
            │   ├───Ymin [38;5;246mBC_t[0m "Null"
            │   │   ├───GridLocation [38;5;246mGridLocation_t[0m "FaceCenter"
            │   │   └───PointList [38;5;246mIndexArray_t[0m I4 (1, 200)
            │   └───Ymax [38;5;246mBC_t[0m "Null"
            │       ├───GridLocation [38;5;246mGridLocation_t[0m "FaceCenter"
            │       └───PointList [38;5;246mIndexArray_t[0m I4 (1, 200)
            └───[1m[38;5;183mCenters[0m [38;5;246mFlowSolution_t[0m 
                ├───GridLocation [38;5;246mGridLocation_t[0m "CellCenter"
                ├───CCX [38;5;246mDataArray_t[0m R8 (5000,)
                ├───CCY [38;5;246mDataArray_t[0m R8 (5000,)
                └───CCZ [38;5;246mDataArray_t[0m R8 (5000,)


.. code:: ipython3

    # Parallel partitioned
    tree = maia.io.file_to_dist_tree('tetra10.hdf', comm)
    ptree = maia.factory.partition_dist_tree(tree, comm)
    compute_cc_seq(ptree)
    maia.transfer.part_tree_to_dist_tree_all(tree, ptree, comm)
    maia.io.dist_tree_to_file(tree, 'sol.hdf', comm)
    PT.print_tree(tree)


.. parsed-literal::

    Distributed read of file tetra10.hdf...
    Read completed (0.02 s) -- Size of dist_tree for current rank is 143.7KiB (Σ=143.7KiB)
    Partitioning tree of 1 initial block...
    Partitioning completed (0.05 s) -- Nb of cells for current rank is 5.0K (Σ=5.0K)
    Distributed write of a 262.2KiB dist_tree (Σ=262.2KiB)...
    [1m[38;5;33mCGNSTree[0m [38;5;246mCGNSTree_t[0m 
    Write completed [sol.hdf] (0.51 s)
    ├───CGNSLibraryVersion [38;5;246mCGNSLibraryVersion_t[0m R4 [4.2]
    └───[1m[38;5;33mBase[0m [38;5;246mCGNSBase_t[0m I4 [3 3]
        └───[1m[38;5;33mzone[0m [38;5;246mZone_t[0m I4 [[1331 5000    0]]
            ├───[1m[38;5;183mZoneType[0m [38;5;246mZoneType_t[0m "Unstructured"
            ├───[1m[38;5;183mGridCoordinates[0m [38;5;246mGridCoordinates_t[0m 
            │   ├───CoordinateX [38;5;246mDataArray_t[0m R8 (1331,)
            │   ├───CoordinateY [38;5;246mDataArray_t[0m R8 (1331,)
            │   └───CoordinateZ [38;5;246mDataArray_t[0m R8 (1331,)
            ├───[1m[38;5;183mTETRA_4.0[0m [38;5;246mElements_t[0m I4 [10  0]
            │   ├───ElementRange [38;5;246mIndexRange_t[0m I4 [   1 5000]
            │   ├───ElementConnectivity [38;5;246mDataArray_t[0m I4 (20000,)
            │   └───:CGNS#Distribution [38;5;246mUserDefinedData_t[0m 
            │       └───Element [38;5;246mDataArray_t[0m I4 [   0 5000 5000]
            ├───[1m[38;5;183mTRI_3.0[0m [38;5;246mElements_t[0m I4 [5 0]
            │   ├───ElementRange [38;5;246mIndexRange_t[0m I4 [5001 6200]
            │   ├───ElementConnectivity [38;5;246mDataArray_t[0m I4 (3600,)
            │   └───:CGNS#Distribution [38;5;246mUserDefinedData_t[0m 
            │       └───Element [38;5;246mDataArray_t[0m I4 [   0 1200 1200]
            ├───[1m[38;5;183mZoneBC[0m [38;5;246mZoneBC_t[0m 
            │   ├───Zmin [38;5;246mBC_t[0m "Null"
            │   │   ├───GridLocation [38;5;246mGridLocation_t[0m "FaceCenter"
            │   │   ├───PointList [38;5;246mIndexArray_t[0m I4 (1, 200)
            │   │   └───:CGNS#Distribution [38;5;246mUserDefinedData_t[0m 
            │   │       └───Index [38;5;246mDataArray_t[0m I4 [  0 200 200]
            │   ├───Zmax [38;5;246mBC_t[0m "Null"
            │   │   ├───GridLocation [38;5;246mGridLocation_t[0m "FaceCenter"
            │   │   ├───PointList [38;5;246mIndexArray_t[0m I4 (1, 200)
            │   │   └───:CGNS#Distribution [38;5;246mUserDefinedData_t[0m 
            │   │       └───Index [38;5;246mDataArray_t[0m I4 [  0 200 200]
            │   ├───Xmin [38;5;246mBC_t[0m "Null"
            │   │   ├───GridLocation [38;5;246mGridLocation_t[0m "FaceCenter"
            │   │   ├───PointList [38;5;246mIndexArray_t[0m I4 (1, 200)
            │   │   └───:CGNS#Distribution [38;5;246mUserDefinedData_t[0m 
            │   │       └───Index [38;5;246mDataArray_t[0m I4 [  0 200 200]
            │   ├───Xmax [38;5;246mBC_t[0m "Null"
            │   │   ├───GridLocation [38;5;246mGridLocation_t[0m "FaceCenter"
            │   │   ├───PointList [38;5;246mIndexArray_t[0m I4 (1, 200)
            │   │   └───:CGNS#Distribution [38;5;246mUserDefinedData_t[0m 
            │   │       └───Index [38;5;246mDataArray_t[0m I4 [  0 200 200]
            │   ├───Ymin [38;5;246mBC_t[0m "Null"
            │   │   ├───GridLocation [38;5;246mGridLocation_t[0m "FaceCenter"
            │   │   ├───PointList [38;5;246mIndexArray_t[0m I4 (1, 200)
            │   │   └───:CGNS#Distribution [38;5;246mUserDefinedData_t[0m 
            │   │       └───Index [38;5;246mDataArray_t[0m I4 [  0 200 200]
            │   └───Ymax [38;5;246mBC_t[0m "Null"
            │       ├───GridLocation [38;5;246mGridLocation_t[0m "FaceCenter"
            │       ├───PointList [38;5;246mIndexArray_t[0m I4 (1, 200)
            │       └───:CGNS#Distribution [38;5;246mUserDefinedData_t[0m 
            │           └───Index [38;5;246mDataArray_t[0m I4 [  0 200 200]
            ├───[1m[38;5;183m:CGNS#Distribution[0m [38;5;246mUserDefinedData_t[0m 
            │   ├───Vertex [38;5;246mDataArray_t[0m I4 [   0 1331 1331]
            │   └───Cell [38;5;246mDataArray_t[0m I4 [   0 5000 5000]
            └───[1m[38;5;183mCenters[0m [38;5;246mFlowSolution_t[0m 
                ├───GridLocation [38;5;246mGridLocation_t[0m "CellCenter"
                ├───CCX [38;5;246mDataArray_t[0m R8 (5000,)
                ├───CCY [38;5;246mDataArray_t[0m R8 (5000,)
                └───CCZ [38;5;246mDataArray_t[0m R8 (5000,)


.. code:: ipython3

    # Parallel distributed
    tree = maia.io.file_to_dist_tree('tetra10.hdf', comm)
    compute_cc_dist(tree, comm)
    maia.io.dist_tree_to_file(tree, 'sol.hdf', comm)
    PT.print_tree(tree)


.. parsed-literal::

    Distributed read of file tetra10.hdf...
    Read completed (0.02 s) -- Size of dist_tree for current rank is 143.7KiB (Σ=143.7KiB)
    Distributed write of a 262.2KiB dist_tree (Σ=262.2KiB)...
    [1m[38;5;33mCGNSTree[0m [38;5;246mCGNSTree_t[0m 
    Write completed [sol.hdf] (0.52 s)
    ├───CGNSLibraryVersion [38;5;246mCGNSLibraryVersion_t[0m R4 [4.2]
    └───[1m[38;5;33mBase[0m [38;5;246mCGNSBase_t[0m I4 [3 3]
        └───[1m[38;5;33mzone[0m [38;5;246mZone_t[0m I4 [[1331 5000    0]]
            ├───[1m[38;5;183mZoneType[0m [38;5;246mZoneType_t[0m "Unstructured"
            ├───[1m[38;5;183mGridCoordinates[0m [38;5;246mGridCoordinates_t[0m 
            │   ├───CoordinateX [38;5;246mDataArray_t[0m R8 (1331,)
            │   ├───CoordinateY [38;5;246mDataArray_t[0m R8 (1331,)
            │   └───CoordinateZ [38;5;246mDataArray_t[0m R8 (1331,)
            ├───[1m[38;5;183mTETRA_4.0[0m [38;5;246mElements_t[0m I4 [10  0]
            │   ├───ElementRange [38;5;246mIndexRange_t[0m I4 [   1 5000]
            │   ├───ElementConnectivity [38;5;246mDataArray_t[0m I4 (20000,)
            │   └───:CGNS#Distribution [38;5;246mUserDefinedData_t[0m 
            │       └───Element [38;5;246mDataArray_t[0m I4 [   0 5000 5000]
            ├───[1m[38;5;183mTRI_3.0[0m [38;5;246mElements_t[0m I4 [5 0]
            │   ├───ElementRange [38;5;246mIndexRange_t[0m I4 [5001 6200]
            │   ├───ElementConnectivity [38;5;246mDataArray_t[0m I4 (3600,)
            │   └───:CGNS#Distribution [38;5;246mUserDefinedData_t[0m 
            │       └───Element [38;5;246mDataArray_t[0m I4 [   0 1200 1200]
            ├───[1m[38;5;183mZoneBC[0m [38;5;246mZoneBC_t[0m 
            │   ├───Zmin [38;5;246mBC_t[0m "Null"
            │   │   ├───GridLocation [38;5;246mGridLocation_t[0m "FaceCenter"
            │   │   ├───PointList [38;5;246mIndexArray_t[0m I4 (1, 200)
            │   │   └───:CGNS#Distribution [38;5;246mUserDefinedData_t[0m 
            │   │       └───Index [38;5;246mDataArray_t[0m I4 [  0 200 200]
            │   ├───Zmax [38;5;246mBC_t[0m "Null"
            │   │   ├───GridLocation [38;5;246mGridLocation_t[0m "FaceCenter"
            │   │   ├───PointList [38;5;246mIndexArray_t[0m I4 (1, 200)
            │   │   └───:CGNS#Distribution [38;5;246mUserDefinedData_t[0m 
            │   │       └───Index [38;5;246mDataArray_t[0m I4 [  0 200 200]
            │   ├───Xmin [38;5;246mBC_t[0m "Null"
            │   │   ├───GridLocation [38;5;246mGridLocation_t[0m "FaceCenter"
            │   │   ├───PointList [38;5;246mIndexArray_t[0m I4 (1, 200)
            │   │   └───:CGNS#Distribution [38;5;246mUserDefinedData_t[0m 
            │   │       └───Index [38;5;246mDataArray_t[0m I4 [  0 200 200]
            │   ├───Xmax [38;5;246mBC_t[0m "Null"
            │   │   ├───GridLocation [38;5;246mGridLocation_t[0m "FaceCenter"
            │   │   ├───PointList [38;5;246mIndexArray_t[0m I4 (1, 200)
            │   │   └───:CGNS#Distribution [38;5;246mUserDefinedData_t[0m 
            │   │       └───Index [38;5;246mDataArray_t[0m I4 [  0 200 200]
            │   ├───Ymin [38;5;246mBC_t[0m "Null"
            │   │   ├───GridLocation [38;5;246mGridLocation_t[0m "FaceCenter"
            │   │   ├───PointList [38;5;246mIndexArray_t[0m I4 (1, 200)
            │   │   └───:CGNS#Distribution [38;5;246mUserDefinedData_t[0m 
            │   │       └───Index [38;5;246mDataArray_t[0m I4 [  0 200 200]
            │   └───Ymax [38;5;246mBC_t[0m "Null"
            │       ├───GridLocation [38;5;246mGridLocation_t[0m "FaceCenter"
            │       ├───PointList [38;5;246mIndexArray_t[0m I4 (1, 200)
            │       └───:CGNS#Distribution [38;5;246mUserDefinedData_t[0m 
            │           └───Index [38;5;246mDataArray_t[0m I4 [  0 200 200]
            ├───[1m[38;5;183m:CGNS#Distribution[0m [38;5;246mUserDefinedData_t[0m 
            │   ├───Vertex [38;5;246mDataArray_t[0m I4 [   0 1331 1331]
            │   └───Cell [38;5;246mDataArray_t[0m I4 [   0 5000 5000]
            └───[1m[38;5;183mCenters[0m [38;5;246mFlowSolution_t[0m 
                ├───GridLocation [38;5;246mGridLocation_t[0m "CellCenter"
                ├───CCX [38;5;246mDataArray_t[0m R8 (5000,)
                ├───CCY [38;5;246mDataArray_t[0m R8 (5000,)
                └───CCZ [38;5;246mDataArray_t[0m R8 (5000,)

