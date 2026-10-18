"""Run minimap smoke regressions under Lua 5.1, including addon conflicts."""
from pathlib import Path
import os
from lupa.lua51 import LuaRuntime

root = Path(__file__).resolve().parents[1]
os.chdir(root)
runtime = LuaRuntime()
compile_lua = runtime.eval('function(s,n) local f,e=loadstring(s,n); assert(f,e) end')
for source in root.glob('*.lua'):
    compile_lua(source.read_text(encoding='utf-8'), source.name)
toc = (root/'VoidMarkMiniMap.toc').read_text(encoding='utf-8')
assert '## Interface: 16001' in toc
assert toc.index('Footer.lua') < toc.index('Repair.lua') < toc.index('VoidMarkMiniMap.lua')
runtime.execute("dofile('Footer.lua'); dofile('tests/footer.lua')")
runtime = LuaRuntime()
runtime.execute("dofile('Repair.lua'); dofile('tests/repair.lua')")
for setup in ('', 'VMM_TEST_ATLAS=true', 'VMM_TEST_SAVED_SETTINGS=true', 'VMM_TEST_OLD_FPS_OFF=true', 'VMM_TEST_CONFLICT=true; LeaPlusLC={MinimapModder="On"}',
              'VMM_TEST_CONFLICT=true; MoveAny={IsEnabled=function() return true end}'):
    runtime = LuaRuntime()
    if setup:
        runtime.execute(setup)
    runtime.execute("dofile('tests/smoke.lua')")
