from jinja2 import Environment, FileSystemLoader
from json import loads
from pathlib import Path


class SetupToJson:
    
    def extract(self, file_path='test/setup.py', write_json_file=False):
        file = open(file_path, 'r')
        lines = file.readlines()
        static_setup_data_lines_with_comments = []
        static_setup_data_lines = []
        in_static_setup_data_lines = False
        for l in lines: 
            if in_static_setup_data_lines : 
                static_setup_data_lines_with_comments.append(l)           
            if l.startswith("# start static_setup_data section"):
                in_static_setup_data_lines = True       
            if l.startswith("# end static_setup_data section"):
                in_static_setup_data_lines = False
        file.close()
        
        for l in static_setup_data_lines_with_comments: 
            if not l.strip().startswith('#'):
                l = l.replace('(', '[')
                l = l.replace(')', ']')
                static_setup_data_lines.append(l)
                
        static_setup_data_lines[0] = static_setup_data_lines[0].replace("static_setup_data = {", "{")
        
        s = ""
        for l in static_setup_data_lines: 
            s += l
        
        if write_json_file:
            f = open('static_setup_data.json', 'w')
            f.write(s)
            f.close()
        
        return s
    
if __name__ == '__main__':
    obj = SetupToJson()
    obj. extract(file_path='../../../setup.py', write_json_file=True)