# Doc-to-Data Agentforce Solution Pattern Demo

A Vendor Contract Intake demo that turns uploaded contract documents into structured Contract Intake records, risk analysis, negotiation tips, and question-answering actions.

This repository contains the Salesforce DX source retrieved from the `Doc-to-Data Agentforce Solution Pattern Demo` unmanaged 1GP package hosted in the `pamigration` org. It is intended to be deployable as source-controlled metadata and to serve as implementation documentation for the solution.

## Solution Highlights
- Creates the Contract_Intake__c data model, app, tabs, quick actions, flexipages, and flows.
- Uses Prompt Builder templates to extract contract fields, analyze risk, answer contract questions, and produce negotiation tips.
- Includes Apex parsers for prompt JSON outputs and an account matching helper.

## Architecture
Typical execution path:

1. An Agentforce action or topic receives a user request.
2. The action invokes a Flow, Prompt Builder template, or Apex invocable target.
3. Supporting Apex, Prompt Builder templates, and Salesforce metadata perform the callout, extraction, generation, formatting, or record update.
4. The result is returned to Agentforce or stored in Salesforce records for follow-up work.

## Metadata Inventory
- GenAiFunctions: `Answer_Contract_Question_or_Perform_Task`
- Prompt templates: `VCR_Analyze_Contract_Risk`, `VCR_Answer_Contract_Question`, `VCR_Extract_Contract_Fields`, `VCR_Negotiation_Tips`
- Flows: `Answer_Contract_Question_or_Perform_Task`, `New_Contract_Intake_Automated_Analysis`, `New_Contract_Intake_Upload`
- Apex classes: `VCR_AccountMatch`, `VCR_ParseAnalysisJson`, `VCR_ParseExtractJson`
- Custom objects: `Contract_Intake__c`
- Applications: `Vendor_Contract_Intake`
- Tabs: `Contract_Intake__c`, `New_Vendor_Contract`
- Flexipages: `Contract_Intake_Record_Page`, `New_Vendor_Contract`, `Vendor_Contract_Intake_UtilityBar`
- Layouts: `Contract_Intake__c-Contract Intake Layout`
- Quick actions: `Contract_Intake__c.New_Contract_Intake`, `VCR_Demo_New_Task`
- Notifications: `VCR_Complete_Notification`
- Content assets: `Vendor_Contract_Intake_image`

## Agentforce Actions and Topics
- `Answer_Contract_Question_or_Perform_Task` -> `Answer_Contract_Question_or_Perform_Task` (flow) - This is the flow that handles a user's task or question about a contract intake. The end user asks a question or asks for a task to be performed and the record ID and user query are handled by the flow and then the answer is brought back to Agentforce to handle.

## Flows
- `Answer_Contract_Question_or_Perform_Task` (Answer Contract Question or Perform Task) status `Active` type `AutoLaunchedFlow` - This is the flow that handles a user's task or question about a contract intake. The end user asks a question or asks for a task to be performed and the record ID and user query are handled by the flow and then the answer is brought back to Agentforce to handle. Key actions: Answer Contract Question or Perform Contract Task (generatePromptResponse: VCR_Answer_Contract_Question).
- `New_Contract_Intake_Automated_Analysis` (New Contract Intake (Automated Analysis)) status `Active` type `AutoLaunchedFlow` - The automatic analysis and hydration of a contract intake record. Key actions: Contract Risk Analysis (generatePromptResponse: VCR_Analyze_Contract_Risk), Extract Key Contract Fields (generatePromptResponse: VCR_Extract_Contract_Fields), Find or Create Account (apex: VCR_AccountMatch), Generate Negotiation Tips (generatePromptResponse: VCR_Negotiation_Tips), Parse JSON Response (apex: VCR_ParseExtractJson), Parse JSON Risk Response (apex: VCR_ParseAnalysisJson).
- `New_Contract_Intake_Upload` (New Contract Intake (Upload)) status `Active` type `Flow` - Creates Contract Intake, then uploads a pdf to it.

## Prompt Templates
- `VCR_Analyze_Contract_Risk` - Analyzes the risks according to rules set by the firm for the given contract. (1 version(s); statuses: Published; inputs: `Input_Contract`)
- `VCR_Answer_Contract_Question` - Prompt template that answers questions about the given contract. (3 version(s); statuses: Published; inputs: `Input_Contract`, `User_Question`)
- `VCR_Extract_Contract_Fields` - Extract the key fields for the input contract. (3 version(s); statuses: Published; inputs: `Input_Contract`)
- `VCR_Negotiation_Tips` (1 version(s); statuses: Published; inputs: `Input_Contract`)

## Apex
Apex runtime classes: `VCR_AccountMatch`, `VCR_ParseAnalysisJson`, `VCR_ParseExtractJson`

Apex test classes: None

Invocable methods and key callouts:
- VCR_AccountMatch: VCR Find or Create Account
- VCR_ParseAnalysisJson: Parse VCR Analysis JSON - Deserializes analyzer JSON to typed Flow outputs
- VCR_ParseExtractJson: Parse VCR Extract JSON - Deserializes extractor JSON to typed Flow outputs

## Data Model and UI
- `Contract_Intake__c` (Contract Intake) with fields: `Account__c (Account, Lookup)`, `Auto_Renew_Period_Months__c (Auto Renew Period (Months), Number)`, `Auto_Renew__c (Auto Renew, Checkbox)`, `Contract_Title__c (Contract Title, Text)`, `Contract_Value__c (Contract Value, Currency)`, `Currency_Code__c (Currency Code, Text)`, `Data_Processing_DPA_Required__c (Data Processing (DPA) Required?, Checkbox)`, `Indemnity_Present__c (Indemnity Present, Checkbox)`, `Liability_Cap_Text__c (Liability Cap (Text), Text)`, `Lowest_Confidence_0100__c (Lowest Confidence (0-100), Number)`, `Needs_Review__c (Needs Review, Checkbox)`, `Negotiation_Tips__c (Negotiation Tips, Html)`, and 10 more. List views: `All`
- Applications: `Vendor_Contract_Intake`
- Tabs: `Contract_Intake__c`, `New_Vendor_Contract`
- Flexipages: `Contract_Intake_Record_Page`, `New_Vendor_Contract`, `Vendor_Contract_Intake_UtilityBar`
- Layouts: `Contract_Intake__c-Contract Intake Layout`
- Quick actions: `Contract_Intake__c.New_Contract_Intake`, `VCR_Demo_New_Task`
- Notifications: `VCR_Complete_Notification`
- Content assets: `Vendor_Contract_Intake_image`

## Integrations and Credentials
- None retrieved.

No credential secret values were included in the retrieved metadata. Any API keys or named-principal secrets must be configured in the target org after deployment.

## Prerequisites
- Salesforce org with Metadata API support and Salesforce CLI access.
- Agentforce and Prompt Builder features enabled for metadata that uses GenAiFunction, GenAiPlugin, or GenAiPromptTemplate.
- Permission to deploy Apex, Flow, Prompt Builder, Named Credential, External Credential, and custom object metadata as applicable.
- Access to any external API provider used by this package.

## Deployment
Authenticate to the target org, then validate first:

```bash
sf org login web --alias <target-org>
sf project deploy start --dry-run --manifest manifest/package.xml --target-org <target-org> --wait 30
```

Deploy after the dry run succeeds:

```bash
sf project deploy start --manifest manifest/package.xml --target-org <target-org> --wait 30
```

## Post-Deploy Setup
- Assign object, tab, and app access for users who will run contract intake.
- Review and publish the included prompt templates in the target org if deployment leaves them in draft.
- Activate or verify the New Contract Intake flows after deployment.
- Test with a non-sensitive sample contract file before using real vendor contracts.

## Testing and Validation
- Run a metadata dry run before deploying to a shared org.
- Run Apex tests listed above when present.
- Open each Flow in Flow Builder and confirm it is active or activate it after reviewing org-specific references.
- Open Prompt Builder templates and confirm the expected published version, model, and inputs.
- Test the Agentforce action with a low-risk sample prompt before giving it to end users.

## Package Provenance
- Source package: `Doc-to-Data Agentforce Solution Pattern Demo`
- MetadataPackageId: `033Hn000000hPWcIAM`
- Retrieved from org alias: `pamigration`
- Package versions observed: `1.0.0 Beta (Fall 2025)`, `1.1.0 Beta (Fall 2025)`
- Repository name: `doc-to-data-agentforce-solution-pattern-demo`

## Notes for Maintainers
- Keep generated secrets, local org auth files, `.sf`, `.sfdx`, and deployment output out of source control.
- Treat prompt templates and Agentforce action descriptions as production behavior, not just documentation.
- For production hardening, prefer Named Credential and External Credential patterns over passing API keys directly through Flow variables.

## Hardening Update
Security and reliability improvements applied after migration:
- Removed the org-specific Lightning URL from the upload Flow and replaced it with a relative record link.
- Prompt templates now treat uploaded contract text as untrusted content.
- Apex account matching now checks baseline Account read/create access before querying or creating Accounts.

## Known Limitations
- Review Contract_Intake__c sharing, field classifications, and FLS before storing real contracts.
- Flow fault handling and human-review routing should be tailored for each deployment.

## Test Commands
Validate metadata and run relevant tests after authenticating to a target org:

```bash
sf project deploy start --dry-run --manifest manifest/package.xml --target-org <target-org> --wait 30
sf apex run test --class-names VCR_Hardening_Test --target-org <target-org> --result-format human --wait 10
```

## Troubleshooting
- If an Agentforce action cannot authenticate, confirm the named principal secret is configured in the target org and the running user has the included permission set.
- If a prompt action returns unsupported or unsafe content, review the prompt template safety rules and test with malicious retrieved content.
- If deployment fails on Agentforce metadata, deploy supporting objects, Apex, Flows, credentials, and prompt templates first, then wire/publish the target agent in Builder.
