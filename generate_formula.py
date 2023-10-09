from cookiecutter.main import cookiecutter
from os.path import join, abspath
from os import pardir, getcwd
import sys

if not len(sys.argv) >= 3: 
    exit(-1)

version = sys.argv[1]
sha = sys.argv[2]


template_dir = "https://github.com/PythonSwiftLink/BrewFormulaCookie.git"

context = {
    "version": version,
    "name_version": version.replace(".",""),
    "sha": sha
}

cookiecutter(template_dir, no_input=True, extra_context=context)