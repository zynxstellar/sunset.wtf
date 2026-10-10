"""Run extracted production functions with deterministic Roblox/network mocks.

Usage: python tests/test-rift.py --luau-dir /path/to/official/luau/binaries
Windows artwork tests: powershell -ExecutionPolicy Bypass -File tests/test-artwork.ps1
These tests do not connect to a game or load the full client.
"""
import argparse
import re
import runpy
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
UNIVERSAL = ROOT / 'archive' / 'universal-retired.lua'


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
    assert 'new("UIGradient"' not in inner, 'Flat UI still creates gradients'
    for corrupt in ('Â', 'â€', 'Ã—', 'â™', 'â–'):
        assert corrupt not in inner, 'UI text still contains encoding corruption'
    board_ui = between(inner, 'function BedWars.BuildUI(boardGame)', '\nlocal function rivalsModuleLoaded(')
    assert 'rift-logo-transparent.png' not in board_ui and 'trash.png' not in board_ui
    assert 'riftTrashFallback(' not in board_ui, 'Removed trash icon is still rendered'
    assert 'Dev Tools' not in inner and 'SunsetExplorer' not in inner and 'WaterSpeedOn' not in inner
    assert 'searchRing' not in board_ui and 'search.png' not in board_ui
    startup_guard = inner.split('local ENV =', 1)[0]
    assert 'game.PlaceId ~= 7336302630 and game.GameId ~= 2862098693' in startup_guard, \
        'Project Delta is supported but the startup guard returns before building its UI'
    chunks = [
        between(inner, 'function Persistence.SavedHUDPositions()', '\ndo\n    local lastSavedJSON'),
        between(inner, 'function Settings.SetupNotifications()', '\nSettings.SetupNotifications()') + '\nSettings.SetupNotifications()\n',
        between(inner, 'do\n    function BedWars.Notify', '\ndo\n    BedWars.SpotifyPanel'),
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
        for name, marker, production in [
            ('menu-drag', '-- INSERT_MENU_DRAG', between(inner, 'function Settings.MakeMenuDraggable(', '\nlocal function makeTab(')),
            ('coldwar-spider', '-- INSERT_COLDWAR_SPIDER', between(inner, 'function Settings.SetupColdWarSpider()', '\nfunction Settings.SetupColdWarSession()')),
            ('coldwar-gravity', '-- INSERT_COLDWAR_GRAVITY', between(inner, 'function Settings.SetupColdWarGravity()', '\nfunction Settings.SetupColdWarSpider()')),
            ('coldwar-jump', '-- INSERT_COLDWAR_JUMP', between(inner, 'function Settings.SetupColdWarJump()', '\nfunction Settings.SetupColdWarSession()')),
        ]:
            spec = (ROOT / 'tests' / (name + '-spec.luau')).read_text(encoding='utf-8')
            spec_path = temp / (name + '-spec.luau')
            spec_path.write_text(spec.replace(marker, production), encoding='utf-8')
            subprocess.run([str(runtime), str(spec_path)], check=True)
        menu_test_source = (ROOT / 'menu-test-loader.lua').read_text(encoding='utf-8')
        assert menu_test_source == runpy.run_path(str(ROOT / 'tools' / 'build-menu-test.py'))['build']()
        menu_test_inner = menu_test_source.split('local source = [========[', 1)[1].split(']========]', 1)[0]
        assert 'IsColdWar     = false' in menu_test_inner
        assert 'Settings.SetupColdWar()' not in menu_test_inner
        assert 'Settings.SetupBedWarsRuntime()' not in menu_test_inner
        menu_test_inner_path = temp / 'menu-test-inner.luau'
        menu_test_inner_path.write_text(menu_test_inner, encoding='utf-8')
        for menu_path in [ROOT / 'menu-test-loader.lua', menu_test_inner_path]:
            subprocess.run([str(compiler), '--null', '-O0', '-g2', str(menu_path)], check=True)
        print('PASS menu test: reproducible real UI toolkit, gameplay initialization excluded, wrapper and UI compile')
        diagnostic_source = (ROOT / 'diagnostic-loader.lua').read_text(encoding='utf-8')
        diagnostic_spec = (ROOT / 'tests' / 'diagnostic-spec.luau').read_text(encoding='utf-8')
        diagnostic_spec = diagnostic_spec.replace('-- INSERT_DIAGNOSTIC', diagnostic_source)
        diagnostic_path = temp / 'diagnostic-spec.luau'
        diagnostic_path.write_text(diagnostic_spec, encoding='utf-8')
        subprocess.run([str(compiler), '--null', str(ROOT / 'diagnostic-loader.lua')], check=True)
        subprocess.run([str(runtime), str(diagnostic_path)], check=True)
        inner_path = temp / 'inner.luau'
        inner_path.write_text(inner, encoding='utf-8')
        spec_path = temp / 'spec.luau'
        spec_path.write_text(harness, encoding='utf-8')
        loader_source = (ROOT / 'loader.lua').read_text(encoding='utf-8')
        build_line = re.search(r'local SUNSET_BUILD = "[^"]+"', inner).group(0)
        loader_spec = (ROOT / 'tests' / 'loader-spec.luau').read_text(encoding='utf-8')
        loader_spec = loader_spec.replace('-- INSERT_CURRENT_RELEASE',
            'local releaseSource = [====[' + build_line + ']====]')
        universal_build_line = re.search(r'local SUNSET_BUILD = "[^"]+"',
            UNIVERSAL.read_text(encoding='utf-8')).group(0)
        loader_spec = loader_spec.replace('-- INSERT_UNIVERSAL_RELEASE',
            'local universalReleaseSource = [====[' + universal_build_line + ']====]')
        loader_spec = loader_spec.replace('-- INSERT_LOADER_PRODUCTION', loader_source)
        loader_path = temp / 'loader-spec.luau'
        loader_path.write_text(loader_spec, encoding='utf-8')
        subprocess.run([str(compiler), '--null', str(ROOT / 'loader.lua')], check=True)
        subprocess.run([str(runtime), str(loader_path)], check=True)
        print('PASS pinned loader: current release, stale/missing version rejection, download/compile failures, recovery')
        universal_source = UNIVERSAL.read_text(encoding='utf-8')
        universal_inner = between(universal_source, 'local source = [========[', ']========]')
        universal_inner = universal_inner[len('local source = [========['):]
        universal_ui = between(universal_inner, 'function RivalsAim.BuildUI()',
            '\nif IS_GENERIC or game.PlaceId == 17625359962')
        assert 'Elements.Label(' not in universal_ui, 'Universal module settings still have explanatory text'
        universal_inner_path = temp / 'universal-inner.luau'
        universal_inner_path.write_text(universal_inner, encoding='utf-8')
        for path in [UNIVERSAL, universal_inner_path]:
            subprocess.run([str(compiler), '--null', '-O0', '-g2', str(path)], check=True)
        print('PASS Universal source: wrapper and embedded game code compile')
        for client_name, client_inner in [('dedicated', inner), ('universal', universal_inner)]:
            lifecycle_spec = (ROOT / 'tests' / 'lifecycle-spec.luau').read_text(encoding='utf-8')
            lifecycle_spec = lifecycle_spec.replace('-- INSERT_UNLOAD',
                between(client_inner, 'ENV.SunsetUnload = function()', '\nprint(BRAND'))
            lifecycle_spec = lifecycle_spec.replace('-- INSERT_EARLY_ABORT',
                between(client_inner, 'ENV.SunsetAbortStartup = function()', '\nlocal Gui ='))
            lifecycle_path = temp / (client_name + '-lifecycle-spec.luau')
            lifecycle_path.write_text(lifecycle_spec, encoding='utf-8')
            subprocess.run([str(runtime), str(lifecycle_path)], check=True)
        assert 'pcall(environment.SunsetAbortStartup)' in universal_source
        for client_name, client_inner in [('dedicated', inner), ('universal', universal_inner)]:
            target_spec = (ROOT / 'tests' / 'target-index-spec.luau').read_text(encoding='utf-8')
            target_spec = target_spec.replace('-- INSERT_PLAYER_INDEX',
                between(client_inner, 'local TargetModels =', '\nlocal function modelPart'))
            target_path = temp / (client_name + '-target-index.luau')
            target_path.write_text(target_spec, encoding='utf-8')
            subprocess.run([str(runtime), str(target_path)], check=True)
            assert 'if game.PlaceId == 6872265039 or game.GameId == 2619619496 then\nfor _, node in ipairs(workspace:GetDescendants()) do indexBedWarsMapNode(node) end' in client_inner


        failure_spec = (ROOT / 'tests' / 'startup-failure-spec.luau').read_text(encoding='utf-8')
        failure_spec = failure_spec.replace('-- INSERT_STARTUP_ABORT',
            between(inner, 'ENV.SunsetAbortStartup = function()', '\nlocal Gui ='))
        failure_spec = failure_spec.replace('-- INSERT_WRAPPER_HANDOFF',
            source[source.rindex('local chunk, err = loadstring(source)'):])
        failure_spec = failure_spec.replace('-- INSERT_KILL_GETTER',
            between(inner, 'function BedWars.CurrentKills()', '\ndo\n    function BedWars.KillChatSend'))
        failure_spec = failure_spec.replace('-- INSERT_KILL_TOGGLE',
            between(inner, '        Elements.Toggle(chatSection, "Kill Chat"', '\n    end\n    do\n        local replySection'))
        failure_path = temp / 'startup-failure-spec.luau'
        failure_path.write_text(failure_spec, encoding='utf-8')
        subprocess.run([str(runtime), str(failure_path)], check=True)
        hands_spec = (ROOT / 'tests' / 'universal-hands-spec.luau').read_text(encoding='utf-8')
        hands_spec = hands_spec.replace('-- INSERT_UNIVERSAL_VIEWMODEL',
            between(universal_inner, '    local function moveAimViewmodel(', '\n    local contexts ='))
        hands_path = temp / 'universal-hands-spec.luau'
        hands_path.write_text(hands_spec, encoding='utf-8')
        subprocess.run([str(runtime), str(hands_path)], check=True)
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
            between(inner, 'if not Settings.IsColdWar then\n    -- Index player characters only', '\nlocal function modelPart'))
        coldwar_spec = coldwar_spec.replace('-- INSERT_ASSET_PRODUCTION',
            between(inner, 'local function riftAsset(', '\nlocal function riftTrashFallback'))
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
        assert 'function Settings.SetupColdWarBulletSpeed(' not in inner
        assert 'gameSection("Cold War", AimTab.Left, "Bullet Speed")' not in inner
        session_spec = (ROOT / 'tests' / 'session-spec.luau').read_text(encoding='utf-8')
        session_spec = session_spec.replace('-- INSERT_SESSION_TRACKER',
            between(inner, 'function Settings.SessionNumber(', '\nSettings.StartupStage("Preparing game runtime...")'))
        session_spec = session_spec.replace('-- INSERT_SESSION_HUD',
            between(inner, 'function Settings.SetupColdWarSession()', '\nfunction Settings.SetupColdWar()'))
        session_spec = session_spec.replace('-- INSERT_BEDWARS_SESSION_UPDATE',
            between(inner, 'local function updateSession()', '\ntask.spawn(function()'))
        session_path = temp / 'session-spec.luau'
        session_path.write_text(session_spec, encoding='utf-8')
        subprocess.run([str(runtime), str(session_path)], check=True)
        assert 'function Settings.SetupColdWarSeated()' not in inner
        assert '"Shoot While Seated"' not in inner
        assert '"Check Seated"' not in inner
        extras_spec = (ROOT / 'tests' / 'visual-extras-spec.luau').read_text(encoding='utf-8')
        extras_spec = extras_spec.replace('-- INSERT_VISUAL_EXTRAS',
            between(inner, 'function Settings.SetupColdWarVisualExtras()', '\nfunction Settings.SetupColdWarWeaponTuning('))
        extras_spec = extras_spec.replace('-- INSERT_VISIBILITY',
            between(inner, 'function Settings.SetupColdWarVisibility(', '\nfunction Settings.SetupColdWar()'))
        extras_path = temp / 'visual-extras-spec.luau'
        extras_path.write_text(extras_spec, encoding='utf-8')
        subprocess.run([str(runtime), str(extras_path)], check=True)
        assert 'function Settings.SetupColdWarHitSounds()' not in inner
        assert '"Hit Sounds"' not in inner
        assert 'assets/hitsounds/' not in inner
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
            between(inner, 'function Settings.SessionNumber(', '\nSettings.StartupStage("Preparing game runtime...")'),
            between(inner, 'function Settings.StartupStage(', '\nSettings.StartupStage("Loading menu controls...")'),
            between(inner, '    function BedWars.MusicOverlayVisible()', '\n    Persistence.HUDFrames.MusicOverlay'),
            between(inner, 'local function buildSpinbot(', '\nspinToggle = buildSpinbot('),
            between(inner, 'local function isNpcModel(', '\nSettings.AimSkipUnknown ='),
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
    listing = between(inner, '    local moduleList = new(', '\nlocal function rivalsModuleLoaded(')
    assert 'notificationsVisible' not in listing and 'ModuleListShifted' not in listing
    assert 'moduleList.Position = UDim2.new(1, -14, 0, 38)' in listing
    print('PASS module list: fixed right anchor independent of notifications')


if __name__ == '__main__':
    main()
