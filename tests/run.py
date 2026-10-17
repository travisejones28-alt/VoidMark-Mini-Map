"""Run minimap smoke regressions under Lua 5.1, including addon conflicts."""
from pathlib import Path
import os
from lupa.lua51 import LuaRuntime

root = Path(__file__).resolve().parents[1]
os.chdir(root)
for setup in ('', 'VMM_TEST_CONFLICT=true; LeaPlusLC={MinimapModder="On"}',
              'VMM_TEST_CONFLICT=true; MoveAny={IsEnabled=function() return true end}'):
    runtime = LuaRuntime()
    if setup:
        runtime.execute(setup)
    runtime.execute("dofile('tests/smoke.lua')")
