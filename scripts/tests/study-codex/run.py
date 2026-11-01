#!/usr/bin/env python3
"""Static wiring checks plus compiled shipping ProviderInstance using isolated stubs."""
import json, re, shutil, subprocess, sys, tempfile
from pathlib import Path
ROOT = Path(__file__).resolve().parents[3]
IOS = ROOT / 'src/ios'
def text(path): return (ROOT / path).read_text()
checks = 0
def check(ok, description):
    global checks
    assert ok, description
    checks += 1
provider = text('src/ios/Providers/OpenAI/OpenAIProvider.swift')
api = text('src/ios/Providers/OpenAI/OpenAIModelsAPI.swift')
store = text('src/ios/Providers/ProviderConfigStore.swift')
db = text('src/ios/Providers/ProviderConfigDB.swift')
ui = text('src/ios/Views/Providers/ProviderInstanceDetailView.swift')
quota = text('src/ios/Providers/Quota/QuotaStore.swift')
instance = text('src/ios/Providers/ProviderInstance.swift')
check(provider.count('let codexVersion = await currentCodexClientVersion()') == 2, 'both inference builders read saved settings')
check('setValue(Self.codexClientVersion' not in provider, 'no inference hardcoded version')
check('instance(for: instanceId)?.effectiveCodexClientVersion' in provider, 'ongoing sessions resolve current setting')
check('clientVersion: instance.effectiveCodexClientVersion' in store, 'model discovery receives effective version')
check('fetchCodexBackendModels(token: token, accountId: accountId, version: clientVersion)' in api, 'actual directory request receives version')
check('URLQueryItem(name: "client_version", value: version)' in api, 'version encoded as query parameter')
check('"codex-oauth-last|\\(instanceId)|\\(accountId ?? "-")|\\(clientVersion)"' in api, 'offline cache segregated by selected version')
check('"codex-oauth|\\(accountId ?? "-")|\\(clientVersion)|\\(token)"' in api, 'primary cache segregated by selected version')
check('codex-version-changed' in store and 'discarded an outdated refresh' in store, 'saved change refreshes and stale replies cannot overwrite')
check('d.instanceId)?.effectiveCodexClientVersion' in quota, 'quota uses matching selected version')
check('codexVersionFromExtras(r["extras_json"]' in db, 'DB comparison detects setting edits')
check('extrasJson: inst.codexVersionExtras(merging:' in db, 'DB persists setting without schema change')
check('codexClientVersionOverride: ProviderInstance.codexVersionFromExtras(row[' in db, 'DB reloads setting')
check('dict["codexClientVersionOverride"] = version' in store and 'codexClientVersionOverride: dict[' in store, 'single-provider export/import preserved')
check('if instance.supportsCodexClientVersion' in ui and 'codexClientVersionSection(instance)' in ui, 'setting scoped to ChatGPT OAuth UI')
check('store.instance(for: instanceId), updated.supportsCodexClientVersion' in ui, 'save uses fresh instance rather than overwriting stale config')
check('updated.codexClientVersionOverride = value' in ui and 'normalizedCodexClientVersion(raw)' in ui, 'validated save / reset')
check('decodeIfPresent(String.self, forKey: .codexClientVersionOverride)' in instance and 'encodeIfPresent(codexClientVersionOverride' in instance, 'old backups compatible and new values included')
locales = json.loads(text('src/ios/Localizable.xcstrings'))['strings']
check(locales['Codex Client Version']['localizations']['zh-Hans']['stringUnit']['value'] == 'Codex 版本号', 'Chinese label')
rootfs = text('src/ios/iSH/RootfsManager.swift')
check('appendingPathComponent("environment"' in rootfs and 'return legacy' in rootfs, 'rootfs migration and fallback preserved')
check('MinisStudyLocalContainer' in text('src/ios/Shared/SharedContainerStore.swift'), 'sideload sandbox fallback preserved')
check('asCopy: true' in text('src/ios/Views/Settings/BackupRestoreView.swift'), 'backup file picker fix preserved')
for path in ['BackupAndRestoreView.swift', 'MountedFoldersSettingsView.swift']:
    check('asCopy: false' in text('src/ios/Views/Settings/' + path), 'directory picker preserved: '+path)
check('backup.destination.systemShare' in text('src/ios/Views/Settings/BackupSettingsView.swift'), 'system-share backup preserved')
print(f'PASS: {checks} static wiring and study regression checks')
if '--static-only' not in sys.argv:
    swift = shutil.which('swiftc')
    if not swift: raise SystemExit('swiftc is required for runtime tests (use --static-only on iSH)')
    with tempfile.TemporaryDirectory(prefix='study-codex-tests-') as tmp:
        exe = Path(tmp) / 'codex-tests'
        subprocess.run([swift, str(IOS/'Providers/ProviderInstance.swift'), str(Path(__file__).with_name('Stubs.swift')), str(Path(__file__).with_name('main.swift')), '-o', str(exe)], check=True)
        subprocess.run([str(exe)], check=True)
