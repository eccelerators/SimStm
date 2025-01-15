import os
import shutil
import xml.etree.cElementTree as ET
from pathlib import Path
from xml.dom import minidom
from json import loads
from setup_data_to_json import SetupToJson
from io import StringIO
from datetime import datetime
import click

class collectTestSuites:
    
    def generate(self, setup_py_file_path='test/setup.py', inoutdir_simulation_results_dir_path='test/SimulationResults'):
            
        # --------------------------
        # extract data from setup.py
        # --------------------------
        extractor = SetupToJson()
        file_path = open(setup_py_file_path, 'r')     
        print("reading {}".format(setup_py_file_path))
        json_string = extractor.extract(setup_py_file_path)
        static_setup_data = loads(json_string)
        
        test_suite_data_dict = {}
        for test_suite in static_setup_data["test_suites"]: 
            if "testsuite-indexes" in test_suite:
                for i in range(int(test_suite["testsuite-indexes"])):
                    test_suite_data_dict["{}_{:d}".format(test_suite["testsuite-name"], i)] = {"file":test_suite["file"] , "test_cases_dict" :{}}
            else:
                test_suite_data_dict[test_suite["testsuite-name"]] = {"file":test_suite["file"] , "test_cases_dict" :{}}
               
               
        for test_suite, test_suite_data in test_suite_data_dict.items():
            for f in os.listdir(inoutdir_simulation_results_dir_path):
                p = inoutdir_simulation_results_dir_path + '/' + f
                if os.path.isfile(p):
                    if Path(f).suffix == '.xml' and f.startswith(test_suite) and f[len(test_suite)] == '_':
                        test_suite_data["test_cases_dict"][f] = {}      
                        test_suite_data["test_cases_dict"][f]["end-date"] = datetime.fromtimestamp(Path(p).stat().st_mtime)  
                        fs = f.replace('.xml', '.start')
                        ps = inoutdir_simulation_results_dir_path + '/' + fs
                        test_suite_data["test_cases_dict"][f]["start-date"] = datetime.fromtimestamp(Path(ps).stat().st_mtime)

        # print(test_suite_data_dict) 

        p = inoutdir_simulation_results_dir_path + '/' + "testSuitesSimulation.start"
        tsuites_start = datetime.fromtimestamp(Path(p).stat().st_mtime)
        p = inoutdir_simulation_results_dir_path + '/' + "testSuitesSimulation.end"
        tsuites_end = datetime.fromtimestamp(Path(p).stat().st_mtime)
        tsuites_tests = 0
        tsuites_skipped = 0
        tsuites_errors = 0
        tsuites_failures = 0
        tsuites_assertions = 0       
        tsuites =  ET.Element("testsuites", name="testSuitesSimulation")
        for test_suite, test_suite_data in test_suite_data_dict.items():
            print("processing {}".format(test_suite))
            tsuite = ET.SubElement(tsuites, "testsuite", name=test_suite)
            tsuite_system_out = ET.SubElement(tsuite, "system-out")
            sop = inoutdir_simulation_results_dir_path + '/' + test_suite + ".out"
            with open(sop, "r") as f:    
                tsuite_system_out.text = f.read() 
            tsuite_system_err = ET.SubElement(tsuite, "system-err")
            soe = inoutdir_simulation_results_dir_path + '/' + test_suite + ".err"
            with open(soe, "r") as f:    
                tsuite_system_err.text = f.read()              
            
            tsuite_tests = 0
            tsuite_skipped = 0
            tsuite_errors = 0
            tsuite_failures = 0
            tsuite_assertions = 0
            tsuite_assertions = 0
            tsuite_start = None
            tsuite_end = None
            test_cases_dict = test_suite_data["test_cases_dict"]
            for k, test_cases_dict in test_cases_dict.items():
                print("processing {}".format(k))
                tsuite_tests += 1
                p = inoutdir_simulation_results_dir_path + '/' + k
                tcaseTree = ET.parse(p)
                tcase = tcaseTree.getroot()
                tcase_name = tcaseTree.find('.').attrib['name']
                tcase_assertions = tcaseTree.find('.').attrib['assertions']
                tsuite_assertions += int(tcase_assertions)
                tcase_classname = tcaseTree.find('.').attrib['classname']
                tcase_file = tcaseTree.find('.').attrib['file']
                tcase_line = tcaseTree.find('.').attrib['file']
                tcase_start = test_cases_dict["start-date"]
                tcase_end = test_cases_dict["end-date"]
                td = tcase_end - tcase_start
                if tsuite_start is None:
                    tsuite_start = tcase_start
                else:
                    if tcase_start < tsuite_start:
                        tsuite_start = tcase_start
                if tsuite_end is None:
                    tsuite_end = tcase_end
                else:
                    if tsuite_end > tcase_end:
                        tsuite_end = tcase_end                
                tcase_time = str(td.total_seconds())
                tcase_properties = tcaseTree.findall('./properties/property')
                tcase_skipped = tcaseTree.find('./skipped')
                tcase_error = tcaseTree.find('./error')
                tcase_failure = tcaseTree.find('./failure')
                
                testcase = ET.SubElement(tsuite, "testcase", 
                              name=tcase_name,  
                              assertions=tcase_assertions, 
                              classname=tcase_classname,
                              file=tcase_file,
                              line=tcase_line, 
                              time=tcase_time )
                properties = ET.SubElement(testcase, "properties")
                
                
                for tcase_property in tcase_properties:
                    ET.SubElement(properties, "property", name=tcase_property.attrib["name"], value=tcase_property.attrib["value"])
                
                if tcase_skipped is not None:
                    tsuite_skipped += 1
                    if tcase_skipped.attrib["message"] is not None:
                        ET.SubElement(testcase, "skipped", message=tcase_skipped.attrib["message"])
                    else:
                        ET.SubElement(testcase, "skipped")
                    
                if tcase_error is not None:
                    tsuite_error += 1
                    if tcase_error.attrib["message"] is not None:
                        ET.SubElement(testcase, "error", message=tcase_error.attrib["message"])
                    else:
                        ET.SubElement(testcase, "error")
                        
                if tcase_failure is not None:
                    tsuite_failures += 1
                    if tcase_failure.attrib["message"] is not None:
                        ET.SubElement(testcase, "failure", message=tcase_failure.attrib["message"])
                    else:
                        ET.SubElement(testcase, "failure")
                        
            tsuite.set("tests", str(tsuite_tests))
            tsuite.set("skipped", str(tsuite_skipped)) 
            tsuite.set("errors", str(tsuite_errors))
            tsuite.set("failures", str(tsuite_failures))
            tsuite.set("assertions", str(tsuite_assertions))    
            tsuite.set("timestamp", str(tsuite_start.isoformat()))  
            tsuite.set("time", str((tsuite_end - tsuite_start).total_seconds()))
            tsuite.set("file", test_suite_data["file"])         
                        
            tsuites_tests += tsuite_tests
            tsuites_skipped += tsuite_skipped
            tsuites_errors += tsuite_errors
            tsuites_failures += tsuite_failures
            tsuites_assertions += tsuite_assertions
            tsuites.set("tests", str(tsuites_tests))
            tsuites.set("skipped", str(tsuites_skipped)) 
            tsuites.set("errors", str(tsuites_errors))
            tsuites.set("failures", str(tsuites_failures))
            tsuites.set("assertions", str(tsuites_assertions))    
            tsuites.set("timestamp", str(tsuites_start.isoformat()))  
            tsuites.set("time", str((tsuites_end - tsuites_start).total_seconds()))
            
        ts_str = minidom.parseString(ET.tostring(tsuites)).toprettyxml(indent="   ")
        tsp = inoutdir_simulation_results_dir_path + "/testSuitesSimulation.xml"
        print("writing {}".format(tsp))  
        with open(tsp, "w") as f:    
            f.write(ts_str)                   

@click.command()
@click.option('--infile', default='../../../setup.py',  help='setup_py_file_path')
@click.option('--inoutdir_simulation_results_dir_path', default='../../../simulation/SimulationResults',  help='input and output directory with testcaseTrees to combine')
def generate(infile, inoutdir_simulation_results_dir_path):
    obj = collectTestSuites()
    obj. generate(setup_py_file_path = infile, 
                  inoutdir_simulation_results_dir_path = inoutdir_simulation_results_dir_path
                  )
              

if __name__ == '__main__':
    generate()
