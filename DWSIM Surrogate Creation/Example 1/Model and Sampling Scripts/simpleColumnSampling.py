# remove the following two lines to run on linux
import pythoncom
pythoncom.CoInitialize()     

import pandas, numpy, time
import clr

dwsimpath = "C:\\Users\\gdela\\AppData\\Local\\DWSIM\\"

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

csv_file = "data_sample1.csv"
DataFileHeaders = pandas.DataFrame([], columns = ['feed_pressure','feed_molarflow',
                                                    'feed_propane','feed_isobutane','feed_n-hexane','feed_isopentane','feed_n-heptane',
                                                    'rebolier_temp','reflux_ratio','top_pressure',
                                                    'top_molar_flow',
                                                    'top_propane','top_isobutane','top_n-hexane','top_isopentane','top_n-heptane',                                            
                                                    'bottom_molar_flow',
                                                    'bottom_propane','bottom_isobutane','bottom_n-hexane','bottom_isopentane','bottom_n-heptane',
                                                    'cduty', 'rduty',
                                                     'solved','dwsim_time'])    
#DataFileHeaders.to_csv(csv_file, index=False)

input_bounds =  {
    'feed_pressure': [175000, 225000],#pa
    'feed_molarflow': [1250, 1650], #mol/sec
    'n_hexane_isopentane_dev': [-0.075, 0.075],
    'rebolier_temp': [360, 370],
    'reflux_ratio': [0.7, 0.95],
    'top_pressure': [140000, 200000],
}

for idx in range(10):
    
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
    ifeed_pressure = numpy.random.rand()*(input_bounds["feed_pressure"][1] - input_bounds["feed_pressure"][0]) + input_bounds["feed_pressure"][0]
    ifeed_molarflow = numpy.random.rand()*(input_bounds["feed_molarflow"][1] - input_bounds["feed_molarflow"][0]) + input_bounds["feed_molarflow"][0]
    in_hexane_isopentane = numpy.random.rand()*(input_bounds["n_hexane_isopentane_dev"][1] - input_bounds["n_hexane_isopentane_dev"][0]) + input_bounds["n_hexane_isopentane_dev"][0]
    irebolier_temp = numpy.random.rand()*(input_bounds["rebolier_temp"][1] - input_bounds["rebolier_temp"][0]) + input_bounds["rebolier_temp"][0]
    ireflux_ratio = numpy.random.rand()*(input_bounds["reflux_ratio"][1] - input_bounds["reflux_ratio"][0]) + input_bounds["reflux_ratio"][0]
    itop_pressure = numpy.random.rand()*(input_bounds["top_pressure"][1] - input_bounds["top_pressure"][0]) + input_bounds["top_pressure"][0]
    
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
    manager.CalculateFlowsheet3(myflowsheet,250)
    t1 = time.time()
    
    row_data = {}
    
    #inputs to Surrogate
    
    #feed parameters
    row_data['feed_pressure'] = [feed.GetPressure()]
    row_data['feed_molarflow'] = [feed.GetMolarFlow()]
    feed_comp = feed.GetOverallComposition()
    row_data['feed_propane'] = feed_comp[0]
    row_data['feed_isobutane'] = feed_comp[1]
    row_data['feed_n-hexane'] = feed_comp[2]
    row_data['feed_isopentane'] = feed_comp[3]
    row_data['feed_n-heptane'] = feed_comp[4]
    
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
    row_data['top_n-hexane'] = top_comp[2]
    row_data['top_isopentane'] = top_comp[3]
    row_data['top_n-heptane'] = top_comp[4]
    
    #bottom
    row_data['bottom_molar_flow'] = [top.GetMolarFlow()]
    bottom_comp = bottom.GetOverallComposition()
    row_data['bottom_propane'] = bottom_comp[0]
    row_data['bottom_isobutane'] = bottom_comp[1]
    row_data['bottom_n-hexane'] = bottom_comp[2]
    row_data['bottom_isopentane'] = bottom_comp[3]
    row_data['bottom_n-heptane'] = bottom_comp[4]
    
    #duties
    row_data['cduty'] = [column.CondenserDuty]
    row_data['rduty'] = [column.ReboilerDuty]
    
    #debugging flags
    row_data['solved'] =[myflowsheet.Solved]
    row_data['dwsim_time']= [t1-t0]

    row_data = pandas.DataFrame(row_data)
    row_data.to_csv(csv_file, mode='a', header=False, index=False)
    
    #reset nominal composition
    feed.SetOverallMolarComposition(comp_nominal)

print("done!")