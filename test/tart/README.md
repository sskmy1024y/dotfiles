# Tart-based macOS Test Environment

Trial-and-error harness for fixing the dotfiles installer on **real** macOS.
Uses [Tart](https://tart.run/) to spin up clean macOS VMs from a vanilla base
image, so each test starts from a guaranteed fresh state — no `git`, no
`brew`, no leftover symlinks from the previous run.

> **Note:** This complements (does not replace) the Docker-based smoke test
> in `test/docker/Dockerfile.macos`, which is just Ubuntu with
> `OSTYPE=darwin`. Tart is the source of truth for real macOS behavior.

---

## Requirements

| Tool | Why | Install |
|---|---|---|
| Apple Silicon Mac (M1+) | Tart only runs on arm64 macOS | — |
| Tart | macOS VM runtime | `brew install cirruslabs/cli/tart` |
| sshpass | Non-interactive SSH into VM | `brew install hudochenkov/sshpass/sshpass` |
| rsync | Push local repo to VM | preinstalled on macOS |
| Disk space | Vanilla image ≈ 40 GB; each clone is COW so only the diff costs | — |
| First-time download | ~30–60 min depending on your connection | — |

Sanity check:

```sh
make -C test/tart check
```

---

## Quick start

```sh
# 1. First-time only: pull vanilla image and create the long-lived base VM
make test-mac-tart-prepare

# 2. Reproduce the curl one-liner problem on real macOS
make test-mac-tart-oneliner

# 3. Reproduce the "git not installed" problem
make test-mac-tart-git

# 4. Run the full pipeline (deploy + init + deep)
make test-mac-tart-full

# 5. Interactive debugging — drop into SSH on a fresh VM
make test-mac-tart-shell

# 6. Clean up ephemeral VMs (base stays)
make test-mac-tart-clean
```

All `test-mac-tart-*` Makefile targets at the repo root forward to
`test/tart/Makefile`. You can also invoke that Makefile directly:

```sh
make -C test/tart oneliner
make -C test/tart shell
make -C test/tart clean
```

---

## How it works

```
test/tart/
├── README.md         (this file)
├── Makefile          convenience targets
├── lib/
│   └── tart-helpers.sh   shared bash functions
├── bin/
│   ├── tart-prepare      pull image, create base VM        (one-time)
│   ├── tart-snapshot     clone base -> ephemeral test VM   (per run)
│   ├── tart-run          boot VM, run a scenario, cleanup  (per run)
│   └── tart-destroy      bulk-delete ephemeral VMs         (housekeeping)
└── scenarios/
    ├── 01-oneliner-remote.sh   curl ... | bash
    ├── 02-git-clone-local.sh   rsync local repo + make install
    └── 03-full-install.sh      deploy + init + deep
```

`tart-run` always:

1. Clones a fresh ephemeral VM from `dotfiles-base`
2. Boots it headless (`tart run --no-graphics`)
3. Waits for SSH (timeout `TART_SSH_TIMEOUT`, default 300s)
4. Sources the scenario script
5. **Destroys the VM on exit**, even if the scenario errored
   (override with `--keep`)

Scenario scripts get these variables pre-set:

| Variable | Meaning |
|---|---|
| `VM_NAME` | Ephemeral VM name |
| `VM_IP` | VM IP address |
| `REPO_ROOT` | Host-side path of this dotfiles repo |
| `TART_SSH_USER` / `TART_SSH_PASS` | Default `admin` / `admin` |

…and these helper functions: `info`, `warn`, `error`, `step`, `log`,
`vm_exec`, `vm_push`.

---

## Iterating on the install scripts

The typical loop while fixing the installer:

```sh
# 0. (once) prepare the base VM
make test-mac-tart-prepare

# 1. edit etc/scripts/... on the host

# 2. push & test (rsync handles incremental copy)
make test-mac-tart-git           # uses YOUR local copy of the repo

# 3. if it fails, drop into the same kind of VM and poke around
make test-mac-tart-shell

# 4. repeat from step 1
```

`make test-mac-tart-git` and `make test-mac-tart-full` rsync your working
tree (including uncommitted changes) into the VM, so you do not need to
push to GitHub between iterations.

`make test-mac-tart-oneliner` always tests the **published** master branch
(the URL is hardcoded to `raw.githubusercontent.com/sskmy1024y/dotfiles/master`).
That scenario only becomes meaningful once your fix is committed and pushed.

---

## Keeping a VM around for inspection

```sh
make -C test/tart keep-git-clone   # VM survives the run
tart list                          # find its name (dotfiles-test-...)
tart ip <name>                     # get its IP
sshpass -p admin ssh admin@<ip>    # log in

# When done:
make test-mac-tart-clean           # nukes every dotfiles-test-* VM
```

---

## Configuration knobs

All overridable via environment variables before invoking `make`:

| Variable | Default | Notes |
|---|---|---|
| `TART_BASE_IMAGE` | `ghcr.io/cirruslabs/macos-sequoia-vanilla:latest` | Use a different macOS version or your own image |
| `TART_BASE_VM` | `dotfiles-base` | Local name for the base VM |
| `TART_TEST_VM_PREFIX` | `dotfiles-test` | Ephemeral VMs get `<prefix>-<timestamp>-<pid>` |
| `TART_SSH_USER` / `TART_SSH_PASS` | `admin` / `admin` | Cirrus vanilla image defaults |
| `TART_SSH_TIMEOUT` | `300` | Seconds to wait for VM SSH on first boot |
| `ONELINER_URL` | `https://raw.githubusercontent.com/sskmy1024y/dotfiles/master/etc/setup` | Override to test a fork/branch |

Example:

```sh
ONELINER_URL=https://raw.githubusercontent.com/sskmy1024y/dotfiles/feat/fix-install/etc/setup \
  make test-mac-tart-oneliner
```

---

## Troubleshooting

**`tart pull` is extremely slow / stalls**
The vanilla image is ~40 GB. There is no resume on interruption; let it
run on a stable connection. Once `dotfiles-base` exists you never need to
pull again unless you `--force`.

**`Timed out waiting for VM SSH`**
First boot of a brand-new macOS install can take longer than the default
300 s. Re-run with `TART_SSH_TIMEOUT=900`.

**`VM 'dotfiles-base' is missing`**
Run `make test-mac-tart-prepare` first.

**`sshpass: not found`**
`brew install hudochenkov/sshpass/sshpass` (the original `sshpass` is not
in the default Homebrew tap).

**A previous run left VMs behind**
`make test-mac-tart-clean` removes every `dotfiles-test-*` VM. `tart list`
shows what is currently on disk.

**I want to start completely over**
`make test-mac-tart-clean-all` removes ephemeral VMs AND the base VM.
You will need `prepare` again afterwards.

---

## Out of scope here

- CI integration via a self-hosted ephemeral runner
  (planned: `cirruslabs/macos-runner` pattern, separate workflow)
- Fixing the install scripts themselves — this directory only provides
  the test bed. Use it while editing `etc/scripts/...`.

---

## Why not just use `macos-latest` runners?

GitHub-hosted `macos-latest` already has `brew`, `git`, `curl`, Xcode CLT,
and a populated `PATH`. That hides the very failures we are trying to
catch (missing `git`, missing `curl`, broken bootstrap). Tart gives us a
true "I just bought this Mac" baseline.
