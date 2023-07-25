import { LightningElement,track,api } from 'lwc';
import {FlowNavigationNextEvent} from 'lightning/flowSupport';
import SCORE_THRSHOLD from '@salesforce/label/c.ThreatMetrixOtpThreshold';

export default class OneTimePasswordFlowWrapper extends LightningElement {
    _threatMetrixResponseScore = null;
    showOtp = false;
    showSpinner = true;
    scoreThreashold = SCORE_THRSHOLD;
    @api userId;
    @api  get threatMetrixResponseScore(){

        return this._threatMetrixResponseScore;

    }

    set threatMetrixResponseScore(value){
        this._threatMetrixResponseScore = value; 
        this.showSpinner = false;
        console.log("threat metrix value compare is ", this.threatMetrixResponseScore <  parseInt(SCORE_THRSHOLD) , this.threatMetrixResponseScore <  SCORE_THRSHOLD, SCORE_THRSHOLD )

        if(this.threatMetrixResponseScore == NaN || this.threatMetrixResponseScore == null || this.threatMetrixResponseScore == undefined || this.threatMetrixResponseScore < parseInt( SCORE_THRSHOLD) ){
            this.showOtp = true
        } else{
            setTimeout(() => {
                const navigateNextEvent = new FlowNavigationNextEvent();
                this.dispatchEvent(navigateNextEvent);
            }, 900);
           // this.querySelector('#nextBtn').click();
        }
        
        
        
    }

}