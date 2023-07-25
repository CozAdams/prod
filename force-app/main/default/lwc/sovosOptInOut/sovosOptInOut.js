import {LightningElement, track,api,wire} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getData from '@salesforce/apex/SovosOptInOutController.getData';
import updateData from '@salesforce/apex/SovosOptInOutController.updateOptInOutForUser';

export default class ConfirmationDialog extends LightningElement {
     @track value = '';
     @track selectedOption = '';
     @api userId = '';
     @track isVisible = false;
     @track result;
     @track data = [];

   connectedCallback(){
        var currentUrl = window.location.pathname;
        var n = currentUrl.lastIndexOf('/');
        this.userId = currentUrl.substring(n+1);

        getData({userId: this.userId}).then(result => {
            console.log('result in get data------>', result);
            if(result == true){
                this.isVisible = true;
            }

        })
        .catch(error => {
            console.log('userId in error'+this.userId);
            console.log('this.createError' + error.body.message);
            
        });

    }

    get options() {
        return [
            { label: 'Yes, I would like to stop receiving my paper tax statement(s)', value: 'true' },
            { label: 'No, I would like to continue receiving my paper tax statement(s)', value: 'false' },
        ];
    }

    handleRadioChange(event) {
        
        this.selectedOption = event.detail.value;
       
    }

     handleClick(){
        if(this.selectedOption == '' || this.selectedOption == null){
            this.handleAlertClick();
        } else{
            this.dataUpdate();
        }
    }

    async dataUpdate(){
        await updateData({userId:this.userId,selectedOption: this.selectedOption}).then(result => {
            console.log('result after update-------', result);
            this.hideModalBox();
            window.location.reload();
            
                const evt = new ShowToastEvent({
                    title: 'Update Successful',
                    message: 'Success!!',
                    variant: 'success',
                    mode: 'dismissable'
                });
                this.dispatchEvent(evt);
             })
        .catch(error => {
            console.log('this.createError' + error.body.message);
            
        });
    }

    async handleAlertClick() {
          const evt = new ShowToastEvent({
                title: 'Error',
                message: 'Please select an option before submitting',
                variant: 'error',
                mode: 'dismissable'
            });
            this.dispatchEvent(evt);
        
    
    }

    hideModalBox(){
        this.isVisible = false;
        

    }

}