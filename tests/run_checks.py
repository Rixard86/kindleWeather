import json
import os
import pathlib
import re
import sys

import lupa.luajit21 as luajit

ROOT_DIR = pathlib.Path(__file__).resolve().parent.parent
PLUGIN_DIR = ROOT_DIR / "weatherscreen.koplugin"
TESTS_DIR = ROOT_DIR / "tests"
SPECS_DIR = TESTS_DIR / "specs"
FIXTURES_DIR = TESTS_DIR / "fixtures"
FIXTURE_FILES = {
    "forecast": "forecast_vanersborg.json",
    "geocode": "geocode_vanersborg.json",
    "news": "news_vanersborg.xml",
    "smhi": "smhi_vanersborg.json",
}
LUACHECK_SOURCE_VARIABLE = "LUACHECK_SRC"
LUACHECK_OPTIONS = {"std": "luajit", "max_line_length": 120, "self": False}
MAX_FILE_LINES = 250
MAX_FUNCTION_LINES = 50
MAX_PARAMETERS = 2
FUNCTION_SIGNATURE = re.compile(r"\bfunction\b\s*[\w.:]*\s*\(([^)]*)\)")
STRING_LITERAL = re.compile(r'"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'')
LFS_STUB = """
package.preload["lfs"] = function()
    return {
        _VERSION = "stub",
        attributes = function() return nil end,
        currentdir = function() return "." end,
        dir = function() return function() return nil end end,
    }
end
"""


def lua_path_entry(directory):
    return directory.as_posix() + "/?.lua;" + directory.as_posix() + "/?/init.lua;"


def new_runtime(directories):
    runtime = luajit.LuaRuntime(unpack_returned_tuples=True)
    search_path = "".join(lua_path_entry(directory) for directory in directories)
    runtime.globals().package.path = search_path + runtime.globals().package.path
    return runtime


def load_fixtures(runtime):
    fixtures = {}
    for name, file_name in FIXTURE_FILES.items():
        with open(FIXTURES_DIR / file_name, encoding="utf-8") as fixture:
            fixtures[name] = json.load(fixture) if file_name.endswith(".json") else fixture.read()
    return runtime.table_from(fixtures, recursive=True)


def run_spec_file(spec_path):
    runtime = new_runtime([PLUGIN_DIR, TESTS_DIR, SPECS_DIR])
    runtime.globals().FIXTURES = load_fixtures(runtime)
    spec = runtime.globals().require(spec_path.stem)
    failures = []
    for name in sorted(spec.keys()):
        outcome = runtime.globals().pcall(spec[name])
        succeeded, error = outcome if isinstance(outcome, tuple) else (outcome, None)
        status = "ok  " if succeeded else "FAIL"
        print(f"  {status} {spec_path.stem}: {name}")
        if not succeeded:
            failures.append(f"{spec_path.stem}: {name}: {error}")
    return failures


def run_specs():
    print("Specs")
    failures = []
    for spec_path in sorted(SPECS_DIR.glob("*_spec.lua")):
        failures.extend(run_spec_file(spec_path))
    return failures


def plugin_sources():
    return sorted(PLUGIN_DIR.glob("*.lua"))


def run_luacheck():
    print("Luacheck")
    source_dir = os.environ.get(LUACHECK_SOURCE_VARIABLE)
    if not source_dir:
        return [f"set {LUACHECK_SOURCE_VARIABLE} to the luacheck src directory"]
    runtime = new_runtime([pathlib.Path(source_dir)])
    runtime.execute(LFS_STUB)
    luacheck = runtime.globals().require("luacheck")
    paths = plugin_sources()
    sources = runtime.table_from([path.read_text(encoding="utf-8") for path in paths])
    report = luacheck.check_strings(sources, runtime.table_from(LUACHECK_OPTIONS))
    return collect_luacheck_warnings(luacheck, report, paths)


def collect_luacheck_warnings(luacheck, report, paths):
    warnings = []
    for index, path in enumerate(paths, start=1):
        for issue in report[index].values():
            warnings.append(f"{path.name}:{issue.line}:{issue.column}: {luacheck.get_message(issue)}")
    print(f"  {len(paths)} files, {len(warnings)} warnings")
    return warnings


def without_strings(line):
    return STRING_LITERAL.sub('""', line)


def indentation(line):
    return len(line) - len(line.lstrip())


def function_length(lines, start):
    start_indent = indentation(lines[start])
    for index in range(start + 1, len(lines)):
        stripped = lines[index].strip()
        if stripped.startswith("end") and indentation(lines[index]) == start_indent:
            return index - start + 1
    return len(lines) - start


def parameter_count(parameters):
    return len([name for name in parameters.split(",") if name.strip()])


def check_line(path, lines, index):
    problems = []
    code = without_strings(lines[index])
    location = f"{path.name}:{index + 1}"
    if "--" in code:
        problems.append(f"{location}: comment found")
    match = FUNCTION_SIGNATURE.search(code)
    if match and parameter_count(match.group(1)) > MAX_PARAMETERS:
        problems.append(f"{location}: more than {MAX_PARAMETERS} parameters")
    if match and not re.search(r"\bend\b", code[match.end():]):
        length = function_length(lines, index)
        if length > MAX_FUNCTION_LINES:
            problems.append(f"{location}: function is {length} lines")
    return problems


def check_style_rules():
    print("Style rules")
    problems = []
    for path in plugin_sources():
        lines = path.read_text(encoding="utf-8").splitlines()
        if len(lines) >= MAX_FILE_LINES:
            problems.append(f"{path.name}: {len(lines)} lines")
        for index in range(len(lines)):
            problems.extend(check_line(path, lines, index))
    print(f"  {len(problems)} problems")
    return problems


def main():
    problems = run_specs() + run_luacheck() + check_style_rules()
    for problem in problems:
        print("PROBLEM", problem)
    print("All checks passed" if not problems else f"{len(problems)} problems")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
