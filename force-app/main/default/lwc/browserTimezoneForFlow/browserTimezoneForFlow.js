import { LightningElement, api } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import lookupTimezoneFromAddress from '@salesforce/apex/TimezoneLookupForLwcController.lookupTimezoneFromAddress';

const FALLBACK_TIMEZONES = [
    'America/New_York',
    'America/Chicago',
    'America/Denver',
    'America/Los_Angeles',
    'America/Phoenix',
    'America/Anchorage',
    'Pacific/Honolulu',
    'America/Toronto',
    'America/Vancouver',
    'America/Mexico_City',
    'America/Sao_Paulo',
    'Europe/London',
    'Europe/Paris',
    'Europe/Berlin',
    'Europe/Madrid',
    'Europe/Rome',
    'Europe/Amsterdam',
    'Asia/Tokyo',
    'Asia/Shanghai',
    'Asia/Singapore',
    'Asia/Dubai',
    'Asia/Kolkata',
    'Australia/Sydney',
    'Australia/Melbourne',
    'Pacific/Auckland',
    'UTC'
];

export default class BrowserTimezoneForFlow extends LightningElement {
    @api timezoneIana;
    @api utcOffsetMinutes;
    @api currentLocalDateTime;
    @api currentUtcDateTime;
    @api captureOnLoad;
    @api apiKey;

    _inputTimezoneIana;
    step = 'confirm';
    alternateMode = '';
    addressStreet = '';
    addressCity = '';
    addressProvince = '';
    addressCountry = '';
    addressPostalCode = '';
    addressError = '';
    addressLoading = false;
    dropdownValue = '';
    timezoneOptions = [];

    @api
    get inputTimezoneIana() {
        return this._inputTimezoneIana;
    }
    set inputTimezoneIana(value) {
        this._inputTimezoneIana = value;
        if (value) {
            this.applyTimezone(value);
        }
    }

    connectedCallback() {
        this.timezoneOptions = this.buildTimezoneOptions();
        if (this.captureOnLoad !== false) {
            this.captureTimezone();
        }
    }

    buildTimezoneOptions() {
        let zones;
        try {
            if (typeof Intl !== 'undefined' && typeof Intl.supportedValuesOf === 'function') {
                zones = Intl.supportedValuesOf('timeZone');
            }
        } catch (e) {
            // ignore
        }
        if (!zones) {
            zones = FALLBACK_TIMEZONES;
        }
        return zones.map((z) => {
            const offset = this.formatUtcOffset(z);
            return { label: `${z} (${offset})`, value: z };
        });
    }

    formatUtcOffset(timeZone) {
        try {
            const parts = new Intl.DateTimeFormat('en-US', {
                timeZone,
                timeZoneName: 'longOffset'
            }).formatToParts(new Date());
            const name = parts.find((p) => p.type === 'timeZoneName')?.value;
            if (name === 'GMT') {
                return 'UTC+00:00';
            }
            return name ? name.replace('GMT', 'UTC') : 'UTC';
        } catch (e) {
            return 'UTC';
        }
    }

    get isConfirmStep() {
        return this.step === 'confirm';
    }

    get isAlternateStep() {
        return this.step === 'alternate';
    }

    get isDoneStep() {
        return this.step === 'done';
    }

    get showAddressPanel() {
        return this.isAlternateStep && this.alternateMode === 'address';
    }

    get showDropdownPanel() {
        return this.isAlternateStep && this.alternateMode === 'dropdown';
    }

    handleConfirmYes() {
        this.step = 'done';
        this.publishOutputs();
    }

    handleConfirmNo() {
        this.step = 'alternate';
        this.alternateMode = '';
        this.dropdownValue = this.timezoneIana || '';
        this.addressError = '';
        this.clearAddressFields();
    }

    handleAlternateChange(event) {
        this.alternateMode = event.detail.value;
        this.addressError = '';
        if (this.alternateMode !== 'address') {
            this.clearAddressFields();
        }
    }

    handleAddressCompoundChange(event) {
        const t = event.target;
        this.addressStreet = t.street ?? '';
        this.addressCity = t.city ?? '';
        this.addressProvince = t.province ?? '';
        this.addressCountry = t.country ?? '';
        this.addressPostalCode = t.postalCode ?? '';
    }

    clearAddressFields() {
        this.addressStreet = '';
        this.addressCity = '';
        this.addressProvince = '';
        this.addressCountry = '';
        this.addressPostalCode = '';
    }

    getAddressLookupQuery() {
        const parts = [
            this.addressStreet,
            this.addressCity,
            this.addressProvince,
            this.addressPostalCode,
            this.addressCountry
        ]
            .map((p) => (p || '').trim())
            .filter(Boolean);
        return parts.join(', ');
    }

    async handleAddressLookup() {
        this.addressError = '';
        const query = this.getAddressLookupQuery();
        if (!query) {
            this.addressError = 'Enter an address or use the address lookup to fill the fields.';
            return;
        }
        this.addressLoading = true;
        try {
            const result = await lookupTimezoneFromAddress({
                address: query,
                apiKey: this.apiKey || null
            });
            if (result.success) {
                const now = new Date();
                this.timezoneIana = result.timezoneIana;
                if (result.utcOffsetSeconds != null) {
                    this.utcOffsetMinutes = Math.round(Number(result.utcOffsetSeconds) / 60);
                }
                this.currentUtcDateTime = this.formatDateTime(now, 'UTC');
                this.currentLocalDateTime = this.formatDateTime(
                    now,
                    this.timezoneIana || undefined
                );
                this.step = 'done';
                this.publishOutputs();
            } else {
                this.addressError = result.message || 'Could not determine timezone for that address.';
            }
        } catch (e) {
            this.addressError = e.body?.message || e.message || 'Lookup failed. Try again.';
        } finally {
            this.addressLoading = false;
        }
    }

    handleDropdownChange(event) {
        const value = event.detail.value;
        if (!value) {
            return;
        }
        this.dropdownValue = value;
        this.applySelectedTimezone(value);
        this.step = 'done';
    }

    get alternateOptions() {
        return [
            { label: 'Look up by address', value: 'address' },
            { label: 'Choose from list', value: 'dropdown' }
        ];
    }

    @api
    captureTimezone() {
        const now = new Date();
        const browserTimezone = Intl.DateTimeFormat().resolvedOptions().timeZone || null;
        this.utcOffsetMinutes = now.getTimezoneOffset() * -1;
        this.timezoneIana = this._inputTimezoneIana || browserTimezone;
        this.currentUtcDateTime = this.formatDateTime(now, 'UTC');
        this.currentLocalDateTime = this.formatDateTime(now, this.timezoneIana || undefined);
        this.step = 'confirm';
        this.publishOutputs();
    }

    applyTimezone(timezoneValue) {
        const now = new Date();
        this.timezoneIana = timezoneValue;
        this.currentUtcDateTime = this.formatDateTime(now, 'UTC');
        this.currentLocalDateTime = this.formatDateTime(now, timezoneValue);
        const off = this.getOffsetMinutesForTimeZone(timezoneValue);
        if (off != null) {
            this.utcOffsetMinutes = off;
        }
        this.publishOutputs();
    }

    applySelectedTimezone(iana) {
        const now = new Date();
        this.timezoneIana = iana;
        const off = this.getOffsetMinutesForTimeZone(iana);
        if (off != null) {
            this.utcOffsetMinutes = off;
        }
        this.currentUtcDateTime = this.formatDateTime(now, 'UTC');
        this.currentLocalDateTime = this.formatDateTime(now, iana);
        this.publishOutputs();
    }

    getOffsetMinutesForTimeZone(timeZone) {
        try {
            const parts = new Intl.DateTimeFormat('en-US', {
                timeZone,
                timeZoneName: 'longOffset'
            }).formatToParts(new Date());
            const name = parts.find((p) => p.type === 'timeZoneName')?.value;
            if (!name) {
                return null;
            }
            const m = name.match(/GMT([+-])(\d{1,2})(?::(\d{2}))?/);
            if (!m) {
                return null;
            }
            const sign = m[1] === '-' ? -1 : 1;
            const hours = parseInt(m[2], 10);
            const mins = m[3] ? parseInt(m[3], 10) : 0;
            return sign * (hours * 60 + mins);
        } catch (e) {
            return null;
        }
    }

    formatDateTime(dateValue, timeZoneValue) {
        return new Intl.DateTimeFormat('en-US', {
            month: '2-digit',
            day: '2-digit',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit',
            hour12: true,
            timeZone: timeZoneValue
        }).format(dateValue);
    }

    publishOutputs() {
        this.dispatchEvent(new FlowAttributeChangeEvent('timezoneIana', this.timezoneIana));
        this.dispatchEvent(new FlowAttributeChangeEvent('utcOffsetMinutes', this.utcOffsetMinutes));
        this.dispatchEvent(new FlowAttributeChangeEvent('currentLocalDateTime', this.currentLocalDateTime));
        this.dispatchEvent(new FlowAttributeChangeEvent('currentUtcDateTime', this.currentUtcDateTime));
        this.dispatchEvent(
            new CustomEvent('timezonechange', {
                detail: {
                    timezoneIana: this.timezoneIana,
                    utcOffsetMinutes: this.utcOffsetMinutes,
                    currentLocalDateTime: this.currentLocalDateTime,
                    currentUtcDateTime: this.currentUtcDateTime
                },
                bubbles: true,
                composed: true
            })
        );
    }
}
