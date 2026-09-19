# 🛡️ AntiClipper: Crypto Clipboard Hijacker Detector & Remover

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: Windows](https://img.shields.io/badge/Platform-Windows-0078D6.svg)](https://microsoft.com/windows)
[![PowerShell: 5.1+](https://img.shields.io/badge/PowerShell-5.1+-5391FE.svg)](https://microsoft.com/powershell)

A specialized, open-source security tool for Windows designed to detect, diagnose, and permanently remove **Crypto Clipboard Hijackers** (Clipper Trojans / Stealers).

---

## 🛑 The Threat: How Clipper Malware Works

Crypto Clipboard Hijackers monitor your Windows clipboard 24/7. When you copy a cryptocurrency address (Ethereum `0x...`, Bitcoin `bc1...`, Solana, etc.) from MetaMask, Binance, or an exchange:

1. The malware intercepts the copy event in milliseconds.
2. It silently substitutes your intended destination address with the **attacker's wallet address**.
3. When you click **Send** or **Transfer**, your funds are permanently stolen.

### 🕵️ How Modern Clippers Hide on Windows

Traditional antiviruses often miss these clippers because modern strains use **stealth system-level techniques**:
* **COM Hijacking (`HKCU\Software\Classes\CLSID`)**: The malware registers an unprivileged user COM class pointing to a fake DLL (e.g. masquerading as `EdgeWebView\msedgeview.dll` in AppData).
* **`explorer.exe` Injection**: Whenever Windows Explorer starts or opens a folder, it automatically loads the rogue DLL into its own memory space as a shell extension.
* **Transient User Handles**: The malware creates and destroys temporary windows on the fly to avoid detection by standard task managers.

---

## ✨ Features of AntiClipper

- [x] **Live Address Injection Test**: Automatically tests Ethereum, Bitcoin, and Solana test vectors to verify whether clipboard hijacking is actively occurring.
- [x] **COM CLSID Hijack Scanner**: Analyzes all user-level registered InprocServer32 DLLs in `HKCU:\Software\Classes\CLSID`, detecting unsigned binaries and masqueraded paths.
- [x] **Masqueraded Binary Hunter**: Scans known evasion locations (like `%LOCALAPPDATA%\Microsoft\EdgeWebView\msedgeview.dll`).
- [x] **Clean Thread Unloading & Explorer Restart**: Automatically terminates Explorer safely to release file locks on injected DLLs.
- [x] **Complete Threat Remediation**: Safely purges malicious registry keys and removes the malware binaries.
- [x] **Post-Remediation Verification**: Re-tests your clipboard to guarantee that your system is 100% clean.

---

## 🚀 How to Run

### Method 1: Run via PowerShell (Recommended)

1. Open **PowerShell** (no Administrator required for user-level COM hijackers, though running as Administrator is supported).
2. Run the script:
```powershell
powershell -ExecutionPolicy Bypass -File .\AntiClipper.ps1
```

### Method 2: One-Liner Quick Scan

```powershell
powershell -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/<YOUR_USERNAME>/AntiClipper/main/AntiClipper.ps1 | iex"
```

---

## 🖥️ Example Output

```text
====================================================================
    ___          __  _  _____ _ _                      
   / _ \        / /_(_)/ ____| (_)                     
  / /_\ \ _ __ |  _/ _/ /    | |_ _ __  _ __   ___ _ __
  |  _  || '_ \| | | | |     | | | '_ \| '_ \ / _ \ '__|
  | | | || | | | |_| | \____ | | | |_) | |_) |  __/ |   
  \_| |_/|_| |_|\__|_|\_____/|_|_| .__/| .__/ \___|_|   
                                 | |   | |             
                                 |_|   |_|             
    CRYPTO CLIPBOARD HIJACKER DETECTOR & CLEANER v1.0
====================================================================

>>> Running real-time clipboard injection test...
 [✗] HIJACK DETECTED for Ethereum!
      Injected:  0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045
      Replaced:  0xcEBDCBA0a42B2dE9Be38c48d648471C672C007C1

>>> Scanning HKCU User CLSIDs for InprocServer32 hijacking...
 [✗] Found malicious/suspicious COM entry: {AAA288BA-9A4C-45B0-95D7-94D524869DB5}
      Target DLL: C:\Users\user\AppData\Local\Microsoft\EdgeWebView\msedgeview.dll
      Reason:     Masquerading as Microsoft Edge in AppData

>>> SCAN SUMMARY
--------------------------------------------------------------------
 Live Hijack Detected:  YES (1 chains)
 Malicious COM Keys:    1
 Rogue Malware Files:   1
--------------------------------------------------------------------

[!] Threat(s) detected! Do you want AntiClipper to remove them now? (Y/N): Y

>>> Starting remediation process...
 [*] Removing registry key: HKCU:\Software\Classes\CLSID\{AAA288BA-...}...
 [✓] Registry key removed successfully.
 [!] Restarting Windows Explorer to unload malicious threads...
 [✓] Windows Explorer restarted clean.
 [*] Deleting malicious file: C:\Users\user\AppData\Local\Microsoft\EdgeWebView\msedgeview.dll...
 [✓] File deleted successfully.

>>> VERIFYING REMEDIATION...
 [✓] Ethereum clipboard test passed (unaltered).
 [✓] Bitcoin clipboard test passed (unaltered).
 [✓] Solana clipboard test passed (unaltered).

====================================================================
  [✓] SUCCESS: CLIPBOARD HIJACKER COMPLETELY REMOVED!
      Your crypto transactions are now safe.
====================================================================
```

---

## 🔒 Security Best Practices

1. **Always double-check the first and last 4–6 characters** of any crypto address before confirming a transaction.
2. **Use Hardware Wallets** (Ledger, Trezor) where the on-device display verifies the actual recipient address independently of your PC.
3. Keep Windows and your browser extensions regularly updated.

---

## 📜 License

This project is licensed under the [MIT License](LICENSE). Feel free to share, fork, and contribute!
