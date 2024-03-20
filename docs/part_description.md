 ## Part description file 

The parts defined by the meshfile need additional parameters for the simulation. These have to be provided via a .csv-file with the following columns and one row per part.

| Column name | Description | Value range |
| :--- | :--- | :--- |      
| name | Name of the part. Will be used later on <br>to match action to inlets/ outlets | freely choosable |
| type | Type of this part | {base, inlet, outlet, patch} |
| part_id | The physical part ID assigned to the part in the mesh file | determined by mesh file |
| thickness | | |
| permeability | | |
| permeability_noise | | |
| porosity | | |
| porosity_noise | | |
| porosity_1 | | | 
| p_1 | | | 
| alpha | | | 
| refdir_1 | | |
| refdir_2 | | |
| refdir_3 | | |