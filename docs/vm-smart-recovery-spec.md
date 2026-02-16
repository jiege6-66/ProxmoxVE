# VM Smart Recovery — Arbeitsanweisung

**Branch:** `feature/vm-smart-recovery` (basiert auf `main`)  
**Verwandt:** `feature/smart-error-recovery` (LXC, PR #11221)  
**Erstellt:** 2026-02-16

---

## 1. Ausgangslage

### Architektur-Vergleich LXC vs. VM

| Aspekt | LXC (fertig in PR #11221) | VM (offen) |
|---|---|---|
| Shared Code | `misc/build.func` (5577 Zeilen) | `misc/vm-core.func` (627 Zeilen) — **nur von `docker-vm.sh` genutzt** |
| Anzahl Scripts | ~170 | 15 |
| Architektur | Alle nutzen `build_container()` | **2 Generationen** (s.u.) |
| Software-Install | `pct exec` → Install-Script im Container | Variiert: `virt-customize`, Cloud-Init, `qm sendkey`, oder gar nichts |
| Telemetrie | `post_to_api()` + `post_update_to_api()` | Identisch — alle sourcen `misc/api.func` |
| Error Handling | Zentral in `build.func` Traps | Jedes Script hat eigenen `error_handler()` |
| Recovery | Smart-Menü mit 6 dynamischen Optionen | **Keine** — bei Fehler wird VM sofort zerstört (`cleanup_vmid`) |

### Zwei Generationen von VM-Scripts

**Generation 1 — Legacy (monolithisch):** `haos-vm.sh`, `debian-vm.sh`, `openwrt-vm.sh` und 11 weitere.  
- Selbstständige 500–700-Zeilen-Scripts
- Definieren **alle** Utility-Funktionen inline (Colors, Icons, `msg_info`/`msg_ok`, `error_handler`, `cleanup`, etc.)
- Sourcen nur `misc/api.func` für Telemetrie

**Generation 2 — Modern (modular):** Ausschließlich `docker-vm.sh`.  
- Sourced drei Shared Libraries:
  - `misc/api.func` — Telemetrie
  - `misc/vm-core.func` — Shared Utilities (627 Zeilen)
  - `misc/cloud-init.func` — Cloud-Init Konfiguration (709 Zeilen)
- Ruft `load_functions` aus `vm-core.func` auf

### Telemetrie-Daten (Top VM-Failures)

| Script | Anteil an VM-Failures |
|---|---|
| `docker-vm.sh` | 30.1 % |
| `openwrt-vm.sh` | 25.9 % |
| `debian-13-vm.sh` | 9.6 % |

---

## 2. Scope & Abgrenzung

### In Scope

- Smart Recovery für VM-Erstellungsfehler (Retry-Menü analog LXC)
- Fehlererkennung: Download, Disk-Import, virt-customize, Ressourcen-Konflikte, Netzwerk
- Exit-Code-Mapping (bereits in `api.func` vorhanden, wird geteilt)

### Out of Scope (bewusst)

- **Migration aller Legacy-Scripts auf `vm-core.func`** → eigenes Refactoring-Ticket
- **In-VM-Repair** → VMs haben kein `pct exec`-Äquivalent
- **`qm sendkey`-Recovery** (OpenWrt) → prinzipbedingt nicht retryable
- **APT/DPKG-Repair innerhalb der VM** → kein Shell-Zugang während Install

---

## 3. Software-Installationsmethoden pro Script

| Script | Methode | Beschreibung |
|---|---|---|
| `docker-vm.sh` | `virt-customize` | Offline Image-Manipulation (libguestfs) |
| `docker-vm.sh` (Fallback) | systemd First-Boot-Service | Script läuft in VM beim ersten Boot |
| `haos-vm.sh` | Keine | Pre-built Appliance (qcow2) |
| `debian-vm.sh` / `debian-13-vm.sh` | Keine / Cloud-Init | Basis Cloud-Image |
| `openwrt-vm.sh` | `qm sendkey` | Virtuelle Tastatur-Automation |
| `opnsense-vm.sh` | `qm sendkey` + Bootstrap | Virtuelle Tastatur |
| `ubuntu-*-vm.sh` | Cloud-Init | User konfiguriert vor Start |
| `owncloud-vm.sh` | `virt-customize` | Wie docker-vm.sh |

---

## 4. Dateien & Änderungen

### 4.1 `misc/vm-core.func` — Zentrale Recovery-Logik

#### Neue Funktion: `vm_error_handler_with_recovery()`

```
Ablauf:
├── Exit-Code erfassen ($? als ERSTES — kein ensure_log_on_host davor!)
├── Fehlerklassifikation:
│   ├── Download-Fehler (curl exit 6/7/22/28/35/52/56)
│   ├── Disk-Import-Fehler (qm importdisk, pvesm alloc)
│   ├── virt-customize-Fehler (libguestfs)
│   ├── Ressourcen-Konflikt (VMID exists, Storage full)
│   └── Netzwerk-Fehler (DNS, Timeout)
├── Smart Recovery Menü:
│   ├── [1] Retry (VM zerstören & neu erstellen)
│   ├── [2] Retry mit anderen Einstellungen (RAM/CPU/Disk ändern)
│   ├── [3] VM behalten (nicht zerstören, manuell debuggen)
│   ├── [4] Abbrechen (VM zerstören, Exit)
│   └── Dynamische Optionen je nach Fehlertyp:
│       ├── Download-Fehler → "Cache löschen & neu downloaden"
│       └── Ressourcen-Konflikt → "Andere VMID wählen"
└── Bei Retry: cleanup_vmid() + create-Funktion erneut aufrufen
```

#### Neue Helper-Funktionen (Fehlererkennung):

```bash
is_download_error()      # curl exit codes + HTTP 404/500
is_disk_import_error()   # qm importdisk stderr patterns
is_virt_customize_err()  # libguestfs error patterns
is_vmid_conflict()       # "already exists" in stderr
is_storage_full()        # "not enough space" patterns
```

#### Log-Erfassung für VMs

Anders als LXC (wo `/root/.install*.log` im Container liegt) müssen VM-Fehler direkt aus stderr der `qm`/`virt-customize` Befehle erfasst werden:

```bash
# Jeder kritische Befehl mit stderr-Capture:
VM_ERROR_LOG="/tmp/vm-install-${VMID}.log"
qm importdisk "$VMID" "$IMAGE" "$STORAGE" 2>> "$VM_ERROR_LOG"
virt-customize -a "$IMAGE" --install docker.io 2>> "$VM_ERROR_LOG"
```

### 4.2 Retry-Wrapper-Architektur

Da VMs kein zentrales `build_container()` haben, gibt es zwei Ansätze:

#### Option A: Wrapper in `vm-core.func` (empfohlen für Gen-2 Scripts)

```bash
vm_create_with_recovery() {
  local create_fn="$1"   # VM-spezifische Erstellungsfunktion
  local max_retries=2
  local attempt=0

  while true; do
    if "$create_fn"; then
      return 0  # Erfolg
    fi
    ((attempt++))
    if ((attempt >= max_retries)); then
      # Max retries erreicht → nur noch "behalten" oder "abbrechen"
    fi
    vm_show_recovery_menu "$?" "$attempt"
    # Menü-Auswahl verarbeiten...
  done
}
```

#### Option B: Inline-Recovery in Legacy-Scripts

Für die 14 Legacy-Scripts (bis Migration auf `vm-core.func`):
- Minimaler Patch: `error_handler()` um Recovery-Prompt erweitern
- `cleanup_vmid` **nicht** sofort aufrufen, sondern erst nach User-Entscheidung

**Empfehlung:** Zunächst **nur `docker-vm.sh`** (30.1 % der Failures) mit Option A umsetzen. Legacy-Scripts als Phase 2 nach Migration.

### 4.3 `misc/api.func` — Keine Änderungen nötig

Exit-Code-Mapping (`explain_exit_code()`) und `categorize_error()` sind bereits universal (LXC + VM). Nach Merge von PR #11221 stehen 70+ Exit-Codes zur Verfügung. Falls dieser Branch vorher fertig ist, können die Codes aus `feature/smart-error-recovery` cherry-picked werden.

---

## 5. Wichtige Unterschiede LXC vs. VM Recovery

| LXC | VM |
|---|---|
| APT/DPKG In-Place-Repair im Container | **Nicht möglich** — kein Shell-Zugang während Install |
| OOM-Retry mit x2 Ressourcen | **Funktioniert** — `qm set` kann RAM/CPU nachträglich ändern |
| DNS-Override im Container (`/etc/resolv.conf`) | **Nicht anwendbar** — VM hat eigenes Netzwerk |
| Container bleibt erhalten bei Repair | VM muss bei Retry **komplett neu erstellt** werden |
| `build_container()` als zentrale Retry-Schleife | **Neue Wrapper-Funktion nötig** (`vm_create_with_recovery`) |
| `pct exec` für In-Container-Zugriff | Kein Äquivalent (qemu-guest-agent nur wenn VM läuft + Agent installiert) |

---

## 6. Technische Fallstricke

### 6.1 VMID-Cleanup vor Retry

`cleanup_vmid` muss vollständig aufräumen:
- `qm stop "$VMID" --skiplock` (falls Running)
- `qm destroy "$VMID" --destroy-unreferenced-disks --purge`
- Einige Scripts erzeugen zusätzliche Disks (`efidisk0`, `cloudinit`), die extra entfernt werden müssen

### 6.2 Image-Caching

`docker-vm.sh` cached Images in `/var/lib/vz/template/cache/`. Bei Download-Retry:
- **Behalten**, wenn Download vollständig war (md5/sha-Check)
- **Löschen**, wenn Corruption vermutet (curl-Fehler, xz-Validierung fehlgeschlagen)

### 6.3 Cloud-Init-State

Wenn Cloud-Init teilweise konfiguriert wurde, muss bei Retry der gesamte State zurückgesetzt werden:
```bash
qm set "$VMID" --delete cicustom
qm set "$VMID" --delete ciuser
qm set "$VMID" --delete cipassword
```

### 6.4 Legacy-Scripts (14 Stück)

- Definieren `error_handler()` inline und sourcen nur `api.func`
- Um dort Recovery einzubauen, entweder:
  - **Jedes Script einzeln patchen** (hohes Risiko, viel Duplikat)
  - **Erst Migration auf `vm-core.func`** (sauberer, aber größerer Scope)
- **Empfehlung:** Migration priorisieren, Recovery danach trivial

### 6.5 `virt-customize` Fallback

`docker-vm.sh` hat bereits einen First-Boot-Fallback für Docker-Installation. Wenn `virt-customize` fehlschlägt:
- Recovery sollte dies als **"soft failure"** behandeln
- Aktiv den Fallback vorschlagen statt blindes Retry

### 6.6 Kein `pct exec`-Äquivalent

- Man kann **nicht "in die VM hinein reparieren"** wie bei LXC
- `qm guest exec` existiert zwar (mit qemu-guest-agent), funktioniert aber nur wenn:
  - Die VM läuft
  - Der Guest Agent installiert ist
  - Genau das ist typischerweise der Punkt, an dem der Install fehlschlägt

---

## 7. Implementierungsreihenfolge

| Phase | Task | Dateien | Impact |
|---|---|---|---|
| **Phase 1** | `vm_error_handler_with_recovery()` Grundgerüst | `misc/vm-core.func` | Basis für alles |
| **Phase 2** | `docker-vm.sh`: Recovery integrieren | `vm/docker-vm.sh` | 30.1 % der Failures |
| **Phase 3** | Fehlererkennung (Download, Import, virt-customize) | `misc/vm-core.func` | Intelligente dynamische Menüoptionen |
| **Phase 4** | `haos-vm.sh`: Recovery integrieren (Download-Retry) | `vm/haos-vm.sh` | Download-Corruption bereits teilweise vorhanden |
| **Phase 5** | `debian-13-vm.sh` + `ubuntu-*-vm.sh` | `vm/debian-13-vm.sh`, etc. | Cloud-Image-Scripts |
| **Phase 6** | `openwrt-vm.sh` (limitiert — nur Download/Import-Retry) | `vm/openwrt-vm.sh` | `sendkey`-Teil nicht retryable |

---

## 8. Test-Matrix

| Szenario | Erwartetes Verhalten |
|---|---|
| Download-Fehler (curl 6/7/28) | Menü: "Retry Download" + "Cache löschen" |
| Disk-Import-Fehler | Menü: "Retry" + "Anderen Storage wählen" |
| VMID-Konflikt | Menü: "Andere VMID" + "Bestehende VM zerstören" |
| virt-customize-Fehler (docker-vm) | Menü: "Retry" + "First-Boot-Fallback nutzen" |
| Storage voll | Menü: "Anderen Storage wählen" + "Disk verkleinern" |
| Netzwerk-Timeout | Menü: "Retry" + "Abbrechen" |
| 2× Retry erreicht | Nur noch "VM behalten" oder "Abbrechen" |
| User wählt "VM behalten" | VM nicht zerstören, manuellen Zugang erklären |

---

## 9. Branch-Workflow

```bash
# Neuen Branch erstellen (bereits geschehen):
git checkout main
git pull origin main
git checkout -b feature/vm-smart-recovery

# Arbeit in Phasen committen:
# Phase 1: git commit -m "feat(vm): add vm_error_handler_with_recovery to vm-core.func"
# Phase 2: git commit -m "feat(vm): integrate smart recovery into docker-vm.sh"
# etc.

# PR gegen main erstellen (NICHT gegen feature/smart-error-recovery)
```

### Abhängigkeit zu PR #11221

Die `api.func`-Änderungen aus `feature/smart-error-recovery` (70+ Exit-Codes, `categorize_error()`) werden nach Merge von PR #11221 automatisch in `main` verfügbar sein.

- Falls VM-Branch **nach** PR #11221 Merge gestartet wird → alles da
- Falls VM-Branch **vorher** fertig ist → `api.func` Codes aus `feature/smart-error-recovery` cherry-picken

---

## 10. Referenz: Exit-0-Bug (nur LXC, gefixt)

> Dieser Bug betrifft **nur LXC** (`misc/build.func`), nicht die VM-Scripts.

**Root Cause:** Der ERR-Trap in `build.func` rief `ensure_log_on_host` vor `post_update_to_api` auf. Da `ensure_log_on_host` mit Exit 0 returned, wurde `$?` auf 0 zurückgesetzt → Telemetrie meldete "failed/0" statt dem echten Exit-Code (~15-20 Records/Tag).

**Fix (PR #11221, Commit `2d7e707a0`):**
```bash
# Vorher (Bug):
trap 'ensure_log_on_host; post_update_to_api "failed" "$?"' ERR

# Nachher (Fix):
trap '_ERR_CODE=$?; ensure_log_on_host; post_update_to_api "failed" "$_ERR_CODE"' ERR
```

**VM-Scripts nicht betroffen:** Diese erfassen `$?` korrekt als erste Zeile in `error_handler()`:
```bash
function error_handler() {
  local exit_code="$?"  # Erste Zeile → korrekt
  ...
}
```
