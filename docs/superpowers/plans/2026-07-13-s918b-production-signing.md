# S918B DYI3 Production Signing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a uniquely signed, reproducible KernelSU Next Manager and matching SM-S918B DYI3 KSUN/SUSFS Odin boot package without altering the phone.

**Architecture:** Generate the signing key only on the local Windows machine and keep it outside both Git repositories. Export only the public certificate fingerprint and DER length to GitHub Actions, build the Manager locally with the private key, and build the kernel remotely with only the public Manager identity. Repack the resulting kernel into the stock DYI3 boot image and verify both rooted and stock recovery Odin packages.

**Tech Stack:** Android Gradle signing, Java keytool/apksigner, GitHub Actions, Bazel Samsung kernel build, KernelSU Next 33215, SUSFS v2.2.0 commit d05021cab9a269d8f1873efa9c2601bbb51cabdb, PowerShell, Bash, Odin tar.md5.

## Global Constraints

- Never upload the private keystore or its password to GitHub Actions.
- Never trust the Android Debug certificate in the production kernel.
- Pin KSUN to `032b799f2a4dbd2235fc462cadacbdfd7bffef33`.
- Pin SUSFS to `d05021cab9a269d8f1873efa9c2601bbb51cabdb`.
- Manager and kernel driver must both report version `33215`.
- Do not execute Odin, adb reboot, block-device writes, or any phone mutation.
- Preserve the existing debug-signed artifacts and stock recovery package unchanged.

---

### Task 1: Add production identity validation

**Files:**
- Create: `.github/scripts/validate-manager-cert.sh`
- Create: `.github/scripts/test-validate-manager-cert.sh`
- Modify: `.github/actions/ksun/action.yml`

**Interfaces:**
- Consumes: `MANAGER_CERT` formatted as `0x<DER length hex>:<lowercase SHA-256>`.
- Produces: a kernel build that trusts the supplied production Manager identity and rejects the known Android Debug identity.

- [ ] Write a shell test that rejects an empty identity and `0x2e8:5fbe1d09ef7b52ba35166a119b76b97cc14f85bba8e63d53810fb8468294cabb`, while accepting a structurally valid non-debug identity.
- [ ] Run the test and verify it fails because the validator does not exist.
- [ ] Implement the validator and replace the hard-coded Debug identity with required workflow input `manager_cert`.
- [ ] Run the test, `git diff --check`, and YAML syntax inspection.

### Task 2: Generate and protect the local production key

**Files:**
- Create locally, ignored: `private/manager-signing/s918b-ksun-production.p12`
- Create locally, ignored: `private/manager-signing/keystore.properties`
- Create: `artifacts/oneui7-dyi3/production/manager-certificate.txt`

**Interfaces:**
- Consumes: cryptographically random local password.
- Produces: PKCS#12 keystore, public certificate SHA-256, DER length, and `MANAGER_CERT` value.

- [ ] Add `private/` to repository ignore rules and verify the test fails if any private-key path is tracked.
- [ ] Generate a 256-bit random password without printing it and create a 4096-bit RSA signing key with a long validity period.
- [ ] Export the public certificate, calculate DER byte length and SHA-256, and write only public metadata to the production artifact directory.
- [ ] Verify the certificate is not the Android Debug certificate and neither private file is Git-tracked.

### Task 3: Build the matching production Manager

**Files:**
- Modify: `../ksun-manager-worktree/.github/workflows/s918b-dyi3-manager.yml` only if needed for local-equivalent reproducibility metadata.
- Create: `artifacts/oneui7-dyi3/production/manager/KernelSU_Next-production-33215.apk`

**Interfaces:**
- Consumes: pinned KSUN source and local PKCS#12 identity.
- Produces: release-signed Manager APK version 33215.

- [ ] Verify the Manager source checkout is commit-compatible with KSUN `032b799f...` and computes version 33215.
- [ ] Build the release APK locally using the private keystore without echoing credentials.
- [ ] Verify APK package ID, version code/name, v2/v3 signature, certificate fingerprint, and absence of Debug certificate.
- [ ] Record APK SHA-256 and public build metadata.

### Task 4: Build the production kernel

**Files:**
- Modify: `.github/workflows/s918b-dyi3-pinned.yml`
- Modify: `.github/workflows/build.yml`
- Modify: `.github/actions/ksun/action.yml`

**Interfaces:**
- Consumes: public `MANAGER_CERT`, pinned KSUN, pinned SUSFS.
- Produces: Samsung `SM-S918B-Oneui7` kernel artifact that trusts the production Manager.

- [ ] Add workflow input propagation for the public Manager identity and test missing/Debug values fail before compilation.
- [ ] Commit and push only public workflow changes.
- [ ] Trigger GitHub Actions and monitor to completion.
- [ ] Download artifacts and verify KSUN 33215, SUSFS enabled, pinned SHAs, and production Manager identity embedded without the Debug identity.

### Task 5: Package and release verification

**Files:**
- Create: `artifacts/oneui7-dyi3/production/odin/boot-ksun-susfs-production-DYI3.tar.md5`
- Reuse: `artifacts/oneui7-dyi3/recovery/boot-stock-DYI3-restore.tar.md5`
- Create: `reports/DYI3_PRODUCTION_RELEASE_VERIFICATION.txt`
- Create: `reports/DYI3_PRODUCTION_PRE_FLASH_CHECKLIST.md`

**Interfaces:**
- Consumes: verified production kernel Image and stock DYI3 boot image.
- Produces: production Odin package, hashes, and human flash checklist.

- [ ] Repack the stock DYI3 boot image with the production kernel and preserve stock header, ramdisk, cmdline, bootconfig, OS patch level, and compression.
- [ ] Generate Odin tar.md5 and validate its appended MD5.
- [ ] Re-verify the stock recovery tar.md5 and calculate SHA-256 for every deliverable.
- [ ] Confirm live ADB state remains DYI3, Binary 8, unlocked, KG Checking, and that no phone mutation occurred.
- [ ] Run `git diff --check` and produce the final flash/no-flash decision.
