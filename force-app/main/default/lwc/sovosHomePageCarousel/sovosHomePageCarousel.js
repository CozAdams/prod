import { LightningElement, track, api } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import FLICK from '@salesforce/resourceUrl/flickity';
import Id from '@salesforce/user/Id';
import tab2 from '@salesforce/label/c.PortalTab2';
import tab3 from '@salesforce/label/c.PortalTab3';
import newEnrollment from '@salesforce/label/c.New_Enrollment';
import getAccountSummary from '@salesforce/apex/SovosRecurringContributionsController.getData';
import sendToBillerIQ from '@salesforce/apex/BillerDirectSSO.RedirectToBillerIQ';
import images from '@salesforce/resourceUrl/images'

export default class SovosHomePageCarousel extends LightningElement {
    currentPageReference = window.location.href;
    userId = Id;
    profileTab1 = this.currentPageReference + 'profile/' + this.userId;
    profileTab2 = this.currentPageReference + 'profile/' + this.userId + tab2;
    profileTab3 = this.currentPageReference + 'profile/' + this.userId + tab3;
    newEnrollmentURL = this.currentPageReference + newEnrollment;

    @api isLoading = false;
    @api accountSummaryId = '';
    @track isModalOpen = false;
    @track showNoAccountFound = false;
    bodyValue = '';

    RecurringContribImage = images + '/images/RecurringContribImage.jpg';
    OopsImage = images + '/images/Oops.jpg';

    connectedCallback() {
        this.isLoading = true;
        this.loadScripts();

        // Get Account Summary for Recurring Contributions
        getAccountSummary({userId: this.userId}).then(result => {
            this.accountSummaryId = result;
        });
    }

    async loadScripts() {
        await loadScript(this, FLICK + '/jquery.min.js');
        await loadScript(this, FLICK + '/flickity.pkgd.min.js');
        await loadStyle(this, FLICK + '/flickity.css');
        
        $(this.template.querySelector('div[class="carousel"]')).flickity({
            autoPlay: false
        });
        this.isLoading = false;
    }

    handleContributions() {
        console.log('Account Summary Id: ', this.accountSummaryId);
        if(this.accountSummaryId != '') {
            this.isModalOpen = true;
            sendToBillerIQ({accountSummaryId: this.accountSummaryId}).then(result => {
                this.bodyValue = result;
            });
        }
        else {
            this.showNoAccountFound = true;
        }
    }

    handleClick() {
        const form = this.template.querySelector('form');
        form.submit();
        this.isModalOpen = false;
    }

    handleCancel() {
        this.isModalOpen = false;
        this.showNoAccountFound = false;
    }

    handleProfileTab1() {
        window.open(this.profileTab1, '_self');
    }

    handleProfileTab2() {
        window.open(this.profileTab2, '_self');
    }

    handleProfileTab3() {
        window.open(this.profileTab3, '_self');
    }

    handleNewEnrollment() {
        window.open(this.newEnrollmentURL, '_self');
    }
}