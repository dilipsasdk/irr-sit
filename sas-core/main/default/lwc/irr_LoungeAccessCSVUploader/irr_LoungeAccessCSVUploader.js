import { LightningElement, api,track } from 'lwc';
import saveFile from '@salesforce/apex/IRR_CON_SendQRForLoungeAccess.insertLoungeAccessQRString';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
export default class Irr_LoungeAccessCSVUploader extends LightningElement {
     isShowModal = false;
     filesUploaded = [];
     file;
     fileName;
     fileContents;
     fileReader;
     content;
     MAX_FILE_SIZE = 1500000;
     UploadFile = 'Upload lounge voucher file';
     isTrue = true;
     @track showLoadingSpinner = false;
     @track isError =false;
     @track errorMessage=[];

    @api setModelFlag()
    {
        this.isShowModal = true; 
        console.log('this.isShowModal::'+this.isShowModal); 
    }
    hideModalBox(){
        this.isShowModal = false;
    }
    handleFilesChange(event) {

        if(event.target.files.length > 0) {
            this.filesUploaded = event.target.files;
            this.fileName = event.target.files[0].name;
            this.isTrue = false;
        }
 
    }
    handleSave() {

        if(this.filesUploaded.length > 0) {
 
            this.uploadHelper();
 
        }
 
        else {
 
            this.fileName = 'Please select a CSV file to upload!!';
 
        }
 
    }
    uploadHelper() {

        this.file = this.filesUploaded[0];
       if (this.file.size > this.MAX_FILE_SIZE) {
            window.console.log('File Size is to long');
            return ;
 
        }
        this.showLoadingSpinner = true;
        this.fileReader= new FileReader();
        this.fileReader.onloadend = (() => {
 
            this.fileContents = this.fileReader.result;
            //this.validateFile();
            this.showLoadingSpinner = true;
            this.saveToFile();
 
        });
        this.fileReader.readAsText(this.file);
 
    }
    saveToFile() {

    saveFile({ base64Data: JSON.stringify(this.fileContents)})
    .then(result => {
     window.console.log('result ====> ');
     window.console.log(result);
     this.data = result;
     this.fileName = this.fileName + ' - Uploaded Successfully';
     this.isTrue = true;
     this.isError =false;
     this.showLoadingSpinner = false;
     const successUploadEvent = new CustomEvent('uploadsuccess', {
        detail: true , bubbles: true
        });
     this.dispatchEvent(successUploadEvent);
     this.dispatchEvent(

            new ShowToastEvent({

                title: 'Success!!',
                message: this.file.name + ' - Uploaded Successfully!!!',
                variant: 'success',

            })

        );
    })
    .catch(error => {
        console.log('Error:- '+error.body.message);
        this.showLoadingSpinner = false;
        this.isError = true;
        this.errorMessage.push(error.body.message);
        
    });

   }
}