import { LightningElement, wire, api } from 'lwc';
import sendToBillerIQ from '@salesforce/apex/BillerDirectSSO.RedirectToBillerIQ'

export default class BillerDirectSSO extends LightningElement {
    sendNow = false;
    bodyValue = "";
    testbodyValue = "";
    @api recordId;
    

    connectedCallback(){
        console.log(this.recordId)
        sendToBillerIQ({accountSummaryId: this.recordId}).then(result => {
            this.bodyValue = result;
            //this.template.querySelector("Form").submit();
            
            //console.log(this.bodyValue);
        });        
    }
   
    handleClick(evt){


        const form = this.template.querySelector('form');
        form.submit();
        this.dispatchEvent(new CustomEvent('close'));

    }
}