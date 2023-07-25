import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import getAddresses from '@salesforce/apex/AddressGoogleSearchController.getAddresses';
import getPlaceDetails from '@salesforce/apex/AddressGoogleSearchController.getPlaceDetails';

const DELAY = 350;

export default class GoogleAddressSearch extends LightningElement {
  @track searchTerm;
  @track searchInProgress = false;
  @track predictions = [];
  @track textSegments = [];
  @track listExpanded = false;
  delayTimeout;

  get autocompleteContainerClass() {
    return `address-autocomplete-container ${this.listExpanded ? 'visible' : ''}`;
  } 

  handleKeyChange(event) {
    window.clearTimeout(this.delayTimeout);
    this.searchTerm = event.target.value;
    if (this.searchTerm) {
      // eslint-disable-next-line @lwc/lwc/no-async-operation
      this.delayTimeout = setTimeout(() => {
        this.searchInProgress = true;
        getAddresses({ input: this.searchTerm })
          .then(result => {
            this.predictions = result.predictions;
            this.listExpanded = true;
            console.log(result);
            this.textSegments = result.predictions.map(prediction => {
              return this.getTextSegments(prediction.place_id, prediction.structured_formatting);
            });
            this.searchInProgress = false;
          })
          .catch(error => {
            // TODO: Display error message if applicable
            this.predictions = [];
            this.listExpanded = false;
            this.searchInProgress = false;
            console.log("ERROR!");
            console.error(error);
            this.dispatchEvent(
              new ShowToastEvent({
                title: 'Error Retrieving Addresses',
                message: error.body.message,
                variant: 'error',
              }),
            );
          })
      }, DELAY);
    } else {
      this.predictions = [];
      this.listExpanded = false;
    }
  }

  getTextSegments(placeId, structuredFormatting) {
    const textSegments = { placeId: placeId, mainTextSegments: [], secondaryTextSegments: [] };
    let mainText = structuredFormatting.main_text;
    let secondaryText = structuredFormatting.secondary_text;
    if (structuredFormatting.hasOwnProperty('main_text_matched_substrings')) {
      structuredFormatting.main_text_matched_substrings.forEach(substring => {
        let matchedSubstring = structuredFormatting.main_text.substring(substring.offset, substring.offset + substring.length);
        mainText = mainText.replace(matchedSubstring, (match, offset, string) => {
          return `${(substring.offset > 0 ? '@@@' : '')}!!!${match}@@@`;
        });
      });
    }
    if (mainText) {
      textSegments.mainTextSegments = mainText.split('@@@').map(segment => {
        const segmentObj = {};
        if (segment.substring(0, 3) === '!!!') {
          segmentObj.segment = segment.substring(3);
          segmentObj.match = true;
        } else {
          segmentObj.segment = segment;
          segmentObj.match = false;
        }
        return segmentObj;
      });
    }

    if (structuredFormatting.hasOwnProperty('secondary_text_matched_substrings')) {
      structuredFormatting.secondary_text_matched_substrings.forEach(substring => {
        let matchedSubstring = structuredFormatting.secondary_text.substring(substring.offset, substring.offset + substring.length);
        secondaryText = secondaryText.replace(matchedSubstring, (match, offset, string) => {
          return `${(substring.offset > 0 ? '@@@' : '')}!!!${match}@@@`;
        });
      });
    }
    if (secondaryText) {
      textSegments.secondaryTextSegments = secondaryText.split('@@@').map(segment => {
        const segmentObj = {};
        if (segment.substring(0, 3) === '!!!') {
          segmentObj.segment = segment.substring(3);
          segmentObj.match = true;
        } else {
          segmentObj.segment = segment;
          segmentObj.match = false;
        }
        segmentObj.key = `${placeId}__${segmentObj.segment}`; 
        return segmentObj;
      });
    }
    
    return textSegments;
  }

  handleClick(event) {
    event.preventDefault();
    const placeId = event.currentTarget.dataset.placeId;
    getPlaceDetails({ placeId: placeId })
      .then(data => {
        console.log(data.result);
        const addressSelectedEvent = new CustomEvent('addressselected', { detail: { ...this.setRecordFields(data.result) } });
        this.searchTerm = '';
        this.listExpanded = false;
        this.dispatchEvent(addressSelectedEvent);
      })
      .catch(error => {
        // TODO: Handle error
        console.log("ERROR!");
        console.error(error);
        this.dispatchEvent(
          new ShowToastEvent({
            title: 'Error Selecting Addresses',
            message: error.body.message,
            variant: 'error',
          }),
        );
      })
  }

  setRecordFields(addressData) {
    const componentFields = {};
    const recordFields = {};
    if (Array.isArray(addressData.address_components)) {
      addressData.address_components.forEach(component => {
        if (component.hasOwnProperty('types')) {
          component.types.forEach(type => {
            componentFields[type] = component.short_name;
          });
        }
      });
    }
    if (addressData.geometry && addressData.geometry.hasOwnProperty('location')) {
      componentFields.lat = addressData.geometry.location.lat;
      componentFields.lng = addressData.geometry.location.lng;
    }
    recordFields.street = `${componentFields.street_number ? componentFields.street_number : ''} ${componentFields.route ? componentFields.route : ''}`.trim();
    recordFields.street2 = '';
    recordFields.city = componentFields.locality ? componentFields.locality : '';
    recordFields.state = componentFields.administrative_area_level_1 ? componentFields.administrative_area_level_1 : '';
    recordFields.country = componentFields.country ? componentFields.country : '';
    recordFields.postalCode = componentFields.postal_code ? componentFields.postal_code : '';
    recordFields.lat = componentFields.lat ? componentFields.lat : '';
    recordFields.lng = componentFields.lng ? componentFields.lng : '';
    return recordFields;
  }
}