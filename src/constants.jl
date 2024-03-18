
const NO_NEIGHBOUR = -9

const KEY_ALPHA = "alpha"
const KEY_PERMEABILITY = "permeability"
const KEY_PERMEABILITY_NOISE = "permeability_noise"
const KEY_POROSITY = "porosity"
const KEY_POROSITY_NOISE = "porosity_noise"
const KEY_REFERENCE_DIRECTION = "reference_direction"
const KEY_THICKNESS = "thickness"
const KEY_TYPE = "type"
const KEY_POROSITY_1 = "porosity_1"
const KEY_P_1 = "p_1"
const KEY_PART_ID = "part_id"
const KEY_NAME = "name"


# 
const PERMEABILITY_MAX = 1.0
const PERMEABILITY_MIN = 0.0

const GAMMA_A = 1.0
const GAMMA_INIT = 0.0
const V_A = 0.
const V_INIT = 0.
const U_A = 0.
const U_INIT = 0.

# HDF group path constants
const GROUP_SIMULATION = "/simulation"
const GROUP_MESH = "/mesh"
const GROUP_CELLS = "/mesh/cells"
const GROUP_AUX = "/mesh/aux"
const GROUP_PARTS = "/mesh/parts"
const GROUP_NODES = "/mesh/nodes"
const GROUP_PARAMS = "/mesh/parameters"

# hdf name constants
const HDF_P = "p"
const HDF_RHO = "rho"
const HDF_GAMMA = "gamma"
const HDF_U = "u"
const HDF_V = "v"
const HDF_CELLPOROSITYTIMESCELLPOROSITY_FACTOR = "cellporositytimesporosityfactor"
const HDF_AP1 = "ap1"
const HDF_AP2 = "ap2"
const HDF_AP3 = "ap3"
const HDF_KAPPA = "kappa"
const HDF_RHO_A = "rho_a"
const HDF_RHO_INIT = "rho_init"
const HDF_I_MODEL = "i_model"
const HDF_RHO_0_OIL = "rho_0_oil"
const HDF_RHO_0_AIR = "rho_0_air"
const HDF_T = "t"
const HDF_ITER = "iter" 
const HDF_DELTAT = "deltat"
const HDF_P_A = "p_a"
const HDF_P_INIT = "p_init"
const HDF_N = "N"
const HDF_MAXNUMNEIGHBOURS = "maxnumberofneighbours"
const HDF_CELLPOROSITY = "cellporosity"
const HDF_CELLPERMEABILITY = "cellpermeability"
const HDF_CELLTHICKNESS = "cellthickness"
const HDF_PERMEABILITY_RATIO = "permeability_ratio"
const HDF_CELLVOLUME = "cellvolume"
const HDF_CELLCENTER_TO_CELLCENTER = "cellcentertocellcenter"
const HDF_CELLFACENORMAL = "cellfacenormal"
const HDF_CELLFACEAREA = "cellfacearea"
const HDF_T11 = "T11"
const HDF_T12 = "T12"
const HDF_T21 = "T21"
const HDF_T22 = "T22"
const HDF_INLET_INDICES = "inletCells"
const HDF_OUTLET_INDICES = "outletCells"
const HDF_TEXTILE_INDICES = "textileCells"
const HDF_CELLNEIGHBOURS = "cellneighboursarray"
const HDF_CELLALPHA = "cellalpha"
const HDF_CELLTYPE = "celltype"
const HDF_CELLAP = "cellap"
const HDF_CELLCP = "cellcp"
const HDF_MU_RESIN = "mu_resin"