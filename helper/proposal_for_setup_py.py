import os
from jinja2 import Environment, FileSystemLoader, Template
from pathlib import Path, PurePath

import click
from vhdeps import run_cli
import io
from contextlib import redirect_stdout



class GenerateProposalForSetupPy:
    
    def generate(self, indir_project, infile_setup_template_py, outfile_setup_proposal):

        project_folder_path = os.path.abspath(indir_project)       
        project_folder_name = PurePath(project_folder_path).name
        project_name = self.project_folder_name_to_project_name(project_folder_name)

        src_vhdl_folders = [
                        'src_to_customize', \
                        'src'               
                        ]
        
        tb_vhdl_folders = [
                      'tb', \
                      ]
        
        tb_simstm_folders = [                                           
                      'tb/simstm', \
                      ]
        
        other_folders = { 
            project_folder_name : [
                {"source_folder": ".", "suffixes":[".md", ".rst"]}
            ]
        }
        
        for f in os.listdir(project_folder_path + '/src/vhdl'):
            if os.path.isfile(project_folder_path + '/src/vhdl' + '/' + f):
                if Path(project_folder_path + '/src/vhdl' + '/' + f).suffix in ['.vhd', '.vhdl']:                  
                    if "tb_simstm" in f:
                        top_entity_file = f
                    
        for f in os.listdir(project_folder_path + '/tb/hdl'):
            if os.path.isfile(project_folder_path + '/tb/hdl' + '/' + f):
                if Path(project_folder_path + '/tb/hdl' + '/' + f).suffix in ['.vhd', '.vhdl']:                   
                    if "tbTop" in f:
                        tb_top_entity_file = f
                    
        f = open(project_folder_path + '/src/vhdl' + '/' + top_entity_file, 'r')
        f_lines = f.readlines()
        for l in f_lines:
            if "entity" in l:
                top_entity = l.split()[1]
                break
        
        f = open(project_folder_path + '/tb/hdl' + '/' + tb_top_entity_file, 'r')
        f_lines = f.readlines()
        for l in f_lines:
            if "entity" in l:
                tb_top_entity = l.split()[1]
                break     
         
        hdl_file_list = []    
        for src_vhdl_folder in src_vhdl_folders:
            hdl_file_list += self.get_files_by_suffixes(project_folder_path, None, src_vhdl_folder, ['.vhd', '.vhdl'])
        for tb_vhdl_folder in tb_vhdl_folders:
            hdl_file_list += self.get_files_by_suffixes(project_folder_path, None, tb_vhdl_folder, ['.vhd', '.vhdl'])
            
                   
        package_dict = {} 
        for hf in hdl_file_list:
            f = open(project_folder_path + '/' + hf, 'r')
            f_lines = f.readlines()
            for l in f_lines:
                ls =  l.split()
                if len(ls) > 0:
                    if "package" in ls[0].lower():
                        if len(ls) > 1:
                            if not "body" in ls[1].lower():
                                package_dict[hf] = {}
                                package_name = ls[1].strip()
                                package_dict[hf] ["package_name"] = package_name
                                break                

        for hf in hdl_file_list:
            f = open(project_folder_path + '/' + hf, 'r')
            f_lines = f.readlines()
            for l in f_lines:
                ls =  l.split()
                if len(ls) > 0:
                    if "package" in ls[0].lower():
                        if len(ls) > 1:
                            if "body" in ls[1].lower():
                                package_body_name = ls[2].strip()
                                for pfk, pfv in package_dict.items():
                                    if pfv["package_name"] == package_body_name:
                                        pfv["body_source_file_path"] = hf                       
                                        break
                            else:
                                break

        
  
        vhdeps_cmd_args = ["dump", tb_top_entity]
        
        vhof = io.StringIO()
        for sf in src_vhdl_folders:
            vhdeps_cmd_args += ["-x", indir_project + '/' + sf]
        for tf in tb_vhdl_folders:
            vhdeps_cmd_args += ["-x", indir_project + '/' + tf]
        with redirect_stdout(vhof):   
            run_cli(args=vhdeps_cmd_args)  
        vhofs = vhof.getvalue()  
        vhofs = vhofs.replace("dep ", "").replace("top ", "").replace("work ", "").replace("2008 ", "").replace("\\", "/").replace(project_folder_path.replace("\\", "/") + "/", "")       
 
        utilized_src_or_tb_files = vhofs.split()
        utilized_src_or_tb_files_hdl_order_dict = {}
        hdl_order = 0
        for usf in utilized_src_or_tb_files:
             utilized_src_or_tb_files_hdl_order_dict[usf] = "{:0>5d}".format(hdl_order)
             hdl_order += 10
             
        for usf in utilized_src_or_tb_files:            
             if usf in package_dict:
                 if "body_source_file_path" in package_dict[usf]:
                     additional_utilized_file = package_dict[usf]["body_source_file_path"]
                     utilized_src_or_tb_files.append(additional_utilized_file)    
                     additional_utilized_file_hdl_order = utilized_src_or_tb_files_hdl_order_dict[usf]
                     utilized_src_or_tb_files_hdl_order_dict[additional_utilized_file] = "{:0>5d}".format(int(additional_utilized_file_hdl_order) + 1)                 
                                            
        TestSuiteFileDictList = []  
        if os.path.exists(project_folder_path + '/tb/simstm/TestSuites'):  
            for f in os.listdir(project_folder_path + '/tb/simstm/TestSuites'):
                if os.path.isfile(project_folder_path + '/tb/simstm/TestSuites' + '/' + f):
                    if Path(project_folder_path + '/tb/simstm/TestSuites' + '/' + f).suffix in ['.stm']:                   
                        if "TestSuite" in f:  
                            TestSuiteObjectName = Path(project_folder_path + '/tb/simstm/TestSuites' + '/' + f).stem[9:]   
                            if TestSuiteObjectName.startswith("Indexed"):
                                isIndexedTestSuite = True
                            else:
                                isIndexedTestSuite = False                         
                            tsf = open(project_folder_path + '/tb/simstm/TestSuites' + '/' + f, 'r')
                            tsf_lines = tsf.readlines()
                            for l in tsf_lines:
                                if l.startswith("testSuite"):
                                    testsuite_name = l.split(':')[0]
                                    break
                            entry_file = "testMainSuite"  + TestSuiteObjectName + ".stm"
                            entry_label = "$testMainSuite" + TestSuiteObjectName  
                        if isIndexedTestSuite:  
                            tsmf = open(project_folder_path+ '/tb/simstm/' + entry_file, 'r')
                            tsmf_lines = tsmf.readlines()
                            testsuite_indexes = ""
                            for l in tsmf_lines:
                                if "const" in l and "testMainSuite"  + TestSuiteObjectName + "MaximumIndex" in l:
                                    testsuite_indexes = l.split()[2]
                                    break      
                            if testsuite_indexes == "" :
                                print("line: 'const testMainSuite" + TestSuiteObjectName + "MaximumIndex = ?' is missing in file: " + project_folder_path+ '/tb/simstm/' + entry_file)                                                                      
                                exit()
                            TestSuiteFileDictList.append({"testsuite-name": testsuite_name, 
                                                      "file":"TestSuites/" + f,
                                                      "testsuite-indexes": testsuite_indexes,                                                   
                                                      "entry-file":entry_file, 
                                                      "entry-label":entry_label})
                        else:
                            TestSuiteFileDictList.append({"testsuite-name": testsuite_name, 
                                                      "file":"TestSuites/" + f,                                                
                                                      "entry-file":entry_file, 
                                                      "entry-label":entry_label})
            
                       
        TestLabFileDictList = []
        if os.path.exists(project_folder_path + '/tb/simstm/TestLabs'):
            for f in os.listdir(project_folder_path + '/tb/simstm/TestLabs'):
                if os.path.isfile(project_folder_path + '/tb/simstm/TestLabs' + '/' + f):
                    if Path(project_folder_path + '/tb/simstm/TestLabs' + '/' + f).suffix in ['.stm']:                   
                        if "TestLab" in f:  
                            TestLabObjectName = Path(project_folder_path + '/tb/simstm/TestLabs' + '/' + f).stem[7:]                         
                            tsf = open(project_folder_path + '/tb/simstm/TestLabs' + '/' + f, 'r')
                            tsf_lines = tsf.readlines()
                            for l in tsf_lines:
                                if l.startswith("testLab"):
                                    testlab_name = l.split(':')[0]
                                    break
                            entry_file = "testMainLab"  + TestLabObjectName + ".stm"
                            entry_label = "$testMainLab" + TestLabObjectName  
                        TestLabFileDictList.append({"testlab-name": testlab_name, 
                                                  "file":"TestLabs/" + f,                                                
                                                  "entry-file":entry_file, 
                                                  "entry-label":entry_label})  
                    
        
                                  
        data_file_lists_str = ""            
        data_file_lists_str += '    "test_suites" : [\n'
        for i,d in enumerate(TestSuiteFileDictList):     
            if "testsuite-indexes" in d:
                data_file_lists_str +='            {{"testsuite-name":"{}", "file":"{}", "testsuite-indexes":"{}", "entry-file":"{}", "entry-label":"{}"}}'.format(d["testsuite-name"], d["file"], d["testsuite-indexes"], d["entry-file"], d["entry-label"])
            else:
                data_file_lists_str +='            {{"testsuite-name":"{}", "file":"{}", "entry-file":"{}", "entry-label":"{}"}}'.format(d["testsuite-name"], d["file"], d["entry-file"], d["entry-label"])                
            if i < len(TestSuiteFileDictList) - 1:
                data_file_lists_str +=',\n'
            else:
                data_file_lists_str +='\n'            
        data_file_lists_str += '    ],\n'

        data_file_lists_str += '    "test_labs" : [\n'
        for i,d in enumerate(TestLabFileDictList):     
            data_file_lists_str +='            {{"testlab-name":"{}", "file":"{}", "entry-file":"{}", "entry-label":"{}"}}'.format(d["testlab-name"], d["file"], d["entry-file"], d["entry-label"])                
            if i < len(TestLabFileDictList) - 1:
                data_file_lists_str +=',\n'
            else:
                data_file_lists_str +='\n'            
        data_file_lists_str += '    ],\n'      
        
        data_file_lists_str += '    "other_data_files" : [(\n'
        destination_folder_destination_files_dict_tupple_list = []
        for other_destination_folder, other_source_folder_dict_list in other_folders.items():
            files_dict_list = []
            for other_source_folder_dict in other_source_folder_dict_list:        
                files_dict_list += self.get_other_destination_files(project_folder_path, None, other_source_folder_dict["source_folder"], other_source_folder_dict["suffixes"], top_entity)
            destination_folder_destination_files_dict_tupple_list.append((other_destination_folder, files_dict_list))
        for j,d in enumerate(destination_folder_destination_files_dict_tupple_list):         
            data_file_lists_str += '        "{}", [\n'.format(d[0])
            for i, fd in enumerate(d[1]):
                if fd["source_file_path"].startswith("./"):
                    fdc = fd["source_file_path"][2:]
                else:
                    fdc = fd["source_file_path"]
                data_file_lists_str +='            {{"file":"{}"}}'.format( fdc)
                if i < len(d[1]) - 1:
                    data_file_lists_str +=',\n'
                else:
                    data_file_lists_str +='\n'  
            if j < len(destination_folder_destination_files_dict_tupple_list) - 1:
                data_file_lists_str +='        ]),(\n'
            else:
                data_file_lists_str +='        ])\n'            
        data_file_lists_str += '    ],\n'    
        
        data_file_lists_str += '    "src_data_files" : [(\n'
        
        destination_folder_destination_files_dict_tupple_list = []
 
        for vhdl_folder in src_vhdl_folders:            
            destination_folder_destination_files_dict_tupple_list += self.get_vhdl_destination_folder_destination_files_tupples(project_folder_path, project_folder_name, None, vhdl_folder, ['.vhd', '.vhdl'])             
        for j,d in enumerate(destination_folder_destination_files_dict_tupple_list):         
            data_file_lists_str += '        "{}", [\n'.format(d[0])
            for i, fd in enumerate(d[1]):
                if fd["file_type"] == "IP-XACT":
                    data_file_lists_str +='            {{"file":"{}", "file_type":"{}"}}'.format( fd["source_file_path"], fd["file_type"])
                    data_file_lists_str +=',\n'                  
                else: 
                    if fd["source_file_path"] in utilized_src_or_tb_files:                                  
                        data_file_lists_str +='            {{"file":"{}", "file_type":"{}", "hdl_order":"{}"}}'.format( fd["source_file_path"], fd["file_type"], utilized_src_or_tb_files_hdl_order_dict[fd["source_file_path"]])
                        data_file_lists_str +=',\n'
            if data_file_lists_str[-2:] == ',\n':
                data_file_lists_str = data_file_lists_str[:-2] + '\n'                          
            if j < len(destination_folder_destination_files_dict_tupple_list) - 1:
                data_file_lists_str +='        ]),(\n'
            else:
                data_file_lists_str +='        ])\n'
        data_file_lists_str += '    ],\n'
        
        data_file_lists_str += '    "tb_data_files" : [(\n'
        destination_folder_destination_files_dict_tupple_list = []        
        for vhdl_folder in tb_vhdl_folders:            
            destination_folder_destination_files_dict_tupple_list += self.get_vhdl_destination_folder_destination_files_tupples(project_folder_path, project_folder_name, None, vhdl_folder, ['.vhd', '.vhdl'])      
        for j,d in enumerate(destination_folder_destination_files_dict_tupple_list):         
            data_file_lists_str += '        "{}", [\n'.format(d[0])
            for i, fd in enumerate(d[1]):
                if fd["source_file_path"] in utilized_src_or_tb_files:
                    data_file_lists_str +='            {{"file":"{}", "file_type":"{}", "hdl_order":"{}", "ghdl_options":["-frelaxed"]}}'.format( fd["source_file_path"], fd["file_type"], utilized_src_or_tb_files_hdl_order_dict[fd["source_file_path"]])
                    data_file_lists_str +=',\n'
            if data_file_lists_str[-2:] == ',\n':
                data_file_lists_str = data_file_lists_str[:-2] + '\n'                               
            if j < len(destination_folder_destination_files_dict_tupple_list) - 1:
                data_file_lists_str +='        ]),(\n'
            else:
                data_file_lists_str +='        ])\n'
        data_file_lists_str += '    ],\n'
            
        data_file_lists_str += '    "src_tb_simstm_data_files" : [(\n'
        destination_folder_destination_files_dict_tupple_list = []
        for simstm_folder in tb_simstm_folders:            
            destination_folder_destination_files_dict_tupple_list += self.get_destination_folder_destination_files_tupples(project_folder_path, project_folder_name, None, simstm_folder, ['.stm'])       
        for j,d in enumerate(destination_folder_destination_files_dict_tupple_list):         
            data_file_lists_str += '        "{}", [\n'.format(d[0])
            for i, fd in enumerate(d[1]):
                data_file_lists_str +='            {{"file":"{}"}}'.format( fd["source_file_path"])
                if i < len(d[1]) - 1:
                    data_file_lists_str +=',\n'
                else:
                    data_file_lists_str +='\n'         
            if j < len(destination_folder_destination_files_dict_tupple_list) - 1:
                data_file_lists_str +='        ]),(\n'
            else:
                data_file_lists_str +='        ])\n'
        data_file_lists_str += '    ],\n'
        
   
        context = {
                "data_file_lists" : data_file_lists_str,
                "project_folder_name" : project_folder_name,
                "project_name" : project_name,
                "top_entity" : top_entity,
                "top_entity_file" : "src/vhdl/" + top_entity_file,
                "tb_top_entity" : tb_top_entity,
                "tb_top_entity_file" : "/tb/hdl/" + tb_top_entity_file,
            }   

        print(data_file_lists_str)    

        template_file = open(infile_setup_template_py, 'r')     
        print("reading {}".format(infile_setup_template_py))                          
        print("writing {}".format(outfile_setup_proposal)) 
        template = Template(template_file.read())
        r = template.render(context)
        f = open(outfile_setup_proposal, 'w')
        f.write(r)
        f.close()
        
                              
    def project_folder_name_to_project_name(self, project_folder_name):
        project_name = ""
        project_folder_name_parts = project_folder_name.split('_')
        if project_folder_name_parts[0] == "pacusc":
            project_folder_name_parts[0] = "pacuSc"
        for p in project_folder_name_parts:
            project_name += p[0].upper() + p[1:]
        return project_name    
    
    def get_files_by_suffixes(self, project_folder_path, parent_folder, folder, suffixes):
        if parent_folder is not None:            
            local_folder = parent_folder + '/' + folder
        else:
            local_folder = folder
        files_list = []
        for f in os.listdir(project_folder_path + '/' + local_folder):
            if os.path.isfile(project_folder_path + '/' + local_folder + '/' + f):
                if Path(project_folder_path + '/' + local_folder + '/' + f).suffix in suffixes:
                    files_list.append(local_folder + '/' + f)
            if os.path.isdir(project_folder_path + '/'+ local_folder + '/' + f):
                files_list += self.get_files_by_suffixes(project_folder_path, local_folder, f, suffixes)
        return files_list
    
    def get_destination_folder_destination_files_tupples(self, project_folder_path, project_folder_name, parent_folder, folder, suffixes):
        folder_files_tupple_dict_list = []
        if parent_folder is not None:            
            local_folder = parent_folder + '/' + folder
        else:
            local_folder = folder
        files_dict_list = []
        for f in os.listdir(project_folder_path + '/' + local_folder):
            if os.path.isfile(project_folder_path + '/' + local_folder + '/' + f):
                if Path(project_folder_path + '/' + local_folder + '/' + f).suffix in suffixes:
                    files_dict_list.append({"file":f, "source_file_path":local_folder + '/' + f})
            if os.path.isdir(project_folder_path + '/'+ local_folder + '/' + f) and local_folder != "tb/hdl/simstm_src_to_customize" :
                folder_files_tupple_dict_list += self.get_destination_folder_destination_files_tupples(project_folder_path, project_folder_name, local_folder, f, suffixes)
        if len(files_dict_list) > 0:
            folder_files_tupple_dict_list.append((project_folder_name + '/' + local_folder, files_dict_list))
        return folder_files_tupple_dict_list 
    
    
    def get_vhdl_destination_folder_destination_files_tupples(self, project_folder_path, project_folder_name, parent_folder, folder, suffixes):
        folder_files_tupple_dict_list = []
        if parent_folder is not None:            
            local_folder = parent_folder + '/' + folder
        else :
            local_folder = folder
        files_dict_list = []
        for f in os.listdir(project_folder_path + '/' + local_folder):
            if os.path.isfile(project_folder_path + '/' + local_folder + '/' + f):
                if Path(project_folder_path + '/' + local_folder + '/' + f).suffix in suffixes:
                    files_dict_list.append({"file":f, "source_file_path":local_folder + '/' + f, "file_type":"VHDL 2008"})
            if os.path.isdir(project_folder_path + '/'+ local_folder + '/' + f):
                folder_files_tupple_dict_list += self.get_vhdl_destination_folder_destination_files_tupples(project_folder_path, project_folder_name, local_folder, f, suffixes)
        if len(files_dict_list) > 0:
            folder_files_tupple_dict_list.append((project_folder_name + '/' + local_folder, files_dict_list))
        return folder_files_tupple_dict_list          
  
    
    def get_other_destination_files(self, project_folder_path, parent_folder, folder, suffixes, top_entity):
        if parent_folder is not None:            
            local_folder = parent_folder + '/' + folder
        else :
            local_folder = folder
        files_dict_list = []
        if local_folder == "package/xgui":
            xgui_tcl_file_dummy_name =  top_entity + "_v1_0" + ".tcl"
            files_dict_list.append({"file":xgui_tcl_file_dummy_name, "source_file_path":"package/xgui" + '/' + xgui_tcl_file_dummy_name})               
        else:    
            for f in os.listdir(project_folder_path + '/' + local_folder):          
                    if os.path.isfile(project_folder_path + '/' + local_folder + '/' + f):
                        if Path(project_folder_path + '/' + local_folder + '/' + f).suffix in suffixes:
                            files_dict_list.append({"file":f, "source_file_path":local_folder + '/' + f})
        return files_dict_list       
     
                
@click.command()
@click.option('--indir_project', default='..',  help='usually project folder above helper folder')
@click.option('--infile_setup_template_py', default='templates/setup_template.py',  help='template file for setup.py generation')
@click.option('--outfile_setup_proposal', default='../setup.py',  help='proposal file path')
def generate(indir_project, infile_setup_template_py, outfile_setup_proposal):
    obj = GenerateProposalForSetupPy()
    obj. generate(indir_project=indir_project, 
                  infile_setup_template_py = infile_setup_template_py,
                  outfile_setup_proposal=outfile_setup_proposal
                  )

if __name__ == '__main__':
    generate()