"""Run extracted production functions with deterministic Roblox/network mocks.

Usage: python tests/test-rift.py --luau-dir /path/to/official/luau/binaries
Windows artwork tests: powershell -ExecutionPolicy Bypass -File tests/test-artwork.ps1
These tests do not connect to a game or load the full client.
"""
import argparse
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def between(source, start, end):
    a = source.index(start)
    b = source.index(end, a + len(start))
    return source[a:b]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--luau-dir', type=Path, required=True)
    args = parser.parse_args()
    source = (ROOT / 'alua').read_text(encoding='utf-8')
    inner = between(source, 'local source = [========[', ']========]')
    inner = inner[len('local source = [========['):]
    chunks = [
        between(inner, 'function Persistence.SavedHUDPositions()', '\ndo\n    local lastSavedJSON'),
        between(inner, 'do\n    BedWars.NotifyGui', '\ndo\n    BedWars.SpotifyPanel'),
        between(inner, 'BedWars.VoidWater = {}', '\nlocal sprintController'),
        between(inner, 'function BedWars.AttackRange()', '\nfunction BedWars.MeleeItem'),
        between(inner, 'function BedWars.HostileNpc(', '\nfunction BedWars.Visible('),
        between(inner, 'local swordHitRemote,', '\nlocal bedWarsProjectileApi'),
        between(inner, 'local function bedWarsReleaseScaffoldItem()', '\nlocal pickupAttempts'),
        between(inner, 'local function bedWarsShopCatalog()', '\nlocal function bedWarsAutoBuyStep'),
    ]
    water = between(inner, 'track(RunService.Heartbeat:Connect(function()\n    if not BedWars.Running or Settings.SelectedGame ~= "BedWars" then return end\n    if not BedWars.AntiVoidOn', '\ntask.spawn(function()')
    water = water.removeprefix('track(RunService.Heartbeat:Connect(function()').removesuffix('\nend))')
    chunks.append('local function waterStep()' + water + '\nend\n')
    spider = between(inner, 'track(RunService.PreSimulation:Connect(function()',
                     '\ntrack(RunService.Heartbeat:Connect(function()\n    if (not BedWars.SpeedOn')
    spider = spider.removeprefix('track(RunService.PreSimulation:Connect(function()').removesuffix('\nend))')
    chunks.append('local function spiderStep()' + spider + '\nend\n')
    harness = (ROOT / 'tests' / 'rift-spec.luau').read_text(encoding='utf-8')
    harness = harness.replace('-- INSERT_PRODUCTION_FUNCTIONS', '\n'.join(chunks))
    suffix = '.exe' if (args.luau_dir / 'luau.exe').exists() else ''
    compiler = args.luau_dir / ('luau-compile' + suffix)
    runtime = args.luau_dir / ('luau' + suffix)
    with tempfile.TemporaryDirectory(prefix='rift-tests-') as temp:
        temp = Path(temp)
        inner_path = temp / 'inner.luau'
        inner_path.write_text(inner, encoding='utf-8')
        spec_path = temp / 'spec.luau'
        spec_path.write_text(harness, encoding='utf-8')
        for path in [ROOT / 'alua', inner_path]:
            subprocess.run([str(compiler), '--null', str(path)], check=True)
        subprocess.run([str(runtime), str(spec_path)], check=True)
        rivals_chunks = [
            between(inner, 'local savedCamType, savedCamMode, camOffset',
                    '\ntrack(Window:GetPropertyChangedSignal("Visible")'),
            between(inner, 'function BedWars.BuildUI(boardGame)',
                    '\nif game.PlaceId == 6872265039'),
            between(inner, 'function RivalsAim.Setup()',
                    '\nif game.PlaceId == 17625359962'),
        ]
        rivals_spec = (ROOT / 'tests' / 'rivals-spec.luau').read_text(encoding='utf-8')
        rivals_spec = rivals_spec.replace('-- INSERT_RIVALS_PRODUCTION', '\n'.join(rivals_chunks))
        rivals_path = temp / 'rivals-spec.luau'
        rivals_path.write_text(rivals_spec, encoding='utf-8')
        subprocess.run([str(runtime), str(rivals_path)], check=True)
        reinject_spec = (ROOT / 'tests' / 'reinject-spec.luau').read_text(encoding='utf-8')
        reinject_spec = reinject_spec.replace('-- INSERT_PERSISTENCE_PRODUCTION',
            between(inner, 'do\n    local lastSavedJSON', '\nlocal function configKey'))
        reinject_spec = reinject_spec.replace('-- INSERT_QUEUE_PRODUCTION',
            between(inner, 'if detectedGame then\n    local queueTeleport', '\ndo\n    if detectedGame then'))
        reinject_path = temp / 'reinject-spec.luau'
        reinject_path.write_text(reinject_spec, encoding='utf-8')
        subprocess.run([str(runtime), str(reinject_path)], check=True)
        startup = between(inner, 'if detectedGame then\n    Persistence.Restore',
                          '\nENV.SunsetLoading.Status.Text')
        assert 'AutoReinject.Toggle.Set(false)' not in startup
    # Notifications must not move or hide the module list on narrow screens.
    listing = between(inner, '    local moduleList = new(', '\n    local dragHandle')
    assert 'notificationsVisible' not in listing and 'ModuleListShifted' not in listing
    assert 'moduleList.Position = UDim2.new(1, -14, 0, 38)' in listing
    print('PASS module list: fixed right anchor independent of notifications')


if __name__ == '__main__':
    main()
