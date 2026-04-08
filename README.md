# Get User Timezone

A Salesforce Lightning Web Component that detects a user's timezone from their browser and lets them confirm or change it. Built for Experience Cloud pages and Flow screens.

## What It Does

1. **Auto-detects** the user's timezone from their browser (e.g., `America/New_York`)
2. **Asks the user to confirm** — shows the detected timezone and local time
3. **Offers alternatives** if the detection is wrong:
   - **Address lookup** — enter an address and resolve the timezone via Google Maps API
   - **Dropdown** — pick from a full list of IANA timezones with UTC offsets
4. **Outputs the timezone** as Flow output variables for downstream use

## What's Included

| Component | Description |
|-----------|-------------|
| `browserTimezoneForFlow` | LWC — the UI component |
| `TimezoneLookupForLwcController` | Apex — wires the LWC to the timezone lookup utility |
| `GoogleMapsTimezoneUtil` | Apex — handles Google Maps Geocoding + Timezone API calls |
| `Google_Maps_Config__mdt` | Custom Metadata Type — stores your Google Maps API key |
| `TimeZoneApi` | Named Credential — endpoint config for `maps.googleapis.com` |
| `TimeZoneExternal` | External Credential — authentication for the Named Credential |
| `Contact.Browser_Timezone__c` | Custom field — stores the confirmed timezone on Contact |
| `Contact.Address_Timezone__c` | Custom field — stores address-derived timezone on Contact |
| Permission Sets | `Timezone_Address_Lookup_Apex`, `Contact_Timezone_Enrichment` |
| Flows | Sample flows for timezone capture and Contact update |

## Installation

### Option A: Install via URL (Recommended)

Click the link below and log into your Salesforce org:

**[Install Get User Timezone](https://login.salesforce.com/packaging/installPackage.apexp?p0=04tHu000003yhPUIAY)**

1. Choose **Install for All Users**
2. Click **Install**
3. Continue to **Post-Install Setup** below

### Option B: Deploy from Source

If you prefer to deploy from source (e.g., to customize before installing):

#### Prerequisites

- Salesforce CLI (`sf`) installed — [install guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_install_cli.htm)
- A Salesforce demo org (sandbox, scratch org, or trial)

```bash
git clone https://github.com/rachelhawley685/get-user-timezone.git
cd get-user-timezone
sf org login web --alias my-demo-org --set-default
sf project deploy start --source-dir force-app --test-level NoTestRun
```

## Post-Install Setup

### Step 1: Add Your Google Maps API Key

The component uses a Custom Metadata Type to store the API key server-side.

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
8. Copy the key and add it in Salesforce (Step 4 above)

### Step 5: Configure the Named Credential

The Named Credential `TimeZoneApi` should already be deployed pointing to `https://maps.googleapis.com`. Verify it exists in **Setup > Named Credentials**.

### Step 6: Assign Permission Sets

Assign the following permission sets to users who need timezone lookup:

- **Timezone Address Lookup Apex** — grants access to the Apex classes
- **Contact Timezone Enrichment** — grants field-level access to timezone fields on Contact

```bash
sf org assign permset --name Timezone_Address_Lookup_Apex --target-org my-demo-org
sf org assign permset --name Contact_Timezone_Enrichment --target-org my-demo-org
```

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

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| `REQUEST_DENIED` | Google API key missing or APIs not enabled | Add your key to Google Maps Config (Step 4) and enable both Geocoding API and Time Zone API in Google Cloud Console |
| `Geocoding status: ZERO_RESULTS` | Address not recognized by Google | Try a more specific address with city and country |
| Named Credential errors | `TimeZoneApi` not deployed or misconfigured | Re-deploy and verify the URL is `https://maps.googleapis.com` |
