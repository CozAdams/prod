import { LightningElement, api, track, wire } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';

export default class AddressGoogleSearch extends LightningElement {
  @api flexipageRegionWidth;

  @api
  get street() {
    return this._street;
  }

  set street(value) {
    this._street = value;
  }

  @api
  get street2() {
    return this._street2;
  }

  set street2(value) {
    this._street2 = value;
  }

  @api
  get city() {
    return this._city;
  }

  set city(value) {
    this._city = value;
  }

  @api
  get state() {
    return this._state;
  }

  set state(value) {
    this._state = value;
  }

  @api
  get postalCode() {
    return this._postalCode;
  }

  set postalCode(value) {
    this._postalCode = value;
  }

  @api
  get country() {
    return this._country;
  }

  set country(value) {
    this._country = value;
  }

  @api
  get lat() {
    return this._lat;
  }

  set lat(value) {
    this._lat= value;
  }

  @api
  get lng() {
    return this._lng;
  }

  set lng(value) {
    this._lng = value;
  }

  @api 
  get verificationReq() {
    return this._verificationReq;
  }
  set verificationReq(value) {
    this._verificationReq = value;
  }

  @track _street;
  @track _street2;
  @track _city;
  @track _state;
  @track _postal;
  @track _country;
  @track _lat;
  @track _lng;
  @track _verificationReq;
  @track _showOverrideMessage;

  get gridClassColOne() {
    return `slds-col ${this.flexipageRegionWidth !== 'SMALL' ? 'slds-size_4-of-6' : 'slds-size_1-of-1'}`;
  }

  get gridClassColTwo() {
    return `slds-col ${this.flexipageRegionWidth !== 'SMALL' ? 'slds-size_2-of-6 slds-p-left_x-small' : 'slds-size_1-of-1'}`;
  }

  // Get form picklist values from Case record type
  @wire(getPicklistValues, { recordTypeId: '012000000000000AAA', fieldApiName: 'Case.Mailing_Country_Reference__c' }) // Null record type ID returns default options
  countryOptions;

  renderedCallback() {
    this.toggleVerification(this.verificationReq);
  }

  handleChange(event) {
    this[`_${event.target.name}`] = event.target.value;
    this.dispatchEvent(new FlowAttributeChangeEvent(`${event.target.name}`, this[`_${event.target.name}`]));
  }

  // Handle change to verification required
  handleVerificationChange(event) {
    const isChecked = event.target.checked;
    this.toggleVerification(isChecked);
  }

  // Toggle disabled attribute on address fields
  toggleVerification(isChecked) {
    // Disable input fields
    const fieldsToDisable = this.template.querySelectorAll('.override-dependent');
    fieldsToDisable.forEach(field => {
      field.disabled = !isChecked;
    });
    this._showOverrideMessage = isChecked;

    // Uncheck override
    const overrideField = this.template.querySelector('.override-checkbox');
    overrideField.checked = isChecked;
    this._verificationReq = isChecked;

    // Reflect changed value in flow
    this.dispatchEvent(new FlowAttributeChangeEvent('verificationReq', this['_verificationReq']));
  }

  handleAddressSelected(event) {
    const inputFields = this.template.querySelectorAll('.address-form-field');
    if (inputFields) {
      inputFields.forEach(field => {
        field.value = event.detail[field.name];
        this[`_${field.name}`] = event.detail[field.name];
      });
    }
    this._lat = event.detail.lat;
    this._lng = event.detail.lng;
    this.dispatchEvent(new FlowAttributeChangeEvent('street', this._street));
    this.dispatchEvent(new FlowAttributeChangeEvent('street2', this._street2));
    this.dispatchEvent(new FlowAttributeChangeEvent('city', this._city));
    this.dispatchEvent(new FlowAttributeChangeEvent('state', this._state));
    this.dispatchEvent(new FlowAttributeChangeEvent('postalCode', this._postalCode));
    this.dispatchEvent(new FlowAttributeChangeEvent('country', this._country));
    this.dispatchEvent(new FlowAttributeChangeEvent('lat', this._lat));
    this.dispatchEvent(new FlowAttributeChangeEvent('lng', this._lng));

    this.toggleVerification(false);
  }
}