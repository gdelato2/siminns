import pandas
import numpy
import time
import os
import clr

def Sampler():

    # update file path and bounds as needed
    inputFilePath = './Results/DWSIM_22_10_2024_22_29_12/DataFiles/DWSIM_input.csv'
    outputFilePath = './Results/DWSIM_22_10_2024_22_29_12/DataFiles/DWSIM_data.csv'

    input_bounds = {
    'feed_pressure': [175000, 225000],
    'feed_molarflow': [1250, 2500],
    'n_hexane_isopentane_dev': [-0.15, 0.15],
    'rebolier_temp': [350, 375], 
    'reflux_ratio': [1.0, 3.0],
    'top_pressure': [180000, 260000],
                  };

    dwsimpath = "C:\\Users\\user\\AppData\\Local\\DWSIM\\"
    
    clr.AddReference(dwsimpath + "CapeOpen.dll")
    clr.AddReference(dwsimpath + "DWSIM.Automation.dll")
    clr.AddReference(dwsimpath + "DWSIM.Interfaces.dll")
    clr.AddReference(dwsimpath + "DWSIM.GlobalSettings.dll")
    clr.AddReference(dwsimpath + "DWSIM.SharedClasses.dll")
    clr.AddReference(dwsimpath + "DWSIM.Thermodynamics.dll")
    clr.AddReference(dwsimpath + "DWSIM.UnitOperations.dll")
    clr.AddReference(dwsimpath + "DWSIM.Inspector.dll")
    clr.AddReference(dwsimpath + "System.Buffers.dll")
    clr.AddReference(dwsimpath + "DWSIM.Thermodynamics.ThermoC.dll")
    
    from DWSIM.Interfaces.Enums.GraphicObjects import ObjectType
    from DWSIM.Thermodynamics import Streams, PropertyPackages
    from DWSIM.UnitOperations import UnitOperations
    from DWSIM.Automation import Automation3
    from DWSIM.GlobalSettings import Settings
    
    try:
        df = pandas.read_csv(inputFilePath)
    except Exception as e: 
        return True
    if len(df) < 11:
        time.sleep(30)  # Wait for 30 seconds
        return False
    else:
        extlen = min(len(df),10)
        extracted_rows = df.head(extlen)
        updated_df = df.iloc[extlen:]
        updated_df.to_csv(inputFilePath, index=False)
    
    # Separate the numbers and strings
    numbers_array = [[float(item) for item in sublist] for sublist in extracted_rows.iloc[:, :-1].to_numpy()]
    strings_array = extracted_rows.iloc[:, -1].to_numpy()   # Last column
    good = 0
    
    for idx in range(len(numbers_array)):        
        # create automation manager
        manager = Automation3()
        myflowsheet = manager.LoadFlowsheet('.\\simpleColumn.dwxmz')
        
        feed = myflowsheet.GetFlowsheetSimulationObject("Feed")
        top = myflowsheet.GetFlowsheetSimulationObject("Top")
        bottom = myflowsheet.GetFlowsheetSimulationObject("Bottom")
        column = myflowsheet.GetFlowsheetSimulationObject("Column")
    
        feed = feed.GetAsObject()
        top = top.GetAsObject()
        bottom = bottom.GetAsObject()
        column = column.GetAsObject()
    
        comp_nominal = feed.GetOverallComposition()
        
        # sample new inputs, replace with more sophisticated method when needed
        ifeed_pressure = numbers_array[idx][0]*(input_bounds["feed_pressure"][1] - input_bounds["feed_pressure"][0]) + input_bounds["feed_pressure"][0]
        ifeed_molarflow = numbers_array[idx][1]*(input_bounds["feed_molarflow"][1] - input_bounds["feed_molarflow"][0]) + input_bounds["feed_molarflow"][0]
        in_hexane_isopentane = numbers_array[idx][2]*(input_bounds["n_hexane_isopentane_dev"][1] - input_bounds["n_hexane_isopentane_dev"][0]) + input_bounds["n_hexane_isopentane_dev"][0]
        irebolier_temp = numbers_array[idx][3]*(input_bounds["rebolier_temp"][1] - input_bounds["rebolier_temp"][0]) + input_bounds["rebolier_temp"][0]
        ireflux_ratio = numbers_array[idx][4]*(input_bounds["reflux_ratio"][1] - input_bounds["reflux_ratio"][0]) + input_bounds["reflux_ratio"][0]
        itop_pressure = numbers_array[idx][5]*(input_bounds["top_pressure"][1] - input_bounds["top_pressure"][0]) + input_bounds["top_pressure"][0]
        
        # set feed parameters
        feed.SetPressure(ifeed_pressure) #pa
        feed.SetMolarFlow(ifeed_molarflow) #mol/sec
        comp = comp_nominal;
        comp[3] = comp[3]-in_hexane_isopentane;
        comp[2] = comp[2]+in_hexane_isopentane;
        feed.SetOverallMolarComposition(comp) #mole frac
        
        # set column parameters
        column.SetReboilerSpec("Temperature", irebolier_temp, "K")
        column.SetCondenserSpec("Reflux Ratio", ireflux_ratio, "")
        column.SetTopPressure(itop_pressure)
    
        t0 = time.time()
        column.set_ExternalLoopTolerance(0.000005)
        column.set_InternalLoopTolerance(0.000005)
        manager.CalculateFlowsheet3(myflowsheet,30)
        t1 = time.time()
        
        row_data = {}
        
        #inputs to Surrogate
        
        #feed parameters
        row_data['feed_pressure'] = [feed.GetPressure()]
        row_data['feed_molarflow'] = [feed.GetMolarFlow()]
        feed_comp = feed.GetOverallComposition()
        row_data['feed_propane'] = feed_comp[0]
        row_data['feed_isobutane'] = feed_comp[1]
        row_data['feed_n_hexane'] = feed_comp[2]
        row_data['feed_isopentane'] = feed_comp[3]
        row_data['feed_n_heptane'] = feed_comp[4]
        
        #columns settings
        row_data['rebolier_temp'] = [irebolier_temp]
        row_data['reflux_ratio'] = [column.RefluxRatio]
        row_data['top_pressure'] = [itop_pressure]
        
        #outputs to Surrogate
        
        #top
        row_data['top_molar_flow'] = [top.GetMolarFlow()]
        top_comp = top.GetOverallComposition()
        row_data['top_propane'] = top_comp[0]
        row_data['top_isobutane'] = top_comp[1]
        row_data['top_n_hexane'] = top_comp[2]
        row_data['top_isopentane'] = top_comp[3]
        row_data['top_n_heptane'] = top_comp[4]
        
        #bottom
        row_data['bottom_molar_flow'] = [top.GetMolarFlow()]
        bottom_comp = bottom.GetOverallComposition()
        row_data['bottom_propane'] = bottom_comp[0]
        row_data['bottom_isobutane'] = bottom_comp[1]
        row_data['bottom_n_hexane'] = bottom_comp[2]
        row_data['bottom_isopentane'] = bottom_comp[3]
        row_data['bottom_n_heptane'] = bottom_comp[4]
        
        #duties
        row_data['cduty'] = [column.CondenserDuty]
        row_data['rduty'] = [column.ReboilerDuty]
        
        #debugging flags
        row_data['dwsim_time']= [t1-t0]
        row_data['solved'] =[myflowsheet.Solved]
        row_data['data_set_number'] = numbers_array[idx][6]
        row_data['data_set'] = strings_array[idx]
        
        if idx == 0:
            table_data = pandas.DataFrame(row_data)
        else:
            table_data = pandas.concat([table_data, pandas.DataFrame(row_data)], ignore_index=True)
        
        #reset nominal composition
        feed.SetOverallMolarComposition(comp_nominal)
    
        if myflowsheet.Solved:
            good = good + 1
    
    table_data.to_csv(outputFilePath, mode='a', header=False, index=False)
    return True