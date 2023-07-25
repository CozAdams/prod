import { LightningElement, track, api } from 'lwc';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import processSingleAccountDistribution from '@salesforce/apex/InternalRmdService.processSingleAccountDistribution';
import processDeferOption from '@salesforce/apex/InternalRmdService.processDeferOption';
import processProRataDistribution from '@salesforce/apex/InternalRmdService.processProRataDistribution';
import retrieveAccounts from '@salesforce/apex/InternalRmdService.retrieveAccounts';
import getDeferringPicklistValues from '@salesforce/apex/InternalRmdService.getDeferringPicklistValues';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
  
export default class RmdDistributionInternal extends LightningElement {
    //Boolean tracked variable to indicate if modal is open or not default value is false as modal is closed when page is loaded 
    @track isModalOpen = false;
    @track showAccountSearch = false;
    @track showProRata = false;
    @api recordId;
    @track accountOptions = [];
    @track selectedAccount;
    @track title;
    @track okDisabled = false;
    @track showDefer = false;
    @track selectedDeferringOption;
    @track deferringValues = [];

    connectedCallback() {
        
        retrieveAccounts({rmdTypeId : this.recordId})
            .then(picklistValues => {
                console.log('retrieve');
                for(let i=0; i<picklistValues.length; i++){
                    var picklistOption={
                        label: picklistValues[i].Name,
                        value: picklistValues[i].Id
                    };
                    
                    this.accountOptions.push(picklistOption);   
                    
                }
                
            });

       getDeferringPicklistValues().then(data =>{
            console.log('defer ' + data);
            for(let i=0; i<data.length; i++){
                var picklistOption={
                    label: data[i],
                    value: data[i]
                };
                this.deferringValues.push(picklistOption);
                
            }
            console.log('deferringValues ' + this.deferringValues);
        
       });
        
    }
    
    openModalProRata() {
        //call apex class and pass in RMD Account Type Id - a0I....
        this.showAccountSearch = false;
        this.showDefer = false;
        this.showProRata = true;
        this.isModalOpen = true;
        processProRataDistribution({ rmdTypeId : this.recordId}).then(data =>{
            let dataObj = []
            for(let item of data){

                dataObj.push({recordId:item});
            }
            console.log('idddds are: ', dataObj);

            getRecordNotifyChange(dataObj);
        })
        this.title = 'Pro Rata Distribution';
        this.okDisabled = false;
    }
    openModalSingleAccount() {
         //call apex class and pass in RMD Account Type Id - a0I, Account Summary Id XXX
        this.selectedAccount = '';
        this.showDefer = false;
        this.isModalOpen = true;
        this.showProRata = false;
        this.showAccountSearch = true;
        this.title = 'Single Account Distribution';
        this.okDisabled = true;
    }
    openModalDefer() {
        this.selectedDeferringOption = '';
        this.isModalOpen = true;
        this.showAccountSearch = false;
        this.showProRata = false;
        this.showDefer = true;
        this.title = 'Defer';
        this.okDisabled = true;
   }
    closeModal() {
        // to close modal set isModalOpen tarck value as false
        this.isModalOpen = false;

    }
    submitDetails() {
        // to close modal set isModalOpen tarck value as false
        //Add your code to call apex method or do some processing
        if(this.showAccountSearch){
            console.log('------------recordIds-----', this.recordId, this.selectedAccount);
            processSingleAccountDistribution({ rmdTypeId : this.recordId, accountRmdId: this.selectedAccount}).then(data=>{
               let dataObj = []
                for(let item of data){
                    dataObj.push({recordId:item});
                }
               
                getRecordNotifyChange(dataObj);
                console.log('idddds are: ', dataObj);


            });

        }
        else if(this.showDefer){
            processDeferOption({ rmdTypeId : this.recordId, selectedDeferOption: this.selectedDeferringOption}).then(data=>{
                console.log('error message 1: ', data.errorMessage);
                let dataObj = [];
                if(data.errorMessage == '') {
                    for(let item of data.recIdList){
                        console.log('item: ', item);
                        dataObj.push({recordId:item});
                    }
                    getRecordNotifyChange(dataObj);
                }
                else {
                    this.showToast(
                        'Error!', data.errorMessage, 'error', 'sticky'
                    );
                }
             });
            
        }
        else{

            getRecordNotifyChange([{recordId : this.recordId}]);

        }

        this.isModalOpen = false;

    }
    genericOnChange(event){
        this.selectedAccount = event.target.value;
        console.log(this.selectedAccount);
        this.okDisabled = false;
    }

    deferOnChange(event){
        this.selectedDeferringOption = event.target.value;
        console.log(this.selectedDeferringOption);
        this.okDisabled = false;
    }

    showToast(title, message, variant, mode) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(event);
    }
}