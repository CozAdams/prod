import { LightningElement,track,api } from 'lwc';
import SCORE_THRSHOLD from '@salesforce/label/c.ThreatMetrixOtpThreshold';
import { convertWiredObject} from 'c/threatMetrixUtil';
import requestOTP from '@salesforce/apex/ThreatMetrixService.requestOTP'
import confirmOTP from '@salesforce/apex/ThreatMetrixService.confirmOTP'
import getUserContactDetails from '@salesforce/apex/ThreatMetrixService.getUserContactDetails'
import Id from '@salesforce/user/Id'
import {FlowNavigationNextEvent} from 'lightning/flowSupport';


export default class ModalPopupLWC extends LightningElement {
    _threatMetrixResponseScore;
    scorethreshold;
    @api contactInfo;
    @api userId;
    @api authenticated = false;
    @track oneTimePassword;
    otpDeliveryRadioGroupOptions;
    otpDeliveryRadioGroup;
    contactOtpDelivery;
    passwordInputHelpMessage;
    setTimeoutId;
    dataRetrieveErrorMessage;

    showContactInfo = false;
    showSpinner = false;
    showSelectionPage = true;
    showConfirmationPage = false;
    nextDisabled = true;

    //for demo 
    get demoThreatMetrixResponseScore(){
        return 'TheatMetrix score: ' +  this.threatMetrixResponseScore + ' , ' + 'Internal Threashold is: ' +  this.scorethreshold ;
   }
   get backDisabled(){

        return this.showSelectionPage
   }

    @api get threatMetrixResponseScore(){
        return this._threatMetrixResponseScore;

    }

    set threatMetrixResponseScore(value){
        this._threatMetrixResponseScore = value;
        console.log('threat metrix score issss', this.threatMetrixResponseScore);
    }

    get chosenContactInfoText (){
        let chosenContactInfoText;
        //extract thissss
        switch(this.otpDeliveryRadioGroup){
            case 'sms' :
            case 'phone' :
                this.contactOtpDelivery ?   chosenContactInfoText = `Phone Number: ${this.contactOtpDelivery?.replace(/.(?=.{4})/g, '*')}` : chosenContactInfoText = ''
                break;
            case 'email' :
                 this.contactOtpDelivery ? chosenContactInfoText = `Email: ${this.contactOtpDelivery.replace(/^(.)(.*)(.@.*)$/, (_, a, b, c) => a + b.replace(/./g, '*') + c)}` : chosenContactInfoText = '';
                break;
            default:
                chosenContactInfoText = null;
        }

        return chosenContactInfoText;
    }

    connectedCallback(){
        if(!this.userId){
            this.userId = Id;
        }
        getUserContactDetails({ userId : this.userId })
        .then((result) => {
            this.contactInfo = result;
            if(result){
                this.otpDeliveryRadioGroupOptions = [
                    { label: 'SMS / Text Message', value: 'sms' },
                    { label: 'Email', value: 'email' },
                    { label: 'Phone Call', value: 'phone' },
                    //{ label: 'Skip', value: 'skip' }
                ]
                this.scorethreshold = parseInt(SCORE_THRSHOLD);
                console.log('contact information issss', JSON.stringify(this.contactInfo));
            }
        })
     }

     disconnectedCallback(){
       // window.location.replace("/MyPensionfund/secur/logout.jsp");
       // console.log('Disconncted call back has been fired');
     }

     changeInput (event) {
        this.oneTimePassword = event.target.value;
     }


    logout() {
        alert('We are unable to complete your request at this time. Please contact Pension Fund at 866-495-7322 for assistance');
        window.location.replace("/MyPensionfund/secur/logout.jsp");

    }

     handleChange (event){


        this.nextDisabled = true;
        this.dataRetrieveErrorMessage = '';

        this.otpDeliveryRadioGroup = event.detail.value;
        this.showContactInfo = true;
        var successfulAuthentication = false; 
        console.log('otpDeliveryRadioGroup', this.otpDeliveryRadioGroup , event.detail.value , JSON.parse(JSON.stringify(event.target)));
        //extract thissss
        switch(this.otpDeliveryRadioGroup){
            case 'sms' :
                 this.contactOtpDelivery = this.contactInfo.Twilio_Phone_Number__c;
                         break;
            case 'phone' :
                switch(this.contactInfo.Contact.npe01__PreferredPhone__c){
                    case 'Mobile':
                        this.contactOtpDelivery = this.contactInfo.Contact.MobilePhone;
                         break;
                    case'Home':
                        this.contactOtpDelivery = this.contactInfo.Contact.HomePhone
                        break;

                    case'Work' :
                        this.contactOtpDelivery = this.contactInfo.Contact.Phone
                        break;

                    case'Other':
                        this.contactOtpDelivery = this.contactInfo.Contact.OtherPhone
                        break;

                    default:
                        this.contactOtpDelivery = this.contactInfo.Contact.MobilePhone
                        break;
                }
                break;
            case 'email' :
                this.contactOtpDelivery = this.contactInfo.Contact.Email
                break;
             default:
                this.contactOtpDelivery = null;
        }

        if(this.contactOtpDelivery){
            this.nextDisabled = false;
            this.dataRetrieveErrorMessage = '';
        }else{

            this.dataRetrieveErrorMessage = 'Could not find the selected contact information';
            
        }
     }

    handleBack(){

        this.showSelectionPage = true;
        this.passwordInputHelpMessage = '';
        this.oneTimePassword ='';

    }

    handleNext() {

        this.showSpinner = true;
        this.passwordInputHelpMessage = '';

       if(this.showSelectionPage){
            requestOTP({ format: this.otpDeliveryRadioGroup , contactInfo: this.contactOtpDelivery })
            .then((result) => {
                this.conversationId = result;
                console.log('conversationId from request: ' + this.conversationId);
                this.showSpinner = false;
                this.showSelectionPage = false;

                if(!this.setTimeoutId){
                    this.setTimeoutId = setTimeout( ()=> {

                        alert('We are unable to complete your request at this time. Please contact Pension Fund at 866-495-7322 for assistance');
                        window.location.replace("/MyPensionfund/secur/logout.jsp")
   
                       } ,180000)
                }

            })
            .catch((error) => {
                console.log('API request Error', error);
                this.passwordInputHelpMessage = 'An error has occoured while making the request, please try again';
            });
       } else{ 
           console.log('conversationId  from submit: ' + this.conversationId);
           console.log('oneTimePassword: ' + this.oneTimePassword);
            confirmOTP({ conversationNumber: this.conversationId, inputNumber: this.oneTimePassword })
            .then((result) => {
                if(result){
                    this.showSelectionPage = true;
                    this.showSpinner = false;
                    this.passwordInputHelpMessage = '';
                    this.oneTimePassword = '';
                    this.authenticated = true;
                    clearTimeout(this.setTimeoutId);
                    this.dispatchEvent(new FlowNavigationNextEvent());
                    this.dispatchEvent(new CustomEvent('otpauthenticated'));

                }else{
                    this.passwordInputHelpMessage = 'Invalid passcode, please try again'
                    this.showSpinner = false;
                }
            })
            .catch((error) => {
                this.passwordInputHelpMessage = 'An error has occoured while making the request, please try again'
                this.showSpinner = false;

            });
        }
    }
}