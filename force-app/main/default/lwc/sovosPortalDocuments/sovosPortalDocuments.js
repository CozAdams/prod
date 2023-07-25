import { LightningElement, track, api, wire } from 'lwc';
import getData from '@salesforce/apex/SovosPortalDocumentsController.getData';

const columns = [
    { label: 'Year', fieldName: 'year', type: 'text', sortable: true, cellAttributes: {alignment: 'left'} },
    { label: 'Tax Form Name', type: 'button', typeAttributes: {label: {fieldName: 'formName'}, variant: 'base', sortable: true}},
    { label: 'Last Modified Date', fieldName: 'dateModified', type: 'date', sortable: true },
];

export default class PortalDocuments extends LightningElement {
    
    columns = columns;
    @track data = [];
    @api isLoading = false;
    @track hasData = false;
    defaultSortDirection = 'desc';
    sortDirection = 'desc';
    sortedBy = 'year';
    userId = '';
    errorMessage = '';
    
    connectedCallback() {
        this.isLoading = true;
        var currentUrl = window.location.pathname;
        var n = currentUrl.lastIndexOf('/');
        this.userId = currentUrl.substring(n+1);
    }

    @wire(getData,{userId: '$userId'})
    wiredData({ error, data }) {

        // DATA
        if(data) {
            
            // FORMS RETURNED
            if(data.length > 0) {
                //console.log('Data: ', data);
                this.isLoading = false;
                this.hasData = true;
                let lstRecords = [];
                for (let row of data) {
                    const finalSobjectRow = {}
                    let rowIndexes = Object.keys(row); 
                    rowIndexes.forEach((rowIndex) => {
                        let relatedFieldValue = row[rowIndex];
                        if(relatedFieldValue.constructor === Object) {
                            this._flattenTransformation(relatedFieldValue, finalSobjectRow, rowIndex)        
                        } else {
                            finalSobjectRow[rowIndex] = relatedFieldValue;
                        }
                        
                    });
                    lstRecords.push(finalSobjectRow);
                }
                
                /*data.sort(function (a, b) {
                    return a.year.localeCompare(b.year);
                }); */

                this.data = lstRecords;
            } 
            
            // NO FORMS RETURNED
            else {
                this.isLoading = false;
                this.hasData = false;
                this.errorMessage = 'No forms to display';
            }
        } 
        
        // ERROR
        else if(error) {
            this.isLoading = false;
            this.hasData = false;
            this.errorMessage = error.body.message;
        }
    }

    handleRowAction(event){
        let element = document.createElement('a');
        element.setAttribute('href', event.detail.row.url);
        element.setAttribute('download', event.detail.row.year + ' - ' + event.detail.row.formName + ' PDF Statement.pdf');
        element.style.display = 'none';
        document.body.appendChild(element);
        element.click();
        document.body.removeChild(element);

        //window.open(event.detail.row.url, '_blank');
    }

    sortBy(field, reverse, primer) {
        const key = primer
            ? function (x) {
                  return primer(x[field]);
              }
            : function (x) {
                  return x[field];
              };

        return function (a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    }

    onHandleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.data];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.data = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }
}