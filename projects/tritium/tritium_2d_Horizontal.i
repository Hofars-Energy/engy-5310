
# Engy-5310 Problem: Poisson 2D FEM
# UMass Lowell Nuclear Chemical Engineering
# Prof. Valmor F. de Almeida
# 11Apr21 15:22:32

# Parameters [cm]
xmin = 0
xmax = 150 			
ymin = 0
ymax = 7.5
diff_coeff =  .000266493 #Diffusion of Tritium in Bulk Fluid
source_s = 0

u_center = 3.6e-07  #Concentration of Tritium in the center of the bulk fluid
flux_exit = 0   # Tritium is completely removed before leaving outflow
u_inlet = 3.6e-07   #Concentration of Tritium in the bulk fluid at inlet
velocity = '5.45 0 0' #Velocity of fluid taken from RE 10,000 


[Problem]
  type = FEProblem
  coord_type = RZ
  rz_coord_axis = x    #Revolve around the x axis (y is now radius)
    
[]

[Mesh]
  [2d]
    type = GeneratedMeshGenerator
    dim = 2
    xmin = ${replace xmin}
    xmax = ${replace xmax}
    ymin = ${replace ymin}
    ymax = ${replace ymax}
    nx = 1
    ny = 1
	elem_type=QUAD9
	
  []
[]

[Variables]
  [u]
    order = second
    family = lagrange
  []
[]
[AuxVariables]
   [diffFluxU_axial]
    order = FIRST
    family = MONOMIAL
	[]
	[diffFluxU_radius]
    order = FIRST
    family = MONOMIAL
	[]
[]


[Kernels]
  [diffusion-term]
    type = DiffusionTerm
    variable = u     # produced quantity
    diffCoeff = ${replace diff_coeff}
  []
  [source-term]
    type = SourceTerm
    variable = u     # add to produced quantity
    sourceS = ${replace source_s}
  []
   [convection-term]
    type = ConvectionTerm
    variable = u     # produced quantity 
    velocity = ${replace velocity}
  []
  
[]
[AuxKernels]
  [diffusion-flux-x]
    execute_on = timestep_end
    type = DiffusionFluxComponent       # user-built auxiliary kernel
    field = u                           # user-defined parameter
    diffCoeff = ${replace diff_coeff}   # user-defined parameter
    component = x                       # user-defined parameter
    variable = diffFluxU_axial              # produced quantity
  []
   [diffusion-flux-y]
    execute_on = timestep_end
    type = DiffusionFluxComponent       # user-built auxiliary kernel
    field = u                           # user-defined parameter
    diffCoeff = ${replace diff_coeff}   # user-defined parameter
    component = y                      # user-defined parameter
    variable = diffFluxU_radius             # produced quantity
  []
[]

[BCs]
 [metal]                            # Liquid-metal interface
 type = NormalFluxBC           		# Diffusion of Tritium into SS316 is limited by the mass transfer through pipe
 variable = u
 boundary = top    
 transferCoeff = 2.35e-03			# estimated mass transfer coeff(see Excel Sheet) [cm/s]
 reference = 0      			    #inside pipe no tritium (boundary acts as a sink)
 []
 [center]                           #center line of bulk fuel salt
  type = DirichletBC				#DirichletBc was imposed by the assumption that at tritium is removed in the secondary fluid
  variable = u                      # our unknown variable from the [Variables] block
  boundary = bottom
  value = ${replace u_center}
 []
  
  [outflow]
    type = NeumannBC
    variable = u
    boundary = right
    value = ${replace flux_exit}
  []
  [inflow]
    type = DirichletBC
    variable = u
    boundary = left
    value = ${replace u_inlet}

  []
[]

[Executioner]
  type = Steady
  solve_type = 'PJFNK'
  petsc_options_iname = '-pc_type -pc_hypre_type'
  petsc_options_value = 'hypre boomeramg'
[]

[VectorPostprocessors]
  [axial-line]
    type = LineValueSampler
    execute_on = 'timestep_end final'
    variable = 'u'    # output data
    start_point = '${replace xmin} ${fparse ymax} 0'
    end_point = '${replace xmax} ${fparse ymax} 0'
    num_points = 20
    sort_by = id
  []
[radial-line]
    type = LineValueSampler
    execute_on = 'timestep_end final'
    variable = 'u'    # output data
    start_point = '${fparse (xmax)} ${replace ymin} 0'
    end_point = '${fparse (xmax)} ${replace ymax} 0'
    num_points = 20
    sort_by = id
  []
[]


[Outputs]
  console = true
  [tecplot]
    type = Tecplot
   tecplot = true
  []
  [axial-line]
    type = CSV
    execute_on = 'final'
    show = 'axial-line'
    file_base = out-axial
  []
  [radial-line]
    type = CSV
    execute_on = 'final'
    show = 'radial-line'
    file_base = out-radial
  []
[]