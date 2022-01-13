/*
EE Model
*/

Macro "Externals" (Args)
    RunMacro("External", Args)
    RunMacro("IEEI", Args)
    return(1)
endmacro

Macro "External" (Args)
  RunMacro("TCB Init")
  RunMacro("Convert EE CSV to MTX", Args)
  RunMacro("Calculate EE IPF Marginals", Args)
  RunMacro("EE TOD", Args)
  RunMacro("IPF EE Seed Table", Args)
  RunMacro("EE Symmetry", Args)
endmacro

/*
Convert the base ee seed csv to mtx.
The matrix is created based on the external stations in the node layer
*/

Macro "Convert EE CSV to MTX" (Args)
  hwy_dbd = Args.Links
  ee_csv_file = Args.[Input Folder] + "\\external\\ee-seed.csv"
  ee_mtx_file = Args.[Output Folder] + "\\external\\base_ee_table.mtx"
  
  // create empty EE matrix from node layer
  {map, {nlyr, llyr}} = RunMacro("Create Map", {file: hwy_dbd})
  
  SetLayer(nlyr)
  qry = "Select * where External = 1"
  n = SelectByQuery("ext", "Several", qry)
  if n = 0 then Throw("No external stations found")
    
  opts = null
  opts.[File Name] = ee_mtx_file
  opts.Label = "EE Matrix"
  opts.Tables = {"EE_AUTO_AM", "EE_AUTO_MD", "EE_AUTO_PM", "EE_AUTO_NT",
                 "EE_CVSUT_AM", "EE_CVSUT_MD", "EE_CVSUT_PM", "EE_CVSUT_NT",
				 "EE_CVMUT_AM", "EE_CVMUT_MD", "EE_CVMUT_PM", "EE_CVMUT_NT"}
  row_spec = {nlyr + "|ext", nlyr + ".ID", "externals"}
  
  mtx = CreateMatrix(row_spec, , opts)
  
  // update the EE matrix with the seed csv
  view = OpenTable("csv", "CSV", {ee_csv_file})
  opts = null
  opts.[Missing Is Zero] = "Yes"
  UpdateMatrixFromView(
    mtx,
    view + "|",
    "orig_taz",
    "dest_taz",
    null,
    {view + ".auto", view + ".auto", view + ".auto", view + ".auto", 
	 view + ".cv_sut", view + ".cv_sut", view + ".cv_sut", view + ".cv_sut",
	 view + ".cv_mut", view + ".cv_mut", view + ".cv_mut", view + ".cv_mut"},
    "Replace",
    opts
  )
  
  mtx = null

  // Remove any nulls
  mtx = CreateObject("Matrix", ee_mtx_file)
  core_names = mtx.GetCoreNames()
  for core_name in core_names do
    core = mtx.GetCore(core_name)
    core := nz(core)
  end

  CloseView(view)
  CloseMap(map)
endmacro 


/*
Calculate the production and attraction marginals at each external station. 
*/

Macro "Calculate EE IPF Marginals" (Args)
  se_file = Args.SE
  
  se_vw = OpenTable("se", "FFB", {se_file})
  SetView(se_vw)

  data = GetDataVectors(
    se_vw + "|", 
    {
      "TAZ", 
      "AWDT",
      "PCT_AUTO_EE",
      "PCT_CVSUT_EE",
      "PCT_CVMUT_EE"
    },
    {OptArray: TRUE}
  )
  
  ee_auto_marg = Nz(data.AWDT) * (Nz(data.PCT_AUTO_EE)/100) / 2
  ee_cv_sut_marg = Nz(data.AWDT) * (Nz(data.PCT_CVSUT_EE)/100) / 2
  ee_cv_mut_marg = Nz(data.AWDT) * (Nz(data.PCT_CVMUT_EE)/100) / 2
  
  a_fields = {
    {"EE_AUTO_MARG", "Real", 10, 2, , , , "ee auto marginal"},
    {"EE_CV_SUT_MARG", "Real", 10, 2, , , , "ee cv sut marginal"},
    {"EE_CV_MUT_MARG", "Real", 10, 2, , , , "ee cv mut marginal"}
  }
  
  RunMacro("Add Fields", {view: se_vw, a_fields: a_fields})
  
  SetView(se_vw)
  SetDataVector(se_vw + "|", "EE_AUTO_MARG", ee_auto_marg, )
  SetDataVector(se_vw + "|", "EE_CV_SUT_MARG", ee_cv_sut_marg, )
  SetDataVector(se_vw + "|", "EE_CV_MUT_MARG", ee_cv_mut_marg, )
  
  CloseView(se_vw)
    
endmacro


/*
Split EE marginals by time period
*/

Macro "EE TOD" (Args)
  se_file = Args.SE
  tod_file = Args.[Input Folder] + "\\external\\ee_tod.csv"
  
  se_vw = OpenTable("se", "FFB", {se_file})
  
  {drive, folder, name, ext} = SplitPath(tod_file)
  
  RunMacro("Create Sum Product Fields", {
      view: se_vw, factor_file: tod_file,
      field_desc: "EE Marginals by Time of Day|See " + name + ext + " for details."
  })

  CloseView(se_vw)
endmacro


/*
Use the calculated marginals to IPF the base-year ee matrix.
*/

Macro "IPF EE Seed Table" (Args)
  base_mtx_file = Args.[Output Folder] + "\\external\\base_ee_table.mtx"
  ee_mtx_file = Args.[Output Folder] + "\\external\\ee_trips.mtx"
  se_file = Args.SE
  
  mtx = OpenMatrix(base_mtx_file, )
  core_names = GetMatrixCoreNames(mtx)
  {ri, ci} = GetMatrixIndex(mtx)
  
  // IPF EE trips
  Opts = null
  Opts.Input.[Base Matrix Currency] = {base_mtx_file, core_names[1], ri, ci}
  Opts.Input.[PA View Set] = {se_file, "se", "ext", "Select * where Type = 'External'"}
  Opts.Global.[Constraint Type] = "Doubly"
  Opts.Global.Iterations = 300
  Opts.Global.Convergence = 0.001
  Opts.Field.[Core Names Used] = core_names
  Opts.Field.[P Core Fields] = {"se.EE_AUTO_MARG_AM", "se.EE_AUTO_MARG_MD", "se.EE_AUTO_MARG_PM", "se.EE_AUTO_MARG_NT" , 
                                "se.EE_CV_SUT_MARG_AM", "se.EE_CV_SUT_MARG_MD", "se.EE_CV_SUT_MARG_PM", "se.EE_CV_SUT_MARG_NT",
								"se.EE_CV_MUT_MARG_AM", "se.EE_CV_MUT_MARG_MD", "se.EE_CV_MUT_MARG_PM", "se.EE_CV_MUT_MARG_NT"}
  Opts.Field.[A Core Fields] = {"se.EE_AUTO_MARG_AM", "se.EE_AUTO_MARG_MD", "se.EE_AUTO_MARG_PM", "se.EE_AUTO_MARG_NT",
                                "se.EE_CV_SUT_MARG_AM", "se.EE_CV_SUT_MARG_MD", "se.EE_CV_SUT_MARG_PM", "se.EE_CV_SUT_MARG_NT",
								"se.EE_CV_MUT_MARG_AM", "se.EE_CV_MUT_MARG_MD", "se.EE_CV_MUT_MARG_PM", "se.EE_CV_MUT_MARG_NT"}
  Opts.Output.[Output Matrix].Label = "EE Trips Matrix"
  Opts.Output.[Output Matrix].[File Name] = ee_mtx_file
  ok = RunMacro("TCB Run Procedure", "Growth Factor", Opts, &Ret)
  
  if !ok then Throw("EE IPF failed")
  
  // Check each core for errors not captured automatically by TC
  for c = 1 to Opts.Field.[Core Names Used].length do
    // e.g., if the "Fail0" option in the second element of the
    // Ret array is greater than zero, it failed
    if Ret[2].("Fail" + String(c-1)) > 0 then do
      errorcore = Opts.Field.[Core Names Used][c]
      Throw(
        "EE IPF failed. Core: " + errorcore
      )
    end
  end
  
endmacro

/*
This macro enforces symmetry on the EE matrix.
*/

Macro "EE Symmetry" (Args)
  ee_mtx_file = Args.[Output Folder] + "\\external\\ee_trips.mtx"
  
  // Open the IPFd EE mtx
  mtx = OpenMatrix(ee_mtx_file, )
  a_corenames = GetMatrixCoreNames(mtx)
  {ri, ci} = GetMatrixIndex(mtx)
  Cur = CreateMatrixCurrencies(mtx, ri, ci, )

  // Create a transposed EE matrix
  tmtx = GetTempFileName(".mtx")
  opts = null
  opts.[File Name] = tmtx
  opts.Label = transposed
  tmtx = TransposeMatrix(mtx, opts)

  // Create transposed currencies
  {tri, tci} = GetMatrixIndex(tmtx)
  tcur = CreateMatrixCurrencies(tmtx, tri, tci, )

  a_corename = GetMatrixCoreNames(mtx)
  for c = 1 to a_corename.length do
    corename = a_corename[c]
    
    // Add together and divide by two to ensure symmetry
    Cur.(corename) := (Cur.(corename) + tcur.(corename))/2
  end
EndMacro

/*
Internal External Model
*/

Macro "IEEI" (Args)
  RunMacro("TCB Init")
  RunMacro("IEEI Productions", Args)
  RunMacro("IEEI Attractions", Args)
  RunMacro("IEEI Balance Ps and As", Args)
  RunMacro("IEEI TOD", Args)
  RunMacro("IEEI Gravity", Args)
  RunMacro("IEEI Combine Matrix", Args)
  RunMacro("IEEI Directionality", Args)
endmacro

/*
Calculate IEEI productions
*/

Macro "IEEI Productions" (Args)
  se_file = Args.SE
  
  se_vw = OpenTable("se", "FFB", {se_file})
  SetView(se_vw)

  data = GetDataVectors(
    se_vw + "|", 
    {
      "TAZ",
      "Freeway_Stations",	  
      "AWDT",
      "PCT_AUTO_IEEI",
      "PCT_CVSUT_IEEI",
      "PCT_CVMUT_IEEI"
    },
    {OptArray: TRUE}
  )
  
  ieei_auto_prod_freeway = if data.Freeway_Stations = 1 then Nz(data.AWDT) * (Nz(data.PCT_AUTO_IEEI)/100) else 0
  ieei_cvsut_prod_freeway = if data.Freeway_Stations = 1 then Nz(data.AWDT) * (Nz(data.PCT_CVSUT_IEEI)/100) else 0
  ieei_cvmut_prod_freeway = if data.Freeway_Stations = 1 then Nz(data.AWDT) * (Nz(data.PCT_CVMUT_IEEI)/100) else 0
  
  ieei_auto_prod_nonfreeway = if data.Freeway_Stations = 1 then 0 else Nz(data.AWDT) * (Nz(data.PCT_AUTO_IEEI)/100)
  ieei_cvsut_prod_nonfreeway = if data.Freeway_Stations = 1 then 0 else Nz(data.AWDT) * (Nz(data.PCT_CVSUT_IEEI)/100)
  ieei_cvmut_prod_nonfreeway = if data.Freeway_Stations = 1 then 0 else Nz(data.AWDT) * (Nz(data.PCT_CVMUT_IEEI)/100)

  a_fields = {
    {"IEEI_AUTO_PROD_FREEWAY", "Real", 10, 2, , , , "ieei auto productions for freeway stations"},
    {"IEEI_CVSUT_PROD_FREEWAY", "Real", 10, 2, , , , "ieei cv sut productions for freeway stations"},
    {"IEEI_CVMUT_PROD_FREEWAY", "Real", 10, 2, , , , "ieei cv mut productions for freeway stations"},
    {"IEEI_AUTO_PROD_NONFREEWAY", "Real", 10, 2, , , , "ieei auto productions for non-freeway stations"},
    {"IEEI_CVSUT_PROD_NONFREEWAY", "Real", 10, 2, , , , "ieei cv sut productions for non-freeway stations"},
    {"IEEI_CVMUT_PROD_NONFREEWAY", "Real", 10, 2, , , , "ieei cv mut productions for non-freeway stations"}	
  }
  
  RunMacro("Add Fields", {view: se_vw, a_fields: a_fields})
  
  SetView(se_vw)
  SetDataVector(se_vw + "|", "IEEI_AUTO_PROD_FREEWAY", ieei_auto_prod_freeway, )
  SetDataVector(se_vw + "|", "IEEI_CVSUT_PROD_FREEWAY", ieei_cvsut_prod_freeway, )
  SetDataVector(se_vw + "|", "IEEI_CVMUT_PROD_FREEWAY", ieei_cvmut_prod_freeway, )
  SetDataVector(se_vw + "|", "IEEI_AUTO_PROD_NONFREEWAY", ieei_auto_prod_nonfreeway, )
  SetDataVector(se_vw + "|", "IEEI_CVSUT_PROD_NONFREEWAY", ieei_cvsut_prod_nonfreeway, )
  SetDataVector(se_vw + "|", "IEEI_CVMUT_PROD_NONFREEWAY", ieei_cvmut_prod_nonfreeway, )
  
  CloseView(se_vw)
endmacro

/*
Calculate IEEI Attractions
*/

Macro "IEEI Attractions" (Args)
  se_file = Args.SE
  ieei_model_file = Args.[Input Folder] + "\\external\\ieei_model.csv"
  
  se_vw = OpenTable("se", "FFB", {se_file})
  
  data = GetDataVectors(
    se_vw + "|",
    {
      "TAZ", 
      "HH_POP",
      "TotalEmp"
    },
    {OptArray: TRUE}
  )  

  // read airport model file for coefficients
  coeffs = RunMacro("Read Parameter File", {
    file: ieei_model_file,
    names: "variable",
    values: "coefficient"
  })

  // compute ieei attractions
  ieei_attractions = coeffs.employment * Nz(data.TotalEmp) + coeffs.population * Nz(data.HH_POP)

  a_fields = {
    {"IEEI_AUTO_ATTR_FREEWAY", "Real", 10, 2, , , , "ieei auto attractions for freeway stations"},
    {"IEEI_CVSUT_ATTR_FREEWAY", "Real", 10, 2, , , , "ieei cv sut attractions for freeway stations"},
    {"IEEI_CVMUT_ATTR_FREEWAY", "Real", 10, 2, , , , "ieei cv mut attractions for freeway stations"},
    {"IEEI_AUTO_ATTR_NONFREEWAY", "Real", 10, 2, , , , "ieei auto attractions for non-freeway stations"},
    {"IEEI_CVSUT_ATTR_NONFREEWAY", "Real", 10, 2, , , , "ieei cv sut attractions for non-freeway stations"},
    {"IEEI_CVMUT_ATTR_NONFREEWAY", "Real", 10, 2, , , , "ieei cv mut attractions for non-freeway stations"}	
  }
  
  RunMacro("Add Fields", {view: se_vw, a_fields: a_fields})
  
  SetView(se_vw)
  SetDataVector(se_vw + "|", "IEEI_AUTO_ATTR_FREEWAY", ieei_attractions, )
  SetDataVector(se_vw + "|", "IEEI_CVSUT_ATTR_FREEWAY", ieei_attractions, )
  SetDataVector(se_vw + "|", "IEEI_CVMUT_ATTR_FREEWAY", ieei_attractions, )
  SetDataVector(se_vw + "|", "IEEI_AUTO_ATTR_NONFREEWAY", ieei_attractions, )
  SetDataVector(se_vw + "|", "IEEI_CVSUT_ATTR_NONFREEWAY", ieei_attractions, )
  SetDataVector(se_vw + "|", "IEEI_CVMUT_ATTR_NONFREEWAY", ieei_attractions, )

  CloseView(se_vw)
endmacro

/*
Balance IEEI production and attraction
*/

Macro "IEEI Balance Ps and As" (Args)
  se_file = Args.SE
  
  se_vw = OpenTable("se", "FFB", {se_file})

  ieei_auto_prod_freeway = GetDataVector(se_vw + "|", "IEEI_AUTO_PROD_FREEWAY", )
  ieei_cvsut_prod_freeway = GetDataVector(se_vw + "|", "IEEI_CVSUT_PROD_FREEWAY", )
  ieei_cvmut_prod_freeway = GetDataVector(se_vw + "|", "IEEI_CVMUT_PROD_FREEWAY", )
  
  ieei_auto_prod_nonfreeway = GetDataVector(se_vw + "|", "IEEI_AUTO_PROD_NONFREEWAY", )
  ieei_cvsut_prod_nonfreeway = GetDataVector(se_vw + "|", "IEEI_CVSUT_PROD_NONFREEWAY", )
  ieei_cvmut_prod_nonfreeway = GetDataVector(se_vw + "|", "IEEI_CVMUT_PROD_NONFREEWAY", )
  
  ieei_auto_attr_freeway = GetDataVector(se_vw + "|", "IEEI_AUTO_ATTR_FREEWAY", )
  ieei_cvsut_attr_freeway = GetDataVector(se_vw + "|", "IEEI_CVSUT_ATTR_FREEWAY", )
  ieei_cvmut_attr_freeway = GetDataVector(se_vw + "|", "IEEI_CVMUT_ATTR_FREEWAY", )
  
  ieei_auto_attr_nonfreeway = GetDataVector(se_vw + "|", "IEEI_AUTO_ATTR_NONFREEWAY", )
  ieei_cvsut_attr_nonfreeway = GetDataVector(se_vw + "|", "IEEI_CVSUT_ATTR_NONFREEWAY", )
  ieei_cvmut_attr_nonfreeway = GetDataVector(se_vw + "|", "IEEI_CVMUT_ATTR_NONFREEWAY", )
  
  auto_prod_freeway_total = VectorStatistic(ieei_auto_prod_freeway, "sum", )
  cvsut_prod_freeway_total = VectorStatistic(ieei_cvsut_prod_freeway, "sum", )
  cvmut_prod_freeway_total = VectorStatistic(ieei_cvmut_prod_freeway, "sum", )
  
  auto_prod_nonfreeway_total = VectorStatistic(ieei_auto_prod_nonfreeway, "sum", )
  cvsut_prod_nonfreeway_total = VectorStatistic(ieei_cvsut_prod_nonfreeway, "sum", )
  cvmut_prod_nonfreeway_total = VectorStatistic(ieei_cvmut_prod_nonfreeway, "sum", )

  auto_attr_freeway_total = VectorStatistic(ieei_auto_attr_freeway, "sum", )
  cvsut_attr_freeway_total = VectorStatistic(ieei_cvsut_attr_freeway, "sum", )
  cvmut_attr_freeway_total = VectorStatistic(ieei_cvmut_attr_freeway, "sum", )
  
  auto_attr_nonfreeway_total = VectorStatistic(ieei_auto_attr_nonfreeway, "sum", )
  cvsut_attr_nonfreeway_total = VectorStatistic(ieei_cvsut_attr_nonfreeway, "sum", )
  cvmut_attr_nonfreeway_total = VectorStatistic(ieei_cvmut_attr_nonfreeway, "sum", )
  
  // balancing to productions (external stations)
  ieei_auto_attr_freeway = ieei_auto_attr_freeway * auto_prod_freeway_total /auto_attr_freeway_total
  ieei_cvsut_attr_freeway = ieei_cvsut_attr_freeway * cvsut_prod_freeway_total /cvsut_attr_freeway_total
  ieei_cvmut_attr_freeway = ieei_cvmut_attr_freeway * cvmut_prod_freeway_total /cvmut_attr_freeway_total
  
  ieei_auto_attr_nonfreeway = ieei_auto_attr_nonfreeway * auto_prod_nonfreeway_total /auto_attr_nonfreeway_total
  ieei_cvsut_attr_nonfreeway = ieei_cvsut_attr_nonfreeway * cvsut_prod_nonfreeway_total /cvsut_attr_nonfreeway_total
  ieei_cvmut_attr_nonfreeway = ieei_cvmut_attr_nonfreeway * cvmut_prod_nonfreeway_total /cvmut_attr_nonfreeway_total
  
  SetView(se_vw)
  SetDataVector(se_vw + "|", "IEEI_AUTO_ATTR_FREEWAY", ieei_auto_attr_freeway, )
  SetDataVector(se_vw + "|", "IEEI_CVSUT_ATTR_FREEWAY", ieei_cvsut_attr_freeway, )
  SetDataVector(se_vw + "|", "IEEI_CVMUT_ATTR_FREEWAY", ieei_cvmut_attr_freeway, )
  
  SetDataVector(se_vw + "|", "IEEI_AUTO_ATTR_NONFREEWAY", ieei_auto_attr_nonfreeway, )
  SetDataVector(se_vw + "|", "IEEI_CVSUT_ATTR_NONFREEWAY", ieei_cvsut_attr_nonfreeway, )
  SetDataVector(se_vw + "|", "IEEI_CVMUT_ATTR_NONFREEWAY", ieei_cvmut_attr_nonfreeway, )
  
  CloseView(se_vw)
  
endmacro

/*
Split IEEI balanced productions and attractions by time periods
*/

Macro "IEEI TOD" (Args)
  se_file = Args.SE
  tod_file = Args.[Input Folder] + "\\external\\ieei_tod.csv"

  se_vw = OpenTable("se", "FFB", {se_file})
  
  {drive, folder, name, ext} = SplitPath(tod_file)
  
  RunMacro("Create Sum Product Fields", {
      view: se_vw, factor_file: tod_file,
      field_desc: "IEEI Productions and Attractions by Time of Day|See " + name + ext + " for details."
  })

  CloseView(se_vw)
endmacro

/*
IEEI Gravity Distribution
*/

Macro "IEEI Gravity" (Args)
  se_file = Args.SE
  param_file = Args.[Input Folder] + "\\external\\ieei_gravity.csv"
  skim_file =  Args.[Output Folder] + "\\skims\\roadway\\accessibility_sov_AM.mtx"
  ieei_matrix_file = Args.[Output Folder] + "\\external\\ie_pa_trips.mtx"
  
  opts = null
  opts.se_file = se_file
  opts.param_file = param_file
  opts.skim_file = skim_file
  opts.output_matrix = ieei_matrix_file
  RunMacro("Gravity", opts)
  
endmacro

/*
Combine IEEI Freeway and Non-Freeway stations matrix cores
*/

Macro "IEEI Combine Matrix" (Args)
  ieei_matrix_file = Args.[Output Folder] + "\\external\\ie_pa_trips.mtx"
  periods = Args.periods
  
  ieei_mtx = OpenMatrix(ieei_matrix_file, )
  mc = CreateMatrixCurrency(ieei_mtx,,,,)
  
  new_cores = null
  for period in periods do 
    new_cores = new_cores + {"IEEI_AUTO_" + period, "IEEI_CVSUT_" + period, "IEEI_CVMUT_" + period}
  end
  
  ieei_combined_matrix_file = Substitute(ieei_matrix_file, ".mtx", "_temp.mtx", )
  matOpts = {{"File Name", ieei_combined_matrix_file}, {"Label", "IEEI Trips Matrix"}, {"File Based", "Yes"}, {"Tables", new_cores}}
  ieei_combined_mtx = CopyMatrixStructure({mc}, matOpts)
  
  mc = null
  ieei_mtx = null
  
  ieei_mtx = CreateObject("Matrix")
  ieei_mtx.LoadMatrix(ieei_matrix_file)

  ieei_combined_mtx = CreateObject("Matrix")
  ieei_combined_mtx.LoadMatrix(ieei_combined_matrix_file)
  
  for period in periods do
    cores = ieei_mtx.data.cores
	combined_cores = ieei_combined_mtx.data.cores
    
	combined_cores.("IEEI_AUTO_" + period)  := Nz(cores.("IEEI_AUTO_FREEWAY_" + period))  + Nz(cores.("IEEI_AUTO_NONFREEWAY_" + period)) 
    combined_cores.("IEEI_CVSUT_" + period) := Nz(cores.("IEEI_CVSUT_FREEWAY_" + period)) + Nz(cores.("IEEI_CVSUT_NONFREEWAY_" + period))
    combined_cores.("IEEI_CVMUT_" + period) := Nz(cores.("IEEI_CVMUT_FREEWAY_" + period)) + Nz(cores.("IEEI_CVMUT_NONFREEWAY_" + period))
  end 
  
  cores = null
  combined_cores = null
  ieei_mtx = null
  ieei_combined_mtx = null
  
  DeleteFile(ieei_matrix_file)
  RenameFile(ieei_combined_matrix_file, ieei_matrix_file)
endmacro


/*
Convert from PA to OD format
*/

Macro "IEEI Directionality" (Args)
  ieei_pa_matrix_file = Args.[Output Folder] + "\\external\\ie_pa_trips.mtx"
  ieei_od_matrix_file = Args.[Output Folder] + "\\external\\ie_od_trips.mtx"
  dir_factor_file = Args.[Input Folder] + "\\external\\ieei_directionality.csv"

  CopyFile(ieei_pa_matrix_file, ieei_od_matrix_file)
  
  ieei_od_transpose_matrix_file = Substitute(ieei_od_matrix_file, ".mtx", "_transpose.mtx", )
    
  mat = OpenMatrix(ieei_od_matrix_file, )
  tmat = TransposeMatrix(mat, {
    {"File Name", ieei_od_transpose_matrix_file},
    {"Label", "Transposed Trips"},
    {"Type", "Double"}}
  )
  mat = null
  tmat = null
    
  mtx = CreateObject("Matrix")
  mtx.LoadMatrix(ieei_od_matrix_file)  
  mtx_core_names = mtx.data.CoreNames
  cores = mtx.data.cores

  t_mtx = CreateObject("Matrix")
  t_mtx.LoadMatrix(ieei_od_transpose_matrix_file)
  t_cores = t_mtx.data.cores
  
  fac_vw = OpenTable("dir", "CSV", {dir_factor_file})
  
  rh = GetFirstRecord(fac_vw + "|", )
  while rh <> null do
    type = fac_vw.trip_type
	period = fac_vw.tod
	pa_factor = fac_vw.pa_fac
	
	core_name = "IEEI_" + type + "_" + period
	
	cores.(core_name) := Nz(cores.(core_name)) * pa_factor + Nz(t_cores.(core_name)) * (1 - pa_factor)

    rh = GetNextRecord(fac_vw + "|", rh, )
  end
  
  cores = null
  t_cores = null
  mtx = null
  t_mtx = null
  CloseView(fac_vw)
  DeleteFile(ieei_od_transpose_matrix_file)
  
endmacro