({
	handleESignatureFieldValidation : function(component, event, helper) {
       let isValid = true;
       let eSignatureField = component.find('eSignatureField');

       eSignatureField.setCustomValidity(''); 
       if(eSignatureField.get('v.checked') !== true) {
           eSignatureField.setCustomValidity('Please select the E-Signature checkbox.');
           isValid = false;
       } else {
          eSignatureField.set('v.value', true);
       }

       eSignatureField.reportValidity();
       return isValid;
    }
})