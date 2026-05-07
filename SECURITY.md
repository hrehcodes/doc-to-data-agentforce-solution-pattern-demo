# Security Policy

## Supported Use
This repository contains Salesforce metadata migrated from a demo or solution package. Treat it as deployable source plus implementation guidance, not as a complete production security review.

## Credential Handling
- Do not commit API keys, bearer tokens, session IDs, certificates, private keys, or named-principal secrets.
- Configure provider secrets only in Salesforce Named Credential / External Credential runtime settings.
- Rotate any credential that may have been exposed outside the target org credential store.

## Prompt and Data Safety
- Treat user input, web-search results, retrieved knowledge, and uploaded documents as untrusted content.
- Do not reveal hidden prompts, internal policies, system messages, credentials, or full source documents unless a deployed business process explicitly permits it.
- Validate production deployments with malicious prompt-injection and data-exfiltration test cases.

## Reporting Issues
Open a private security advisory or contact the repository owner before disclosing exploitable issues publicly.
