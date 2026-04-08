# Timezone Flow Implementation Guide

This guide defines two autolaunched Flows that use the Apex actions in this project.

## Flow 1: `Util_Contact_BrowserTimezone_Update`

### Type
Autolaunched Flow (No Trigger)

### Input Variables
- `inContactId` (Text, Available for input = true)
- `inBrowserTimezoneIana` (Text, Available for input = true)
- `inBrowserUtcOffsetMinutes` (Number, 0 decimals, Available for input = true)

### Elements
1. **Action**: `Resolve Browser Timezone`
   - Apex Action: `BrowserTimezoneFlowAction.resolve`
   - Map:
     - `timezoneIana` <= `inBrowserTimezoneIana`
     - `utcOffsetMinutes` <= `inBrowserUtcOffsetMinutes`
   - Store output in:
     - `varResolvedTimezoneIana`
     - `varResolvedUtcOffsetMinutes`
     - `varIsValidTimezone`

2. **Decision**: `Valid Timezone?`
   - Outcome `Yes`: `varIsValidTimezone = true`
   - Default Outcome: End

3. **Update Records**: `Update Contact Browser Timezone`
   - Record: Contact where `Id = inContactId`
   - Field values:
     - `Browser_Timezone__c = varResolvedTimezoneIana`
     - `Browser_UTC_Offset_Minutes__c = varResolvedUtcOffsetMinutes`
     - `Timezone_Source__c = "Browser"`

## Flow 2: `Util_Contact_AddressTimezone_Update`

### Type
Autolaunched Flow (No Trigger)

### Input Variables
- `inContactId` (Text, Available for input = true)
- `inLatitude` (Number, 6 decimals, Available for input = true)
- `inLongitude` (Number, 6 decimals, Available for input = true)
- `inEpochSeconds` (Number, 0 decimals, Available for input = true, optional)

### Elements
1. **Action**: `Lookup Timezone From Coordinates`
   - Apex Action: `TimezoneFromCoordinatesFlowAction.lookup`
   - Map:
     - `latitude` <= `inLatitude`
     - `longitude` <= `inLongitude`
     - `epochSeconds` <= `inEpochSeconds`
   - Store output in:
     - `varLookupSuccess`
     - `varAddressTimezoneIana`
     - `varAddressTimezoneAbbreviation`
     - `varAddressUtcOffsetSeconds`
     - `varLookupMessage`

2. **Decision**: `Lookup Succeeded?`
   - Outcome `Yes`: `varLookupSuccess = true`
   - Default Outcome: End

3. **Update Records**: `Update Contact Address Timezone`
   - Record: Contact where `Id = inContactId`
   - Field values:
     - `Address_Timezone__c = varAddressTimezoneIana`
     - `Address_Timezone_Abbreviation__c = varAddressTimezoneAbbreviation`
     - `Address_UTC_Offset_Seconds__c = varAddressUtcOffsetSeconds`
     - `Timezone_Source__c = "Address"`

## Experience Cloud Screen Flow Pattern

Use your screen Flow with component `browserTimezoneForFlow`:

1. Screen element with `browserTimezoneForFlow`
2. Capture outputs:
   - `timezoneIana` -> Flow variable `varBrowserTimezoneIana`
   - `utcOffsetMinutes` -> Flow variable `varBrowserUtcOffsetMinutes`
3. Subflow call:
   - Subflow = `Util_Contact_BrowserTimezone_Update`
   - Inputs:
     - `inContactId` from your flow context
     - `inBrowserTimezoneIana = varBrowserTimezoneIana`
     - `inBrowserUtcOffsetMinutes = varBrowserUtcOffsetMinutes`

## Notes

- Create and configure Named Credential `TimeZoneApi` before using address timezone lookup.
- If you geocode address in Flow or Apex, pass those coordinates into Flow 2.
- Consider adding field history tracking if timezone changes must be audited.
