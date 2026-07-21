# **📦 SharedMailboxProvisioning Module**

Declarative provisioning and drift‑correction for Exchange Online shared mailboxes

## **📘 Overview**

**SharedMailboxProvisioning** is a declarative PowerShell module that provisions and maintains Exchange Online shared mailboxes using a CSV definition file and a JSON configuration file.

It ensures that each mailbox's:

- existence
- display name
- aliases
- folders
- visibility
- description
- department
- manager
- regional settings
- auto‑reply configuration
- permissions (FullAccess, SendAs, SendOnBehalf)

matches the desired state defined in the CSV.

The module supports:

- **add‑only** permission assignment
- **strict enforcement** (add \+ remove)
- **rename drift correction**
- **alias expansion across multiple domains**
- **UPN resolution from sAMAccountName**
- **dry‑run mode** for safe previewing

It is designed to be predictable, testable, and maintainable — following the same architectural patterns as your IdentityProvisioning module.

## **📁 Folder Structure**

Code

SharedMailboxProvisioning/

│

├── Public/

│ ├── Enforce-MailboxPermissions.ps1

│ ├── Import-MailboxCsv.ps1

│ ├── Invoke-SharedMailboxProvisioning.ps1

│ ├── New-SharedMailbox.ps1

│ ├── Set-MailboxAliases.ps1

│ ├── Set-MailboxAutoReply.ps1

│ ├── Set-MailboxDepartment.ps1

│ ├── Set-MailboxDescription.ps1

│ ├── Set-MailboxFolders.ps1

│ ├── Set-MailboxManager.ps1

│ ├── Set-MailboxPermissions.ps1

│ ├── Set-MailboxRegionalSettings.ps1

│ ├── Set-MailboxVisibility.ps1

│

├── Private/

│ ├── Load-MailboxConfig.ps1

│ ├── Normalize-MailboxRecord.ps1

│ ├── Split-SemicolonList.ps1

│ ├── Expand-Aliases.ps1

│ ├── Connect-EXO.ps1

│ ├── Connect-Graph.ps1

│ ├── Write-RenameLog.ps1

│ ├── Internal-Helpers.ps1

│

├── shared_mailboxes.csv

└── mailbox_config.json

## **📑 CSV Schema**

The CSV defines the desired state for each mailbox. All identities (Manager, FullAccess, SendAs, SendOnBehalf) are **sAMAccountNames**, resolved to UPNs using the primary domain.

### **Columns**

|        Column        | Description                                                           |
| :------------------: | --------------------------------------------------------------------- |
|       **Name**       | Local mailbox name (PrimarySMTP \= `name@PrimaryDomain`)              |
|   **HideFromGAL**    | True/False                                                            |
|     **Aliases**      | Semicolon‑delimited alias local parts (expanded across alias domains) |
|     **Folders**      | Semicolon‑delimited Inbox subfolders                                  |
|   **Description**    | CustomAttribute1 value                                                |
|    **Department**    | Department string (e.g., IT, Security, FIN)                           |
|     **Manager**      | sAMAccountName of manager (resolved to UPN)                           |
| **FullAccessUsers**  | Semicolon‑delimited sAMAccountNames                                   |
|   **SendAsUsers**    | Semicolon‑delimited sAMAccountNames                                   |
|   **SendOnBehalf**   | Semicolon‑delimited sAMAccountNames                                   |
| **AutoReplyEnabled** | True/False                                                            |
|  **InternalReply**   | Internal auto‑reply message                                           |
|  **ExternalReply**   | External auto‑reply message                                           |
| **ExternalAudience** | None / Known / All                                                    |

### **Example (current version)**

csv

Name,HideFromGAL,Aliases,Folders,Description,Department,Manager,FullAccessUsers,SendAsUsers,SendOnBehalf,AutoReplyEnabled,InternalReply,ExternalReply,ExternalAudience

IT,False,"it","Alerts;Systems;Vendors;Automation;Archive;Processed;To Review","IT operations mailbox","IT","kael","kael","kael","kael",False,"","",""

Security,False,"security","Incidents;Investigations;Reports;Archive;Processed;To Review","Security alerts and investigations","Security","kael","kael","kael","kael",False,"","",""

Support,False,"support","Tickets;Resolved;Escalations;Archive;Processed;To Review","Customer support communications","Support","kael","kael","kael","kael",False,"","",""

Info,False,"info","Archive;Processed;To Review","General inquiries and information","Information","kael","kael","kael","kael",False,"","",""

Sales,False,"sales","Archive;Processed;To Review","Sales inquiries and communications","FIN","kael","kael;tobias","kael;tobias","kael;tobias",False,"","",""

HR,False,"hr","Onboarding;Offboarding;Benefits;Policies;Archive;Processed;To Review","Human resources communications","FIN","kael","kael;tobias","kael;tobias","kael;tobias",False,"","",""

Billing,False,"billing","Invoices;Receipts;Vendors;Archive;Processed;To Review","Billing and financial correspondence","FIN","kael","kael;tobias","kael;tobias","kael;tobias",False,"","",""

Accounting,False,"accounting","Invoices;Receipts;Vendors;Archive;Processed;To Review","Accounting and financial operations","FIN","kael","kael;tobias","kael;tobias","kael;tobias",False,"","",""

Legal,False,"legal","Cases;Contracts;Policies;Archive;Processed;To Review","Legal case and contract management","Legal","kael","kael","kael","kael",False,"","",""

No-Reply,True,"noreply;no-reply","","Automated outbound-only mailbox","Automation","","","","",False,"","",""

Automation,True,"automation","","System automation tasks and notifications","Automation","kael","kael","kael","kael",False,"","",""

## **⚙️ Config Schema (mailbox_config.json)**

json

{

"PrimaryDomain": "untapped.tech",

"AliasDomains": \[

    "untappedtechnologies.com",

    "untappedhq.com"

\],

"DefaultLanguage": "en-US",

"DefaultTimeZone": "Eastern Standard Time"

}

## **🔧 Function Responsibilities (Public)**

### **Enforce-MailboxPermissions**

Strict drift enforcement for FullAccess, SendAs, SendOnBehalf.

### **Import-MailboxCsv**

Loads CSV \+ config, normalizes mailbox objects.

### **Invoke-SharedMailboxProvisioning**

Orchestrates the entire provisioning pipeline.

### **New-SharedMailbox**

Creates mailboxes and corrects rename drift.

### **Set-MailboxAliases**

Adds missing aliases.

### **Set-MailboxAutoReply**

Enables, disables, or clears auto‑reply configuration.

### **Set-MailboxDepartment**

Sets AAD Department via Graph.

### **Set-MailboxDescription**

Sets CustomAttribute1.

### **Set-MailboxFolders**

Creates Inbox subfolders.

### **Set-MailboxManager**

Sets AAD Manager via Graph.

### **Set-MailboxPermissions**

Add‑only permissions for FullAccess, SendAs, SendOnBehalf.

### **Set-MailboxRegionalSettings**

Applies language \+ timezone.

### **Set-MailboxVisibility**

Applies HideFromGAL.

## **🔄 Provisioning Pipeline**

The pipeline executed by `Invoke-SharedMailboxProvisioning`:

1. **Import CSV \+ config**
2. **Normalize mailbox records**
3. **Create or rename mailboxes**
4. **Apply metadata**
    - Visibility
    - Description
    - Department
    - Manager
    - Regional settings
5. **Apply mailbox structure**
    - Aliases
    - Folders
6. **Apply auto‑reply configuration**
7. **Apply permissions**
8. **Optionally enforce permissions (drift correction)**

## **🧪 Dry Run Mode**

All public functions support:

Code

\-DryRun

This prints intended actions without making changes.

## **🚀 Usage**

### **Basic provisioning**

powershell

Invoke-SharedMailboxProvisioning \-MailboxesCsvPath ".\\shared_mailboxes.csv"

### **Dry run**

powershell

Invoke-SharedMailboxProvisioning \-MailboxesCsvPath ".\\shared_mailboxes.csv" \-DryRun

### **Enforce permissions**

powershell

Invoke-SharedMailboxProvisioning \-MailboxesCsvPath ".\\shared_mailboxes.csv" \-EnforcePermissions

## **🧱 Design Principles**

- Declarative desired state
- Idempotent operations
- Drift detection and correction
- Explicit public API
- UPN resolution from sAMAccountName
- Separation of concerns (one responsibility per function)
- Consistent with IdentityProvisioning architecture

## **📜 License**

Internal automation module — no external license.
