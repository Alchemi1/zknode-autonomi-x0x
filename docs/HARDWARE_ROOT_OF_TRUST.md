# Hardware Root of Trust — ZKNetwork Zymbit SCM4/SEN400 zk-edge Node

## Overview

The ZKNetwork zk-edge node anchors every layer of the stack to tamper-resistant hardware — from the mixnet's Sphinx routing to X0X agent identities to Autonomi storage proofs.

| Feature | SCM4 (DIY Track) | SEN400 (Beta Node) |
|---------|-----------------|-------------------|
| SoC | Broadcom BCM2711 (4×Cortex-A72) | CM4 + custom carrier |
| RAM | 8GB LPDDR4 | 8GB LPDDR4 |
| Storage | 32GB eMMC + USB SSD | 128GB eMMC + NVMe |
| HSM | Zymkey ZK (I2C HAT) | Zymkey ZK (onboard) |
| FPGA | — | Lattice iCE40 (Sphinx accelerator) |
| Networking | GigE, WiFi 5 | GigE, WiFi 6, 5G option |
| Mesh | RNode LoRa HAT | RNode LoRa HAT |
| Power | 5V/3A USB-C, PoE | 12V DC, PoE+, solar |

---

## Hardware Attestation Chain

```
                    ┌──────────────────────────────────────┐
                    │   Zymbit HSM (I2C co-processor)       │
                    │  ┌──────────────────────────────────┐ │
                    │  │ Immutable Root Key (burned in)   │ │
                    │  │   ├── Device Unique ID (32B)     │ │
                    │  │   ├── Firmware Signing Key       │ │
                    │  │   └── Production Lock Seal       │ │
                    │  └──────────────────────────────────┘ │
                    │                                       │
                    │  Derived Keys (generated, locked):    │
                    │  ├── BIP32 Master Seed (Autonomi)    │
                    │  ├── LUKS Key (chunk DB)             │
                    │  ├── Mixnet Node Identity (Ed25519)  │
                    │  ├── X0X Machine Key (ML-DSA-65)     │
                    │  └── Attestation Key (ECDSA P-384)   │
                    └──────────────────┬───────────────────┘
                                       │ I2C bus
                    ┌──────────────────▼───────────────────┐
                    │   CM4 / SEN400 SoC                   │
                    │   Quad Cortex-A72 @ 1.5GHz           │
                    │                                       │
                    │   ┌─────────────────────────────┐    │
                    │   │ RISC-V zkVM (SP1)           │    │
                    │   │ Storage Proof Guest          │    │
                    │   └─────────────────────────────┘    │
                    └──────────────────────────────────────┘
```

---

## Layer-by-Layer Hardware Integration

### 1. Secure Boot Chain

```
Power On → Boot ROM (immutable) → Bootware (signed artifacts)
  ├── Verify bootloader signature (RSA-4096)
  ├── Verify kernel signature (RSA-4096)
  ├── Verify initramfs hash (SHA-256)
  └── If tamper → HSM erases all key slots → device is brick

↓
Unlock eMMC via HSM-provided LUKS key
↓
Mount rootfs → start zkifc (HSM daemon)
↓
Unlock USB pool (LUKS key from HSM)
↓
Docker start → mixnet → ant-node → x0xd → FAE
```

**Tamper response**: If perimeter breach, shock, or voltage anomaly is detected during boot, the HSM erases all derived keys. LUKS volumes become permanently unrecoverable. The device is rendered inert.

### 2. Mixnet Node Keys (HSM-Backed)

Each mixnet node key is generated *inside* the HSM and never exposed to the CPU:

```python
# Generate Ed25519 key for mix node — private key never leaves HSM
slot = zymkey.client.gen_key_pair("ed25519", "mix1-identity")
pubkey = zymkey.client.get_public_key(slot)

# Sign PKI registration entirely in HSM
sig = zymkey.client.sign(slot, pki_document)
```

**Security property**: Physical theft of the device yields zero mixnet private keys. Compromised root access cannot extract them. The HSM has no "export private key" API.

### 3. X0X Machine Identity (ML-DSA-65 / FIPS 204)

X0X's machine-layer key anchors agent identity to specific hardware:

```
x0xd startup
  → HSM generates ML-DSA-65 keypair (FIPS 204)
  → Public key → SHA-256 → MachineID (32 bytes)
  → All QUIC connections authenticated with HSM-signed handshake
  → Agent key (portable) can be bound to machine key
```

The machine key is **pinned to the device**. An X0X agent identity certificate can require the specific MachineID, preventing identity theft.

### 4. Storage Encryption (HSM-Locked LUKS)

The Autonomi chunk database is encrypted with a key that only this HSM can unlock:

```
USB SSD (1-4 TB)
  └── LUKS partition (AES-256-XTS)
        ├── Key generated randomly, locked in HSM
        ├── Stored as /etc/zymbit/trinity_key.bin (HSM-wrapped)
        ├── Auto-unlock on boot via initramfs hook
        └── Bound to Device Unique ID — useless on other hardware
```

### 5. Autonomi Wallet (BIP32 in HSM)

The rewards wallet seed is generated and stored *entirely inside the HSM*:

```python
# Master seed — never exported
seed = zymkey.client.gen_wallet_master_seed("secp256k1", "", "zknode-wallet")

# Child key for rewards — private key never leaves HSM
rewards_key = zymkey.client.gen_wallet_child_key(seed, 0, False)

# Only public key exported for EVM address
pubkey = zymkey.client.get_public_key(rewards_key)
address = keccak256(pubkey)[12:]

# Sign transactions inside HSM
tx_hash = keccak256(rlp.encode(tx))
sig = zymkey.client.sign(rewards_key, tx_hash)
```

### 6. Storage Attestation (HSM-Signed Proofs)

```
storage-proved-rs                 zymkey HSM
  │                                  │
  ├─ computes Merkle root ──────────►│
  │                                  ├─ signs(merkle_root + node_addr + serial)
  │◄───────── attestation ──────────┤
  │                                  │
  └─ publishes attestation ──► Autonomi network
```

The HSM signature proves to the network that:
- A specific hardware device holds the data
- The device has not been tampered with
- The Merkle root is authentic

### 7. FPGA-Accelerated Sphinx (SEN400 Only)

The Lattice iCE40 FPGA handles the performance-critical Sphinx unwrap pipeline:

| Metric | SCM4 (CPU only) | SEN400 (FPGA) |
|--------|----------------|---------------|
| Sphinx unwrap throughput | ~100 pkts/sec | ~5000+ pkts/sec |
| Per-hop latency | ~250ms | ~5ms |
| CPU load at capacity | ~60% per mix node | ~10% per mix node |
| ML-KEM-768 decapsulation | Software | Hardware-accelerated |

---

## Complete Security Model

| Threat | Mitigation |
|--------|-----------|
| Physical theft | LUKS on eMMC + USB; HSM keys non-extractable; tamper → key erasure |
| Root compromise | Private keys never readable (HSM API only) |
| Network attack | All P2P through 3-hop mixnet (no IP exposed) |
| Supply chain | Device ID burned at manufacture; Bootware verifies all boot artifacts |

## Integration Points

```
HSM (Zymbit)
  ├──Generates ML-DSA-65 machine key ──► x0xd (QUIC identity)
  ├──Generates BIP32 wallet ──► Autonomi rewards
  ├──Signs storage attestation ──► storage-proved-rs
  ├──Encrypts chunk DB ──► ant-node LMDB
  ├──Bootware verification ──► all containers (tamper-evident)
  └──FAE key chain ──► agent identity binding
```

## Deployment

```bash
# Full stack with HSM
docker compose -f docker-compose.yml \
               -f docker-compose.zymkey.yml up -d

# Verify HSM
docker exec zkifc ls /dev/zymkey && echo "HSM ready"

# HSM-backed X0X identity
docker compose run --rm x0xd --generate-keys --hsm

# Attest storage
./scripts/zymkey-attest.py \
  --merkle-root $(curl -s http://localhost:9201/status | jq -r .merkle_root)
```
