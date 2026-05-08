---
description: "Use when building secure Electron desktop applications. Covers process architecture, inter-process communication, content security policy, code signing, auto-updates, credential storage, and ASAR integrity. Reference skill at skills/electron-apps/SKILL.md for implementation patterns."
applyTo: "**/*"
---

# Electron Desktop Application Security Standards

Use this instruction when developing Electron applications to ensure secure process architecture, IPC patterns, and protective measures against common desktop vulnerabilities.

## Expectations

- All renderer processes run in sandbox mode with nodeIntegration disabled.
- IPC is restricted to explicit preload-exposed APIs via contextBridge.
- child_process.spawn() calls are restricted to safe, validated commands (no shell execution).
- All executables are code-signed (Windows/macOS).
- Auto-updates validate checksums before installing.
- Sensitive credentials are stored in OS keychains, never in application memory or files.
- Content Security Policy (CSP) headers restrict inline scripts and external resource loading.
- ASAR packages are integrity-checked on load.

## Process Architecture

Electron runs two processes with distinct privilege levels:

| Process | Runtime | Privileges | Responsibility |
|---|---|---|---|
| **Main** | Node.js | Full system access | App lifecycle, native APIs, file I/O, window management |
| **Renderer** | Chromium | Restricted (sandboxed) | UI rendering, user interaction, DOM manipulation |

**Critical**: Renderer processes are the attack surface. Restrict their capabilities aggressively.

## Inter-Process Communication (IPC)

IPC is the only trusted communication path between renderer and main. Restrict IPC to explicit, validated channels.

### Preload Scripts

Preload scripts run in the renderer context with access to both main process APIs and the DOM. They are the security boundary.

**Correct Pattern: Restricted Preload**

```javascript
// preload.js
const { contextBridge, ipcRenderer } = require('electron');

// Only expose safe APIs
contextBridge.exposeInMainWorld('api', {
  // Request data — no mutation
  getData: () => ipcRenderer.invoke('get-data'),

  // Update data — validate on receive
  updateData: (data) => {
    if (!validateDataSchema(data)) {
      throw new Error('Invalid data schema');
    }
    return ipcRenderer.invoke('update-data', data);
  },

  // Subscribe to events
  onDataChanged: (callback) => {
    ipcRenderer.on('data-changed', (_event, data) => {
      callback(data);
    });
  },
});

function validateDataSchema(data) {
  // Implement validation; reject untrusted data
  return data && typeof data === 'object';
}
```

**Incorrect Patterns to Avoid**

```javascript
// ❌ NEVER: expose ipcRenderer directly
contextBridge.exposeInMainWorld('ipc', ipcRenderer);

// ❌ NEVER: expose require() or process
contextBridge.exposeInMainWorld('require', require);
contextBridge.exposeInMainWorld('process', process);

// ❌ NEVER: set nodeIntegration = true
new BrowserWindow({
  webPreferences: { nodeIntegration: true }, // DANGEROUS
});
```

### Main Process IPC Handlers

Main process handlers must validate all input and sanitize responses.

```javascript
// main.js
const { ipcMain } = require('electron');
const fs = require('fs');
const path = require('path');

// Validate input before processing
ipcMain.handle('get-data', async (event) => {
  try {
    const data = await loadDataFromSecureLocation();
    // Return only necessary fields; never return sensitive metadata
    return {
      id: data.id,
      name: data.name,
      // Do NOT return: data.internalToken, data.adminFlag, etc.
    };
  } catch (error) {
    console.error('get-data error:', error);
    throw new Error('Failed to retrieve data');
  }
});

ipcMain.handle('update-data', async (event, data) => {
  // Validate schema
  if (!data || typeof data.id !== 'string' || typeof data.name !== 'string') {
    throw new Error('Invalid data schema');
  }

  // Sanitize inputs
  const sanitized = {
    id: String(data.id).slice(0, 36), // UUID length
    name: String(data.name).slice(0, 256), // Max name length
  };

  try {
    await saveDataToSecureLocation(sanitized);
    return { ok: true };
  } catch (error) {
    console.error('update-data error:', error);
    throw new Error('Failed to update data');
  }
});

// ❌ NEVER: accept arbitrary file paths
ipcMain.handle('read-file', async (event, filePath) => {
  // This allows renderer to read ANY file (../ traversal, system files)
  return fs.readFileSync(filePath, 'utf8');
});

// ✅ CORRECT: whitelist safe paths
const SAFE_PATHS = {
  userDocuments: path.join(app.getPath('userData'), 'documents'),
  userCache: path.join(app.getPath('userData'), 'cache'),
};

ipcMain.handle('read-user-file', async (event, filename) => {
  // Prevent path traversal
  const fullPath = path.normalize(path.join(SAFE_PATHS.userDocuments, filename));
  if (!fullPath.startsWith(SAFE_PATHS.userDocuments)) {
    throw new Error('Path traversal detected');
  }
  return fs.readFileSync(fullPath, 'utf8');
});
```

## Content Security Policy (CSP)

CSP headers restrict script execution and resource loading in the renderer.

**Strict CSP**

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
  upgrade-insecure-requests;
">
```

**CSP Directives Explained**

| Directive | Value | Purpose |
|---|---|---|
| `default-src 'none'` | Deny all by default | Block inline scripts, external resources |
| `script-src 'self'` | Only same-origin scripts | Prevent inline JS and external CDN scripts |
| `style-src 'self' 'unsafe-inline'` | Same-origin or inline CSS | Unsafe-inline required for built-in styles; consider external stylesheet |
| `img-src 'self' data:` | Same-origin or data URIs | Block external image loads |
| `connect-src 'self'` | Same-origin HTTP/WS | Restrict XMLHttpRequest and WebSocket |
| `object-src 'none'` | Disable plugins | Prevent Flash, Java applets |
| `frame-ancestors 'none'` | No framing allowed | Prevent clickjacking |

## Child Process Execution

Electron apps often spawn child processes (git, Node, Python). This is a high-risk operation.

**Secure Pattern: Whitelisted Commands**

```javascript
// main.js
const { spawn } = require('child_process');
const path = require('path');

// Whitelist safe, trusted executables
const ALLOWED_COMMANDS = {
  git: 'git', // system PATH git
  python: process.platform === 'win32' ? 'python.exe' : 'python3',
};

ipcMain.handle('run-command', async (event, cmd, args) => {
  // Validate command is in whitelist
  if (!ALLOWED_COMMANDS[cmd]) {
    throw new Error(`Command '${cmd}' not allowed`);
  }

  // Validate args (no shell metacharacters)
  if (!Array.isArray(args) || args.some(arg => typeof arg !== 'string')) {
    throw new Error('Invalid arguments');
  }

  // Validate no shell metacharacters (; | & > < $ etc.)
  const unsafeChars = /[;&|<>$`(){}[\]\\]/;
  if (args.some(arg => unsafeChars.test(arg))) {
    throw new Error('Invalid characters in arguments');
  }

  return new Promise((resolve, reject) => {
    const proc = spawn(ALLOWED_COMMANDS[cmd], args, {
      shell: false, // CRITICAL: never use shell: true
      timeout: 30000, // 30s timeout to prevent hanging
      env: {
        // Pass only safe environment variables
        PATH: process.env.PATH,
        HOME: process.env.HOME,
      },
    });

    let stdout = '';
    let stderr = '';

    proc.stdout.on('data', (data) => {
      stdout += data.toString();
      if (stdout.length > 10 * 1024 * 1024) { // 10MB limit
        proc.kill();
        reject(new Error('Output too large'));
      }
    });

    proc.stderr.on('data', (data) => {
      stderr += data.toString();
    });

    proc.on('close', (code) => {
      if (code === 0) {
        resolve(stdout);
      } else {
        reject(new Error(`Command failed with exit code ${code}: ${stderr}`));
      }
    });

    proc.on('error', (err) => {
      reject(err);
    });
  });
});

// ❌ NEVER: accept arbitrary commands
ipcMain.handle('run-command-unsafe', async (event, cmd) => {
  return new Promise((resolve, reject) => {
    exec(cmd, (error, stdout, stderr) => { // exec uses shell, dangerous!
      if (error) reject(error);
      else resolve(stdout);
    });
  });
});
```

## Code Signing

Code signing ensures binaries haven't been tampered with. Require signatures for auto-updates and distribution.

**Windows Signing**

```javascript
// main.js (after build)
const certificateFile = 'C:\\Path\\To\\cert.pfx';
const certificatePassword = process.env.CERTIFICATE_PASSWORD; // From CI/CD secrets

// In build/signing step:
// signtool.exe sign /f cert.pfx /p <password> /t http://timestamp.server.com app.exe
```

**macOS Signing**

```bash
# Code sign the app
codesign --deep --force --verify --verbose --sign - /path/to/App.app

# Verify signature
codesign -v /path/to/App.app
spctl -a -v /path/to/App.app
```

**Verification in Main Process**

```javascript
const { app } = require('electron');

// On macOS, verify signature before launching
if (process.platform === 'darwin') {
  const { execSync } = require('child_process');
  try {
    const output = execSync(`codesign -v "${app.getAppPath()}"`).toString();
    if (!output.includes('valid on disk')) {
      throw new Error('Invalid code signature');
    }
  } catch (error) {
    console.error('Code signature verification failed:', error);
    app.quit();
  }
}
```

## Auto-Updates

Auto-updates must verify checksums and signatures to prevent tampering.

**Secure Auto-Update Pattern**

```javascript
// main.js
const { autoUpdater } = require('electron-updater');
const crypto = require('crypto');
const https = require('https');

// Configure auto-updater
autoUpdater.checkForUpdatesAndNotify();

autoUpdater.on('before-quit-for-update', () => {
  // Application will quit and install update
  console.log('Update ready, quitting to install');
});

ipcMain.handle('check-for-updates', async (event) => {
  try {
    const result = await autoUpdater.checkForUpdates();
    return {
      updateAvailable: result.updateInfo != null,
      version: result.updateInfo?.version,
    };
  } catch (error) {
    console.error('Update check failed:', error);
    throw error;
  }
});

// Validate update checksums
const verifyChecksum = (file, expectedHash) => {
  const hash = crypto.createHash('sha256');
  const stream = require('fs').createReadStream(file);
  return new Promise((resolve, reject) => {
    stream.on('data', (chunk) => hash.update(chunk));
    stream.on('end', () => {
      const digest = hash.digest('hex');
      resolve(digest === expectedHash);
    });
    stream.on('error', reject);
  });
};
```

**Configuration (electron-builder.json)**

```json
{
  "publish": {
    "provider": "github",
    "owner": "your-org",
    "repo": "your-app"
  },
  "build": {
    "sign": true,
    "certificateFile": "path/to/cert.pfx",
    "certificatePassword": "${CERTIFICATE_PASSWORD}"
  }
}
```

## Credential Storage

Never store credentials in application memory or configuration files. Use OS keychains.

**Secure Pattern: OS Keychain**

```javascript
// main.js
const { safeStorage } = require('electron');
const keytar = require('keytar');

// Store credential in OS keychain
ipcMain.handle('store-credential', async (event, service, account, password) => {
  try {
    await keytar.setPassword(service, account, password);
    return { ok: true };
  } catch (error) {
    console.error('Failed to store credential:', error);
    throw error;
  }
});

// Retrieve credential from OS keychain
ipcMain.handle('get-credential', async (event, service, account) => {
  try {
    const password = await keytar.getPassword(service, account);
    if (!password) {
      return null;
    }
    return password;
  } catch (error) {
    console.error('Failed to retrieve credential:', error);
    throw error;
  }
});

// ❌ NEVER: store credentials in config files
const config = {
  apiKey: 'secret-key-123', // DANGEROUS
  password: 'user-password', // DANGEROUS
};

// ❌ NEVER: store in application memory unencrypted
let userPassword = '';
ipcMain.handle('login', async (event, password) => {
  userPassword = password; // DANGEROUS
  return validate(userPassword);
});
```

## ASAR Integrity

ASAR (Atom Shell Archive) packages the app code. Verify ASAR integrity on load to detect tampering.

```javascript
// main.js
const fs = require('fs');
const crypto = require('crypto');

const verifyAsarIntegrity = () => {
  const asarPath = path.join(app.getAppPath(), 'app.asar');
  if (!fs.existsSync(asarPath)) {
    console.log('ASAR archive not found; running in dev mode');
    return true;
  }

  // Compute hash of ASAR file
  const hash = crypto.createHash('sha256');
  const stream = fs.createReadStream(asarPath);
  return new Promise((resolve, reject) => {
    stream.on('data', (chunk) => hash.update(chunk));
    stream.on('end', () => {
      const digest = hash.digest('hex');
      const expectedHash = fs.readFileSync(path.join(asarPath, '../app.asar.sha256'), 'utf8').trim();
      if (digest === expectedHash) {
        console.log('ASAR integrity verified');
        resolve(true);
      } else {
        console.error('ASAR integrity check failed');
        resolve(false);
      }
    });
    stream.on('error', reject);
  });
};

app.on('ready', async () => {
  if (!await verifyAsarIntegrity()) {
    app.quit();
  }
});
```

## Review Lens

When reviewing Electron code, verify:

- [ ] All renderer processes run with `sandbox: true` in `webPreferences`.
- [ ] `nodeIntegration` is explicitly set to `false`.
- [ ] `enableRemoteModule` is set to `false`.
- [ ] IPC is restricted to explicit preload-exposed APIs.
- [ ] Preload scripts use `contextBridge` to expose only necessary functions.
- [ ] All IPC handlers validate input and sanitize responses.
- [ ] `child_process.spawn()` never uses `shell: true`.
- [ ] Commands are whitelisted; arguments are validated for shell metacharacters.
- [ ] CSP headers are enforced; inline scripts are blocked.
- [ ] Credentials are stored in OS keychains, not files or memory.
- [ ] Code is signed for distribution (Windows/macOS).
- [ ] Auto-updates validate checksums before installation.
- [ ] ASAR packages are integrity-checked on load.

## Standards and References

- **Electron Security** — Official Electron documentation on security best practices.
- **OWASP Desktop Application Security** — Guidance for desktop app vulnerabilities.
- **CWE-502 (Deserialization of Untrusted Data)** — Risk of unmarshaling untrusted objects.
- **CWE-95 (Improper Neutralization of Directives in Dynamically Evaluated Code)** — Code injection via eval/exec.
- **CWE-426 (Untrusted Search Path)** — Risk of loading compromised modules from PATH.
