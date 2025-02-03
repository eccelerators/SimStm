from io import StringIO
from json import loads
import os
from pathlib import Path
import shutil
from xml.dom import minidom
import xml.etree.cElementTree as ET

import click
from setup_data_to_json import SetupToJson


class GenAntBuildXml:
    def generate(self, setup_py_file_path='test/setup.py', simulation_subdir_path='test/modelsim/build_modelsim.xml'):
        target_prefix = 'modelsim-'
        time_stamps_prefix = 'simulation/' + 'modelsim' + "/work/TimeStamps/"
        simulation_dir_prefix = 'simulation/' + 'modelsim' + '/'

        # --------------------------
        # extract data from setup.py
        # --------------------------
        extractor = SetupToJson()
        file_path = open(setup_py_file_path, 'r')
        print("reading {}".format(setup_py_file_path))
        json_string = extractor.extract(setup_py_file_path)
        static_setup_data = loads(json_string)

        src_data_file_list = []
        for src_data_file_per_dest in static_setup_data["src_data_files"]:
            for src_data_file in src_data_file_per_dest[1]:
                src_data_file_list.append(src_data_file)

        tb_data_file_list = []
        for tb_data_file_per_dest in static_setup_data["tb_data_files"]:
            for tb_data_file in tb_data_file_per_dest[1]:
                tb_data_file_list.append(tb_data_file)

        context = {
            "name": static_setup_data["project_name"],
            "top_entity": static_setup_data["top_entity"],
            "top_entity_file": static_setup_data["top_entity_file"],
            "src_data_file_list": src_data_file_list,
            "tb_top_entity": static_setup_data["tb_top_entity"],
            "tb_top_entity_file": static_setup_data["tb_top_entity_file"],
            "tb_data_file_list": tb_data_file_list,
        }

        test_suite_data_dict = {}
        if "test_suites" in static_setup_data:
            for test_suite in static_setup_data["test_suites"]:
                if "testsuite-indexes" in test_suite:
                    for i in range(int(test_suite["testsuite-indexes"])):
                        test_suite_data_dict["{}_{:d}".format(test_suite["testsuite-name"],
                                                              i)] = {"file": test_suite["file"],
                                                                     "entry-file": test_suite["entry-file"],
                                                                     "entry-label": test_suite["entry-label"],
                                                                     "index": str(i)}
                else:
                    test_suite_data_dict[test_suite["testsuite-name"]] = {"file": test_suite["file"],
                                                                          "entry-file": test_suite["entry-file"],
                                                                          "entry-label": test_suite["entry-label"]}

        test_lab_data_dict = {}
        if "test_labs" in static_setup_data:
            for test_lab in static_setup_data["test_labs"]:
                test_lab_data_dict[test_lab["testlab-name"]] = {"file": test_lab["file"],
                                                                "entry-file": test_lab["entry-file"],
                                                                "entry-label": test_lab["entry-label"]}

        simulation_hdl_file_list = src_data_file_list + tb_data_file_list

        ordered_hdl_file_dict = {}

        for shf in simulation_hdl_file_list:
            if 'IP-XACT' not in shf['file_type']:
                ordered_hdl_file_dict[shf['hdl_order']] = shf

        ordered_hdl_file_dict = dict(sorted(ordered_hdl_file_dict.items()))

        root = ET.Element("project", name='modelsim')

        ET.SubElement(root, "property", name="vlib-executable", value="vlib")
        ET.SubElement(root, "property", name="vmap-executable", value="vmap")
        ET.SubElement(root, "property", name="vcom-executable", value="vcom")
        ET.SubElement(root, "property", name="vsim-executable", value="vsim")

        t = ET.SubElement(root, "target", name=target_prefix + "prepare", description="make work folder")
        ET.SubElement(t, "mkdir", dir=simulation_dir_prefix + "work")
        ex = ET.SubElement(
            t,
            "exec",
            executable="${vlib-executable}",
            dir=simulation_dir_prefix +
            "work",
            failonerror="true")
        ET.SubElement(ex, "arg", value="${basedir}/" + simulation_dir_prefix + "work" + "/work")
        ex = ET.SubElement(
            t,
            "exec",
            executable="${vmap-executable}",
            dir=simulation_dir_prefix +
            "work",
            failonerror="true")
        ET.SubElement(ex, "arg", value="work")
        ET.SubElement(ex, "arg", value="${basedir}/" + simulation_dir_prefix + "work" + "/work")
        ex = ET.SubElement(
            t,
            "exec",
            executable="${vmap-executable}",
            dir=simulation_dir_prefix +
            "work",
            failonerror="true")
        ET.SubElement(ex, "arg", value="work_lib")
        ET.SubElement(ex, "arg", value="${basedir}/" + simulation_dir_prefix + "work" + "/work")

        t = ET.SubElement(root, "target", name=target_prefix + "clean", description="delete work folder")
        dl = ET.SubElement(t, "delete", dir=simulation_dir_prefix + "work")
        dl = ET.SubElement(t, "delete", dir=simulation_dir_prefix + "TimeStamps")

        ET.SubElement(
            root,
            "target",
            name=target_prefix +
            "all",
            description="all from scratch until interactive simulation",
            depends=" modelsim-clean, modelsim-prepare, modelsim-compile, modelsim-simulate-suites, modelsim-exit-on-junit-errors-or-failures")

        ET.SubElement(
            root, "target",
            name=target_prefix + "all-gui", description="all from scratch until interactive simulation",
            depends=" modelsim-clean, modelsim-prepare, modelsim-compile, modelsim-simulate-gui")

        s = ' '
        for kohf, shf in ordered_hdl_file_dict.items():
            s += '-do_compile_' + target_prefix + shf['file'].replace('/', '_') + ', '
        s = s[:-2]
        ET.SubElement(root, "target", name=target_prefix + "compile", depends=s, description="compile all")

        t = ET.SubElement(root, "target", name=target_prefix + "simulate", description="simulate")
        ET.SubElement(t, "delete", dir=simulation_dir_prefix + "../SimulationResults")
        ET.SubElement(t, "mkdir", dir=simulation_dir_prefix + "../SimulationResults")
        echo = ET.SubElement(t, "echo", file=simulation_dir_prefix + "work/simulation.started", append="false")
        echo.text = "STARTED"
        echo = ET.SubElement(t, "echo", file=simulation_dir_prefix + "work/run_all.do", append="false")
        echo.text = "run -all"
        ex = ET.SubElement(t, "exec", executable="${vsim-executable}", dir=simulation_dir_prefix + "work")
        ET.SubElement(ex, "arg", value="-t")
        ET.SubElement(ex, "arg", value="ps")
        ET.SubElement(ex, "arg", value="-L")
        ET.SubElement(ex, "arg", value="work")
        ET.SubElement(ex, "arg", value="work." + context['tb_top_entity'])
        ET.SubElement(ex, "arg", value="-batch")
        ET.SubElement(ex, "arg", value="-gstimulus_path=${basedir}/tb/simstm/")
        ET.SubElement(ex, "arg", value="-do")
        ET.SubElement(ex, "arg", value="run_all.do")
        echo = ET.SubElement(t, "echo", file=simulation_dir_prefix + "work/simulation.ended", append="false")
        echo.text = "ENDED"

        t = ET.SubElement(root, "target", name=target_prefix + "simulate-gui", description="simulate start gui")
        ET.SubElement(t, "delete", dir=simulation_dir_prefix + "../SimulationResults")
        ET.SubElement(t, "mkdir", dir=simulation_dir_prefix + "../SimulationResults")
        ex = ET.SubElement(t, "exec", executable="${vsim-executable}", dir=simulation_dir_prefix + "work")
        ET.SubElement(ex, "arg", value="-t")
        ET.SubElement(ex, "arg", value="ps")
        ET.SubElement(ex, "arg", value="-voptargs=+acc")
        ET.SubElement(ex, "arg", value="-L")
        ET.SubElement(ex, "arg", value="work")
        ET.SubElement(ex, "arg", value="work." + context['tb_top_entity'])
        ET.SubElement(ex, "arg", value="-gstimulus_path=${basedir}/tb/simstm/")
        ET.SubElement(ex, "arg", value="-i")

        if "test_suites" in static_setup_data:
            t = ET.SubElement(root, "target", name=target_prefix +
                              "simulate-suites", description="simulate all suites parallel")
            ET.SubElement(t, "delete", dir=simulation_dir_prefix + "../SimulationResults")
            ET.SubElement(t, "mkdir", dir=simulation_dir_prefix + "../SimulationResults")
            echo = ET.SubElement(t, "echo", file=simulation_dir_prefix +
                                 "../SimulationResults/testSuitesSimulation.start", append="false")
            echo.text = "STARTED"
            echo = ET.SubElement(t, "echo", file=simulation_dir_prefix + "work/run_all.do", append="false")
            echo.text = "run -all"
            prl = ET.SubElement(t, "parallel", threadCount="8")

            for test_suite, test_suite_data in test_suite_data_dict.items():
                ex = ET.SubElement(prl, "exec", executable="${vsim-executable}", dir=simulation_dir_prefix + "work")
                ET.SubElement(ex, "redirector",
                              output=simulation_dir_prefix + "../SimulationResults/" + test_suite + ".out",
                              error=simulation_dir_prefix + "../SimulationResults/" + test_suite + ".err",
                              alwayslog="true")

                ET.SubElement(ex, "arg", value="-t")
                ET.SubElement(ex, "arg", value="ps")
                ET.SubElement(ex, "arg", value="-L")
                ET.SubElement(ex, "arg", value="work")
                ET.SubElement(ex, "arg", value="work." + context['tb_top_entity'])
                ET.SubElement(ex, "arg", value="-batch")
                ET.SubElement(ex, "arg", value="-gstimulus_path=${basedir}/tb/simstm/")
                ET.SubElement(ex, "arg", value="-gstimulus_file=" + test_suite_data["entry-file"])
                ET.SubElement(ex, "arg", value="-gstimulus_main_entry_label=" + test_suite_data["entry-label"])
                if "index" in test_suite_data:
                    ET.SubElement(ex, "arg", value="-gstimulus_test_suite_index=" + test_suite_data["index"])
                ET.SubElement(ex, "arg", value="-do")
                ET.SubElement(ex, "arg", value="run_all.do")
            echo = ET.SubElement(t, "echo", file=simulation_dir_prefix +
                                 "../SimulationResults/testSuitesSimulation.end", append="false")
            echo.text = "ENDED"

            ex = ET.SubElement(t, "exec", executable="${python-executable}")
            ET.SubElement(ex, "arg", value="helper/collect-simulation-results.py")
            ET.SubElement(ex, "arg", value="--infile")
            ET.SubElement(ex, "arg", value="setup.py")
            ET.SubElement(ex, "arg", value="--inoutdir_simulation_results_dir_path")
            ET.SubElement(ex, "arg", value="simulation/SimulationResults")

            ET.SubElement(
                t,
                "available",
                file="simulation/SimulationResults/testSuitesSimulation.xml",
                property="testSuitesSimulation.xml.present")
            ET.SubElement(t, "antcall", target=target_prefix + "do-remove-junit-artifacts")
            ET.SubElement(t, "antcall", target=target_prefix + "complain-about-junit-artifacts")

            t = ET.SubElement(root, "target", {"name": target_prefix +
                                               "do-remove-junit-artifacts", "if": "testSuitesSimulation.xml.present"})
            dl = ET.SubElement(t, "delete", failonerror="false", includeemptydirs="true")
            fs = ET.SubElement(dl, "fileset", dir="simulation/SimulationResults")
            ET.SubElement(fs, "include", name="**/*")
            ET.SubElement(fs, "exclude", name="**/testSuitesSimulation.xml")

            t = ET.SubElement(root,
                              "target",
                              {"name": target_prefix + "complain-about-junit-artifacts",
                               "unless": "testSuitesSimulation.xml.present"})
            ET.SubElement(
                t,
                "echo",
                message="testSuitesSimulation.xml couldn't be build from artifacts, keeping artifacts")

        if "test_labs" in static_setup_data:
            for test_lab, test_lab_data in test_lab_data_dict.items():
                t = ET.SubElement(
                    root,
                    "target",
                    name=target_prefix +
                    "simulate-" +
                    test_lab,
                    description="run simulation")
                ET.SubElement(t, "delete", dir=simulation_dir_prefix + "../SimulationResults")
                echo = ET.SubElement(t, "echo", file=simulation_dir_prefix + "work/simulation.started", append="false")
                echo.text = "STARTED"
                echo = ET.SubElement(t, "echo", file=simulation_dir_prefix + "work/run_all.do", append="false")
                echo.text = "run -all"
                ex = ET.SubElement(t, "exec", executable="${vsim-executable}", dir=simulation_dir_prefix + "work")
                ET.SubElement(ex, "arg", value="-t")
                ET.SubElement(ex, "arg", value="ps")
                ET.SubElement(ex, "arg", value="-L")
                ET.SubElement(ex, "arg", value="work")
                ET.SubElement(ex, "arg", value="work." + context['tb_top_entity'])
                ET.SubElement(ex, "arg", value="-batch")
                ET.SubElement(ex, "arg", value="-gstimulus_path=${basedir}/tb/simstm/")
                ET.SubElement(ex, "arg", value="-gstimulus_file=" + test_lab_data["entry-file"])
                ET.SubElement(ex, "arg", value="-gstimulus_main_entry_label=" + test_lab_data["entry-label"])
                ET.SubElement(ex, "arg", value="-do")
                ET.SubElement(ex, "arg", value="run_all.do")
                echo = ET.SubElement(t, "echo", file=simulation_dir_prefix + "work/simulation.ended", append="false")
                echo.text = "ENDED"

                t = ET.SubElement(root, "target", name=target_prefix + "simulate-gui-" +
                                  test_lab, description="simulate and write trace.vcd")
                ET.SubElement(t, "delete", dir=simulation_dir_prefix + "../SimulationResults")
                echo = ET.SubElement(t, "echo", file=simulation_dir_prefix + "work/simulation.started", append="false")
                echo.text = "STARTED"
                echo = ET.SubElement(t, "echo", file=simulation_dir_prefix + "work/run_all.do", append="false")
                echo.text = "run -all"
                ex = ET.SubElement(t, "exec", executable="${vsim-executable}", dir=simulation_dir_prefix + "work")
                ET.SubElement(ex, "arg", value="-t")
                ET.SubElement(ex, "arg", value="ps")
                ET.SubElement(ex, "arg", value="-L")
                ET.SubElement(ex, "arg", value="work")
                ET.SubElement(ex, "arg", value="work." + context['tb_top_entity'])
                ET.SubElement(ex, "arg", value="-gstimulus_path=${basedir}/tb/simstm/")
                ET.SubElement(ex, "arg", value="-gstimulus_file=" + test_lab_data["entry-file"])
                ET.SubElement(ex, "arg", value="-gstimulus_main_entry_label=" + test_lab_data["entry-label"])
                ET.SubElement(ex, "arg", value="-i")
                echo = ET.SubElement(t, "echo", file=simulation_dir_prefix + "work/simulation.ended", append="false")
                echo.text = "ENDED"

        t = ET.SubElement(root, "target", name=target_prefix + "init-skip-properties")
        ET.SubElement(t, "mkdir", dir=time_stamps_prefix[:-1])
        for kohf, shf in ordered_hdl_file_dict.items():
            ET.SubElement(
                t,
                "uptodate",
                srcfile="${basedir}/" +
                shf['file'],
                targetfile="${basedir}/" +
                time_stamps_prefix +
                shf['file'].replace(
                    '/',
                    '_'),
                property=target_prefix +
                shf['file'].replace(
                    '/',
                    '_') +
                '.skip',
                value="true")

        for kohf, shf in ordered_hdl_file_dict.items():
            do = '-do_compile_' + target_prefix + shf['file'].replace('/', '_')
            if shf['file_type'] == 'Verilog':
                t = ET.SubElement(
                    root,
                    "target",
                    name=do,
                    depends=target_prefix +
                    "init-skip-properties",
                    unless=target_prefix +
                    shf['file'].replace(
                        '/',
                        '_') +
                    '.skip')
                ex = ET.SubElement(
                    t,
                    "exec",
                    executable="${vcom-executable}",
                    dir=simulation_dir_prefix +
                    "work",
                    failonerror="true")
                ET.SubElement(ex, "arg", value="${basedir}/" + shf['file'])
            else:
                t = ET.SubElement(
                    root,
                    "target",
                    name=do,
                    depends=target_prefix +
                    "init-skip-properties",
                    unless=target_prefix +
                    shf['file'].replace(
                        '/',
                        '_') +
                    '.skip')
                ex = ET.SubElement(
                    t,
                    "exec",
                    executable="${vcom-executable}",
                    dir=simulation_dir_prefix +
                    "work",
                    failonerror="true")
                if '2008' in shf['file_type']:
                    ET.SubElement(ex, "arg", value="-O0")
                    ET.SubElement(ex, "arg", value="-2008")
                ET.SubElement(ex, "arg", value="${basedir}/" + shf['file'])
            ET.SubElement(t, "touch", file="${basedir}/" + time_stamps_prefix + shf['file'].replace('/', '_'))

        t = ET.SubElement(root, "target", name=target_prefix + "exit-on-junit-errors-or-failures")
        ET.SubElement(
            t,
            "xmlproperty",
            file="simulation/modelsim/../SimulationResults/testSuitesSimulation.xml",
            keepRoot="true")
        c = ET.SubElement(t, "condition", property="no-failures")
        ET.SubElement(c, "equals", arg1="${testsuites(failures)}", arg2="0")
        c = ET.SubElement(t, "condition", property="no-errors")
        ET.SubElement(c, "equals", arg1="${testsuites(errors)}", arg2="0")
        c = ET.SubElement(t, "condition", property="no-errors-or-failures")
        a = ET.SubElement(c, "and")
        ET.SubElement(a, "isset", property="no-failures")
        ET.SubElement(a, "isset", property="no-errors")
        f = ET.SubElement(t, "fail", unless="no-errors-or-failures", message="Testsuites report errors or failures")

        tree = ET.ElementTree(root)

        xml_str = minidom.parseString(ET.tostring(root)).toprettyxml(indent="   ")
        xml_file = StringIO(xml_str)
        xml_lines = xml_file.readlines()

        xml_lines_beautified = []
        for l in xml_lines:
            if target_prefix + "compile" in l or target_prefix + "all" in l:
                l = l.replace('depends="', 'depends="\n    ')
                l = l.replace(',', ',\n    ')
                l = l.replace(' description="', '\n         description="')
            if 'property name="vlib-executable"' in l:
                xml_lines_beautified.append('   <!-- may be overridden in main build script -->\n')
            if '<target' in l:
                xml_lines_beautified.append('\n')
            xml_lines_beautified.append(l)

        bf = simulation_subdir_path + '/build-' + target_prefix[:-1] + '.xml'
        if os.path.exists(bf):
            os.remove(bf)

        print("writing {}".format(bf))
        with open(bf, "w") as f:
            for l in xml_lines_beautified:
                f.write(l)


@click.command()
@click.option('--infile', default='../../../setup.py', help='setup_py_file_path')
@click.option('--outdir_simulation_subdir', default='../../../simulation/modelsim', help='simulation_subdir_path')
def generate(infile, outdir_simulation_subdir):
    obj = GenAntBuildXml()
    obj. generate(setup_py_file_path=infile,
                  simulation_subdir_path=outdir_simulation_subdir
                  )


if __name__ == '__main__':
    generate()
