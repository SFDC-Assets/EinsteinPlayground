import { LightningElement, api } from 'lwc';

export default class EinsteinLanguageSelectLwc extends LightningElement {
    value = 'en_US';

    get options() {
        return [
			{ label: "Chinese Simplified", value: "zh_CN" },
			{ label: "Chinese Traditional", value: "zh_TW" },
			{ label: "English (US)", value: "en_US" },
            { label: "English (UK)", value: "en_GB" },
            { label: "French", value: "fr" },
            { label: "German", value: "de" },
			{ label: "Italian", value: "it" },
			{ label: "Japanese", value: "ja" },
            { label: "Portuguese", value: "pt_PT" },
            { label: "Spanish", value: "es" }
        ];
    }

    handleChange(event) {
        this.value = event.detail.value;
        this.sendEvent();
    }

    connectedCallback() {
        // send the initial, default value
        this.sendEvent();
    }

    sendEvent() {
        const newValue = this.value;
        console.log('sendEvent: ', newValue);
        const valueChangeEvent = new CustomEvent("languagevaluechange", {
			detail: { newValue }
        });
        // Fire the custom event
        this.dispatchEvent(valueChangeEvent);
    }

}
