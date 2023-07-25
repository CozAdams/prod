import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'

export default class AddressGoogleSearch extends LightningElement {
  @api recordId;
  @api objectApiName;
  @api flexipageRegionWidth;
  @api street;
  @api street2;
  @api city;
  @api state;
  @api postalCode;
  @api country;
  @api lat;
  @api lng;
  @track showSpinner = false;
  @track buttonsDisabled = true;
  latValue;
  lngValue;
  fieldMappings = {};

  renderedCallback() {
    // Set the field mappings of App Builder fields to data
    // returned from the Google Maps API
    this.fieldMappings[this.street] = 'street';
    this.fieldMappings[this.street2] = 'street2';
    this.fieldMappings[this.city] = 'city';
    this.fieldMappings[this.state] = 'state';
    this.fieldMappings[this.postalCode] = 'postalCode';
    this.fieldMappings[this.country] = 'country';
  }

  handleChange() {
    if (this.buttonsDisabled) {
      this.buttonsDisabled = false;
    }
  }

  handleAddressSelected(event) {
    const inputFields = this.template.querySelectorAll('lightning-input-field');
    if (inputFields) {
      inputFields.forEach(field => {
        field.value = event.detail[this.fieldMappings[field.fieldName]];
      });
    }
    this.latValue = event.detail.lat;
    this.lngValue = event.detail.lng;

    this.searchTerm = '';
    this.listExpanded = false;
    this.buttonsDisabled = false;
  }

  handleReset() {
    const inputFields = this.template.querySelectorAll('lightning-input-field');
    if (inputFields) {
      inputFields.forEach(field => {
        field.reset();
      });
    }
    this.buttonsDisabled = true;
  }

  handleSubmit(event) {
    event.preventDefault();
    this.showSpinner = true;
    const fields = event.detail.fields;
    fields[this.lat] = this.latValue;
    fields[this.lng] = this.lngValue;

    this.template.querySelector('lightning-record-edit-form').submit(fields);
  }

  handleSuccess() {
    this.dispatchEvent(new ShowToastEvent({
      title: 'Success',
      message: 'Address saved successfully.',
      variant: 'success'
    }));
    this.showSpinner = false;
    this.buttonsDisabled = true;
  }

  handleError(event) {
    this.dispatchEvent(
      new ShowToastEvent({
        title: 'Error creating record',
        message: event.detail.message,
        variant: 'error',
      }),
    );
    this.showSpinner = false;
  }
}