"""Run extracted production functions with deterministic Roblox/network mocks.

Usage: python tests/test-rift.py --luau-dir /path/to/official/luau/binaries
Windows artwork tests: powershell -ExecutionPolicy Bypass -File tests/test-artwork.ps1
These tests do not connect to a game or load the full client.
"""
import argparse
import re
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
        loader_source = (ROOT / 'loader.lua').read_text(encoding='utf-8')
        build_line = re.search(r'local SUNSET_BUILD = "[^"]+"', inner).group(0)
        loader_spec = (ROOT / 'tests' / 'loader-spec.luau').read_text(encoding='utf-8')
        loader_spec = loader_spec.replace('-- INSERT_CURRENT_RELEASE',
            'local releaseSource = [====[' + build_line + ']====]')
        loader_spec = loader_spec.replace('-- INSERT_LOADER_PRODUCTION', loader_source)
        loader_path = temp / 'loader-spec.luau'
        loader_path.write_text(loader_spec, encoding='utf-8')
        subprocess.run([str(compiler), '--null', str(ROOT / 'loader.lua')], check=True)
        subprocess.run([str(runtime), str(loader_path)], check=True)
        print('PASS pinned loader: current release, stale/missing version rejection, download/compile failures, recovery')
        for path in [ROOT / 'alua', inner_path]:
            subprocess.run([str(compiler), '--null', str(path)], check=True)
            # Executor loadstring may keep every debug local in a register.
            # Default CLI debug mode prunes lifetimes and can hide the 200-register failure.
            for optimization in ('-O0', '-O1', '-O2'):
                subprocess.run([str(compiler), '--null', optimization, '-g2', str(path)], check=True)
        subprocess.run([str(runtime), str(spec_path)], check=True)
        slider_spec = (ROOT / 'tests' / 'slider-spec.luau').read_text(encoding='utf-8')
        slider_spec = slider_spec.replace('-- INSERT_SLIDER_PRODUCTION',
            between(inner, 'local function sliderNumber(', '\nfunction Elements.Dropdown'))
        slider_path = temp / 'slider-spec.luau'
        slider_path.write_text(slider_spec, encoding='utf-8')
        subprocess.run([str(runtime), str(slider_path)], check=True)
        startup_spec = (ROOT / 'tests' / 'startup-spec.luau').read_text(encoding='utf-8')
        startup_spec = startup_spec.replace('-- INSERT_STARTUP_PRODUCTION',
            between(inner, 'local function waitForRivalsStartup()', '\nif (game.PlaceId'))
        startup_path = temp / 'startup-spec.luau'
        startup_path.write_text(startup_spec, encoding='utf-8')
        subprocess.run([str(runtime), str(startup_path)], check=True)
        loading_spec = (ROOT / 'tests' / 'loading-spec.luau').read_text(encoding='utf-8')
        loading_spec = loading_spec.replace('-- INSERT_LOADING_PRODUCTION',
            between(inner, 'function Settings.CompleteStartup(', '\nlocal supportedGames'))
        loading_spec = loading_spec.replace('-- INSERT_HOOK_POLICY',
            between(inner, 'local canHook =', '\nlocal savedCamType'))
        loading_path = temp / 'loading-spec.luau'
        loading_path.write_text(loading_spec, encoding='utf-8')
        subprocess.run([str(runtime), str(loading_path)], check=True)
        handoff = inner[inner.index('ENV.SunsetLoading.Status.Text = detectedGame'):]
        assert 'Settings.CompleteStartup(ENV.SunsetLoading, detectedGame)' in handoff
        assert 'task.delay' not in handoff and 'task.wait' not in handoff
        coldwar_spec = (ROOT / 'tests' / 'coldwar-startup-spec.luau').read_text(encoding='utf-8')
        coldwar_spec = coldwar_spec.replace('-- INSERT_BEDWARS_RUNTIME',
            between(inner, 'function Settings.SetupBedWarsRuntime()', '\nif Settings.IsColdWar then\n    -- There are no BedWars'))
        coldwar_spec = coldwar_spec.replace('-- INSERT_GAME_RUNTIME_DISPATCH',
            between(inner, 'if Settings.IsColdWar then\n    -- There are no BedWars', '\nlocal Fun ='))
        coldwar_spec = coldwar_spec.replace('-- INSERT_TARGET_DISPATCH',
            between(inner, 'if not Settings.IsColdWar then\n    track(workspace.DescendantAdded', '\nlocal function modelPart'))
        coldwar_spec = coldwar_spec.replace('-- INSERT_ASSET_PRODUCTION',
            between(inner, 'local riftAssetCache =', '\nlocal function riftTrashFallback'))
        coldwar_path = temp / 'coldwar-startup-spec.luau'
        coldwar_path.write_text(coldwar_spec, encoding='utf-8')
        subprocess.run([str(runtime), str(coldwar_path)], check=True)
        ui_host_spec = (ROOT / 'tests' / 'ui-host-spec.luau').read_text(encoding='utf-8')
        ui_host_spec = ui_host_spec.replace('-- INSERT_UI_HOST_PRODUCTION',
            between(inner, 'function Settings.ParentColdWarUI(', '\nlocal function border'))
        ui_host_path = temp / 'ui-host-spec.luau'
        ui_host_path.write_text(ui_host_spec, encoding='utf-8')
        subprocess.run([str(runtime), str(ui_host_path)], check=True)
        aim_spec = (ROOT / 'tests' / 'coldwar-aim-spec.luau').read_text(encoding='utf-8')
        aim_spec = aim_spec.replace('-- INSERT_COLDWAR_AIM_PRODUCTION',
            between(inner, 'function Settings.SetupColdWarAim(', '\nfunction Settings.SetupPlayerESP('))
        aim_path = temp / 'coldwar-aim-spec.luau'
        aim_path.write_text(aim_spec, encoding='utf-8')
        subprocess.run([str(runtime), str(aim_path)], check=True)
        assert '{ Name = "Project Delta", Place = 7336302630, Universe = 2862098693 }' in inner
        assert '[7336302630] = true, [2862098693] = true' in inner
        delta_spec = (ROOT / 'tests' / 'project-delta-spec.luau').read_text(encoding='utf-8')
        delta_spec = delta_spec.replace('-- INSERT_PROJECT_DELTA_PRODUCTION',
            between(inner, 'function Settings.SetupProjectDelta()', '\nif game.PlaceId == 6872265039'))
        delta_path = temp / 'project-delta-spec.luau'
        delta_path.write_text(delta_spec, encoding='utf-8')
        subprocess.run([str(runtime), str(delta_path)], check=True)
        speed_spec = (ROOT / 'tests' / 'coldwar-speed-spec.luau').read_text(encoding='utf-8')
        speed_spec = speed_spec.replace('-- INSERT_COLDWAR_SPEED_PRODUCTION',
            between(inner, 'function Settings.SetupColdWarBulletSpeed(', '\nfunction Settings.SetupColdWarAutoWeapons('))
        speed_path = temp / 'coldwar-speed-spec.luau'
        speed_path.write_text(speed_spec, encoding='utf-8')
        subprocess.run([str(runtime), str(speed_path)], check=True)
        extras_spec = (ROOT / 'tests' / 'visual-extras-spec.luau').read_text(encoding='utf-8')
        extras_spec = extras_spec.replace('-- INSERT_VISUAL_EXTRAS',
            between(inner, 'function Settings.SetupColdWarVisualExtras()', '\nfunction Settings.SetupColdWarWeaponTuning('))
        extras_spec = extras_spec.replace('-- INSERT_VISIBILITY',
            between(inner, 'function Settings.SetupColdWarVisibility(', '\nfunction Settings.SetupColdWar()'))
        extras_path = temp / 'visual-extras-spec.luau'
        extras_path.write_text(extras_spec, encoding='utf-8')
        subprocess.run([str(runtime), str(extras_path)], check=True)
        tuning_spec = (ROOT / 'tests' / 'weapon-tuning-spec.luau').read_text(encoding='utf-8')
        tuning_spec = tuning_spec.replace('-- INSERT_WEAPON_TUNING',
            between(inner, 'function Settings.SetupColdWarWeaponTuning(', '\nfunction Settings.SetupColdWarAutoWeapons('))
        tuning_path = temp / 'weapon-tuning-spec.luau'
        tuning_path.write_text(tuning_spec, encoding='utf-8')
        subprocess.run([str(runtime), str(tuning_path)], check=True)
        auto_spec = (ROOT / 'tests' / 'auto-weapons-spec.luau').read_text(encoding='utf-8')
        auto_spec = auto_spec.replace('-- INSERT_AUTO_WEAPONS',
            between(inner, 'function Settings.SetupColdWarAutoWeapons(', '\nfunction Settings.SetupColdWar()'))
        auto_path = temp / 'auto-weapons-spec.luau'
        auto_path.write_text(auto_spec, encoding='utf-8')
        subprocess.run([str(runtime), str(auto_path)], check=True)
        rivals_chunks = [
            between(inner, 'function Settings.StartupStage(', '\nSettings.StartupStage("Loading menu controls...")'),
            between(inner, '    function BedWars.MusicOverlayVisible()', '\n    Persistence.HUDFrames.MusicOverlay'),
            between(inner, 'local function buildSpinbot(', '\nspinToggle = buildSpinbot('),
            between(inner, 'local function refreshBedWarsPlayers()', '\nlocal function refreshBedWarsMap()'),
            between(inner, 'local Binds = {}', '\nfunction Elements.ColorPicker'),
            between(inner, 'local function projectBounds(', '\nlocal ESP = {}'),
            between(inner, 'local savedCamType, savedCamMode, camOffset',
                    '\ntrack(Window:GetPropertyChangedSignal("Visible")'),
            between(inner, 'function BedWars.BuildUI(boardGame)',
                    '\nlocal function rivalsModuleLoaded('),
            between(inner, 'local function rivalsModuleLoaded(',
                    '\nfunction Settings.SetupColdWarAim('),
            between(inner, 'function Settings.SetupColdWarAim(',
                    '\nif game.PlaceId == 6872265039'),
        ]
        rivals_spec = (ROOT / 'tests' / 'rivals-spec.luau').read_text(encoding='utf-8')
        rivals_spec = rivals_spec.replace('-- INSERT_RIVALS_PRODUCTION', '\n'.join(rivals_chunks))
        rivals_path = temp / 'rivals-spec.luau'
        rivals_path.write_text(rivals_spec, encoding='utf-8')
        subprocess.run([str(runtime), str(rivals_path)], check=True)
        reinject_spec = (ROOT / 'tests' / 'reinject-spec.luau').read_text(encoding='utf-8')
        reinject_spec = reinject_spec.replace('-- INSERT_PERSISTENCE_PRODUCTION',
            between(inner, 'function Persistence.ControlApplies(', '\nlocal function configKey'))
        reinject_spec = reinject_spec.replace('-- INSERT_QUEUE_PRODUCTION',
            between(inner, 'if detectedGame then\n    local queueTeleport', '\ndo\n    if detectedGame then'))
        reinject_spec = reinject_spec.replace('-- INSERT_CANCEL_PRODUCTION',
            between(inner, 'function AutoReinject.Cancel()', '\nlocal RefreshConfigList'))
        reinject_path = temp / 'reinject-spec.luau'
        reinject_path.write_text(reinject_spec, encoding='utf-8')
        subprocess.run([str(runtime), str(reinject_path)], check=True)
        fly_spec = (ROOT / 'tests' / 'fly-spec.luau').read_text(encoding='utf-8')
        fly_spec = fly_spec.replace('-- INSERT_FLY_PRODUCTION',
            between(inner, 'local Fly = {}', '\nlocal MapFloorY'))
        fly_path = temp / 'fly-spec.luau'
        fly_path.write_text(fly_spec, encoding='utf-8')
        subprocess.run([str(runtime), str(fly_path)], check=True)
        startup = between(inner, '    Persistence.Restore(detectedGame, menuKeyControl)',
                          '\nENV.SunsetLoading.Status.Text')
        assert 'AutoReinject.Toggle.Set(false)' not in startup
        unload = between(inner, 'ENV.SunsetUnload = function()', '\nprint(BRAND')
        assert 'AutoReinject.Cancel()' in unload
    # Notifications must not move or hide the module list on narrow screens.
    listing = between(inner, '    local moduleList = new(', '\n    local dragHandle')
    assert 'notificationsVisible' not in listing and 'ModuleListShifted' not in listing
    assert 'moduleList.Position = UDim2.new(1, -14, 0, 38)' in listing
    print('PASS module list: fixed right anchor independent of notifications')


if __name__ == '__main__':
    main()
