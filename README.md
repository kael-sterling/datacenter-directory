# **📘 datacenter-directory**

Declarative identity governance for Active Directory, Exchange-style attributes, shared mailbox departments, cloud profile photo synchronization, and strict group membership enforcement. This repository implements a clean, deterministic identity model using CSV-driven provisioning and a unified configuration system.

The repo contains three major components:

1. **IdentityProvisioning Module** Declarative user and group provisioning for AD DS.
2. **SharedMailboxProvisioning Module** Declarative mailbox provisioning.
3. **Cloud Photo Synchronization** Automated ingestion of user profile photos from Microsoft 365 into AD DS.

All systems follow the same IaC philosophy: identity is code, provisioning is deterministic, and drift is eliminated.

# **🧩 IdentityProvisioning Module**

The `IdentityProvisioning` module provisions and maintains AD DS user and group objects using declarative CSV files and a unified configuration file (`identity.json`). It enforces identity attributes, manages non-identity attributes with governed overwrite rules, generates proxyAddresses across multiple domains, and maintains group membership and nesting.

Key capabilities include:

- Declarative user provisioning from `users.csv`
- Declarative group provisioning from `groups.csv`
- Strict desired-state enforcement for:
    - identity attributes
    - non-identity attributes
    - proxyAddresses
    - manager relationships
    - department/title/company metadata
- Automatic generation of:
    - canonical names
    - mailNicknames
    - proxyAddresses
- Drift detection and correction
- Group nesting enforcement
- Predictable, idempotent execution model

See the module-level README in `IdentityProvisioning/README.md` for full details.

# **📬 SharedMailboxProvisioning Engine**

This directory contains the top-level provisioning workflow for shared mailboxes and mailbox-related directory groups. It includes:

- `Invoke-MailboxProvisioning.ps1` — orchestration wrapper
- `shared_mailboxes.csv` — real desired-state definition
- `shared_mailboxes_example.csv` — fictional example

The engine provisions:

- shared mailboxes
- mailbox metadata (aliases, folders, descriptions)
- mailbox department classification
- mailbox visibility (HideFromGAL)
- mailbox permissions
- strict group membership enforcement

Members are semicolon-separated UPNs.

## **▶️ Invoke-MailboxProvisioning.ps1**

This wrapper:

1. Resolves CSV paths
2. Imports all provisioning scripts from subdirectories
3. Provisions mailboxes and mailbox permission groups
4. Enforces strict group membership
5. Supports DryRun mode

It ensures all provisioning logic runs in a predictable, idempotent order.

### **Example**

```powershell
pwsh ./Run-MailboxProvisioning.ps1 -MailboxesCsvPath ./shared\_mailboxes.csv -DryRun
```

# **🖼️ Cloud Photo Synchronization**

## **`Sync-AllUserPhotosFromCloud.ps1`**

This script synchronizes user profile photos from Microsoft 365 (Graph) into Active Directory, ensuring AD DS always reflects the authoritative cloud profile image.

Capabilities:

- Connects to Microsoft Graph
- Retrieves user profile photos
- Resizes and normalizes images
- Writes photos to AD DS (`thumbnailPhoto`)
- Enforces deterministic overwrite rules
- Supports DryRun mode
- Logs all operations for auditability

This script integrates cleanly with the IdentityProvisioning module, ensuring that identity metadata and identity photos remain consistent across cloud and on-prem environments.

### **Example**

```powershell
pwsh ./Sync-AllUserPhotosFromCloud.ps1 -DryRun
```

# **📄 CSV Files**

## **shared_mailboxes.csv (base/empty)**

This is the **real CSV** used by the provisioning engine. It ships empty:

Code

Name,PrimarySmtp,Aliases,Folders,Description,Department,HideFromGAL,GroupDescription

Users populate this file with their actual mailbox definitions.

This file drives:

- mailbox creation
- mailbox rename detection
- metadata drift correction
- alias enforcement
- folder creation
- group naming conventions

## **shared_mailboxes_example.csv (fictional)**

A fully fictional example demonstrating the correct schema, naming conventions, and metadata fields.

Safe for public repositories.

# **🧠 Philosophy**

`datacenter-directory` treats identity as code.

Every run enforces a deterministic identity model, eliminates drift, and ensures AD DS remains consistent with declarative configuration. The system is:

- Predictable
- Repeatable
- Idempotent
- Auditable
- Easy to extend

This repo is designed to be a homelab-grade identity system built with enterprise IAM principles.

# **✍️ Author**

Created by Kael Sterling @ Untapped Technologies
