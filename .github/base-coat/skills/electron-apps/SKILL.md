---

name: electron-apps
description: Build secure, production-ready Electron desktop applications with best practices for IPC, CSP, state management, testing, packaging, and auto-updates.
applyTo: agent-electron-developer, agent-desktop-engineer
compatibility: ["VS Code", "Cursor", "Windsurf", "Claude Code"]
metadata:
  category: "Uncategorized"
  tags: ["uncategorized"]
  maturity: "beta"
  audience: ["developers"]
allowed-tools: ["bash", "git", "grep", "find"]
---

# Electron Application Development

Professional Electron application patterns for building secure, scalable desktop software.

## Core Concepts

### Process Architecture

Electron runs two processes:
- **Main Process**: Node.js runtime; controls app lifecycle, windows, and native APIs
- **Renderer Process**: Chromium; runs UI, DOM API, restricted system access (unless configured)

```javascript
// main.js — Main Process
const { app, BrowserWindow } = require('electron');

app.on('ready', () => {
  const win = new BrowserWindow({
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      sandbox: true,
      nodeIntegration: false,
      enableRemoteModule: false,
    },
  });
  win.loadFile('index.html');
});
```

### Inter-Process Communication (IPC)

Use preload scripts and ipcMain/ipcRenderer for secure communication.

```javascript
// preload.js — Runs in renderer context with main process access
const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('api', {
  getData: () => ipcRenderer.invoke('get-data'),
  onUpdate: (callback) => ipcRenderer.on('update', (_event, data) => callback(data)),
});

// main.js — Handle IPC calls
ipcMain.handle('get-data', async () => {
  return { /* data */ };
});
ipcMain.on('set-data', (event, data) => {
  event.reply('ack', { ok: true });
});
```

## Content Security Policy (CSP)

Enforce strict CSP headers to prevent XSS and injection attacks.

```html
<!-- index.html -->
<meta http-equiv="Content-Security-Policy" content="
  default-src 'none';
  script-src 'self';
  style-src 'self' 'unsafe-inline';
  img-src 'self' data:;
  font-src 'self';
  connect-src 'self';
  object-src 'none';
  frame-ancestors 'none';
  base-uri 'self';
  form-action 'self';
">
```

## State Management Patterns

### Local State (Single Window)

Use React, Vue, or Svelte with local state.

```javascript
// React + React Query example
import { useQuery, useMutation } from '@tanstack/react-query';

export const useAppData = () => {
  return useQuery({
    queryKey: ['app-data'],
    queryFn: async () => window.api.getData(),
  });
};

export const useUpdateData = () => {
  return useMutation({
    mutationFn: (data) => window.api.updateData(data),
  });
};
```

### Shared State (Multi-Window)

Use Electron's `ipcMain` broadcast or external state service.

```javascript
// main.js — Shared state via event emission
const { ipcMain } = require('electron');

let appState = {};

ipcMain.handle('state:get', () => appState);
ipcMain.handle('state:set', (event, newState) => {
  appState = { ...appState, ...newState };
  // Broadcast to all windows
  mainWindow?.webContents?.send('state:changed', appState);
  return appState;
});
```

## Testing Patterns

### Unit Tests (Jest + Electron)

```javascript
// src/utils/__tests__/math.test.js
import { add, multiply } from '../math';

describe('Math utils', () => {
  it('adds numbers correctly', () => {
    expect(add(2, 3)).toBe(5);
  });
});
```

### Integration Tests (Spectron → WebdriverIO)

Spectron is deprecated; use WebdriverIO with Electron driver.

```javascript
// test/integration.js
import { remote } from 'webdriverio';

describe('Electron App', () => {
  it('launches and shows window', async () => {
    const app = await remote({
      capabilities: {
        browserName: 'chrome',
        'wdio:electronService': {},
      },
    });

    const title = await app.getTitle();
    expect(title).toBe('My App');
    await app.deleteSession();
  });
});
```

## Packaging & Distribution

### Electron Forge

Standard tool for packaging Electron apps.

```javascript
// forge.config.js
module.exports = {
  packagerConfig: {
    asar: true,
    icon: './assets/icon',
    osxSign: {
      identity: 'Developer ID Application: Company (ID)',
    },
  },
  makers: [
    {
      name: '@electron-forge/maker-squirrel',
      config: {
        certificateFile: './cert.pfx',
        certificatePassword: process.env.CERT_PASSWORD,
      },
    },
    {
      name: '@electron-forge/maker-dmg',
    },
    {
      name: '@electron-forge/maker-zip',
    },
  ],
};
```

### Signing & Notarization (macOS)

```bash
# Build and sign for macOS
npm run make -- --platform darwin

# Notarize (Apple notarization)
xcrun altool --notarize-app --file MyApp.dmg --primary-bundle-id com.example.app \
  -u developer@apple.com -p @keychain:Developer-ID
```

## Auto-Updates

Use `electron-updater` for staged, delta-compressed updates.

```javascript
// main.js
import { autoUpdater } from 'electron-updater';

autoUpdater.checkForUpdatesAndNotify();

autoUpdater.on('update-downloaded', () => {
  autoUpdater.quitAndInstall();
});
```

**Update server config:**
```javascript
autoUpdater.setFeedURL({
  provider: 'github',
  owner: 'myorg',
  repo: 'myapp',
  token: process.env.GH_TOKEN,
});
```

## Performance & UX

- **Code splitting**: Lazy-load renderer code with dynamic import()
- **V8 code caching**: Pre-compile scripts for faster startup
- **Memory profiling**: Use Chrome DevTools in dev mode
- **Native modules**: Compile with `native-addon-build` to match Electron's Node.js version

## Security Checklist

- [ ] Node integration disabled (`nodeIntegration: false`)
- [ ] Remote module disabled (`enableRemoteModule: false`)
- [ ] Preload script sandboxed (`sandbox: true`)
- [ ] CSP meta tag enforced
- [ ] IPC: Validate all messages from renderer
- [ ] Code signing + notarization (production)
- [ ] No hardcoded secrets (use environment variables)
- [ ] Dependencies scanned with `npm audit`
- [ ] Auto-updates signed and verified

## Common Patterns

**Stay always-on-top**: `win.setAlwaysOnTop(true)`
**Tray menu**: `Menu.setApplicationMenu(createMenu())`
**Deep linking**: Use `deep-linking` protocol + `app.on('open-url')`
**Crash reporting**: Integrate Sentry or similar
