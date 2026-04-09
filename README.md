# Get User Timezone

A Salesforce package that detects and manages user timezones. Includes a browser-detection LWC for Experience Cloud and Flow screens, a record-triggered flow that auto-updates Contact timezone when their address changes, and an autolaunched flow that can be invoked by Agentforce or quick actions.

## What It Does

### Browser Detection (LWC)
1. **Auto-detects** the user's timezone from their browser (e.g., `America/New_York`)
2. **Asks the user to confirm** — shows the detected timezone and local time
3. **Offers alternatives** if the detection is wrong:
   - **Address lookup** — enter an address and resolve the timezone via Google Maps API
   - **Dropdown** — pick from a full list of IANA timezones with UTC offsets
4. **Outputs the timezone** as Flow output variables for downstream use

### Automated Timezone Enrichment (Flows)
- **Record-Triggered Flow** — when a Contact's mailing address coordinates change, automatically looks up the timezone and updates the Contact record
- **Autolaunched Flow** — accepts a Contact ID and browser timezone as inputs, validates, and updates the Contact. Can be called by **Agentforce**, a **quick action**, or any other flow

## What's Included

| Component | Type | Description |
|-----------|------|-------------|
| `browserTimezoneForFlow` | LWC | Browser timezone detection UI |
| `TimezoneLookupForLwcController` | Apex | Wires the LWC to the timezone lookup utility |
| `GoogleMapsTimezoneUtil` | Apex | Google Maps Geocoding + Timezone API calls |
| `BrowserTimezoneFlowAction` | Apex (Invocable) | Validates and resolves browser timezone data |
| `TimezoneFromCoordinatesFlowAction` | Apex (Invocable) | Looks up timezone from lat/long coordinates |
| `Google_Maps_Config__mdt` | Custom Metadata Type | Stores your Google Maps API key |
| `SFS_Demo_Lab_Get_Contact_Timezone` | Record-Triggered Flow | Auto-updates Contact timezone when address changes |
| `Util_Contact_BrowserTimezone_Update` | Autolaunched Flow | Updates Contact browser timezone — callable by Agentforce or quick actions |
| Contact Custom Fields | Fields | `Browser_Timezone__c`, `Address_Timezone__c`, `Timezone_Source__c`, `Address_Timezone_Abbreviation__c`, `Browser_UTC_Offset_Minutes__c`, `Address_UTC_Offset_Seconds__c` |
| Permission Sets | Security | `Timezone_Address_Lookup_Apex`, `Contact_Timezone_Enrichment` |

## Installation

### Option A: Install via URL (Recommended)

Click the link below and log into your Salesforce org:

**[Install Get User Timezone](https://login.salesforce.com/packaging/installPackage.apexp?p0=04tHu000003yhThIAI)**

1. Choose **Install for All Users**
2. Under **Advanced Options**, change the Apex compile option to **Compile only this package's Apex** (do NOT use the default "Recompile all Apex" — orgs with Salesforce Maps, Marketing Cloud, or other managed packages may have pre-existing Apex compile errors that will cause the install to fail)
3. Click **Install**
4. Continue to **Post-Install Setup** below

### Option B: Deploy from Source

If you prefer to deploy from source (e.g., to customize before installing):

```bash
git clone https://github.com/rachelhawley685/get-user-timezone.git
cd get-user-timezone
sf org login web --alias my-demo-org --set-default
sf project deploy start --source-dir force-app --test-level NoTestRun
```

## Post-Install Setup

### Step 1: Add Your Google Maps API Key

The address lookup uses a Custom Metadata Type to store the API key server-side.

1. In Setup, search for **Custom Metadata Types**
2. Click **Manage Records** next to **Google Maps Config**
3. Edit the **Default** record
4. Paste your API key into the **API Key** field
5. Click **Save**

### Getting a Google Maps API Key

You need a key with the **Geocoding API** and **Time Zone API** enabled.

**Salesforce SEs:** Request a Google Maps API key through **Embark** if you don't already have one.

**Everyone else:**
1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create or select a project
3. Go to **APIs & Services > Library**
4. Search for and enable **Geocoding API**
5. Search for and enable **Time Zone API**
6. Go to **APIs & Services > Credentials**
7. Click **Create Credentials > API Key**
8. Copy the key and add it in Salesforce (Step 1 above)

### Step 2: Assign Permission Sets

Assign the following permission sets to users who need timezone lookup:

- **Timezone Address Lookup Apex** — grants access to the Apex classes
- **Contact Timezone Enrichment** — grants field-level access to timezone fields on Contact

```bash
sf org assign permset --name Timezone_Address_Lookup_Apex --target-org my-demo-org
sf org assign permset --name Contact_Timezone_Enrichment --target-org my-demo-org
```

### Step 3: Activate the Record-Triggered Flow

The **SFS Demo Lab: Get Contact Timezone** flow is included in Draft status. To enable automatic timezone updates when a Contact's address changes:

1. In Setup, go to **Flows**
2. Find **SFS Demo Lab: Get Contact Timezone**
3. Open it and click **Activate**

## Usage

### On an Experience Cloud Page

Add the `browserTimezoneForFlow` component to any Experience Cloud page via Experience Builder. It's exposed to the `lightningCommunity__Page` and `lightningCommunity__Default` targets.

### In a Flow Screen

Add the component to a Flow Screen. Available output variables:

| Variable | Type | Description |
|----------|------|-------------|
| `timezoneIana` | String | IANA timezone identifier (e.g., `America/Chicago`) |
| `utcOffsetMinutes` | Integer | UTC offset in minutes (e.g., `-300`) |
| `currentLocalDateTime` | String | User's local date/time at capture |
| `currentUtcDateTime` | String | UTC date/time at capture |

Optional input variables:

| Variable | Type | Description |
|----------|------|-------------|
| `captureOnLoad` | Boolean | Auto-detect on load (default: `true`) |
| `inputTimezoneIana` | String | Pre-populate with a known timezone |
| `apiKey` | String | Override API key (prefer Custom Metadata instead) |

### With Agentforce or Quick Actions

The **Util_Contact_BrowserTimezone_Update** autolaunched flow can be invoked by Agentforce agents or wired to a quick action. It accepts:

| Input Variable | Type | Description |
|----------------|------|-------------|
| `inContactId` | String | The Contact record ID to update |
| `inBrowserTimezoneIana` | String | IANA timezone (e.g., `Europe/Dublin`) |
| `inBrowserUtcOffsetMinutes` | Number | UTC offset in minutes |

### Automatic Address-Based Enrichment

The **SFS Demo Lab: Get Contact Timezone** record-triggered flow runs automatically when a Contact's `MailingLatitude` or `MailingLongitude` changes. It calls the Google Maps Timezone API to resolve the timezone and updates:

- `Address_Timezone__c` — IANA timezone ID
- `Address_Timezone_Abbreviation__c` — timezone abbreviation
- `Address_UTC_Offset_Seconds__c` — UTC offset
- `Timezone_Source__c` — set to "Address"

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| `REQUEST_DENIED` | Google API key missing or APIs not enabled | Add your key to Google Maps Config (Step 1) and enable both Geocoding API and Time Zone API in Google Cloud Console |
| `Geocoding status: ZERO_RESULTS` | Address not recognized by Google | Try a more specific address with city and country |
| Timezone not updating on address change | Record-triggered flow not activated | Activate the **SFS Demo Lab: Get Contact Timezone** flow in Setup |
| `Apex compile failure: Invalid type: MetadataService.Read...` during install | Another installed managed package (e.g., Salesforce Maps, Marketing Cloud) contains an outdated `MetadataServiceTest` class that fails to compile | In the installer, change the Apex compile option to **Compile only this package's Apex** instead of "Recompile all Apex" |
