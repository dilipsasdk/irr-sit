import { LightningElement,track,wire } from 'lwc';
import qrcode from './qrcode.js';
import { CurrentPageReference } from 'lightning/navigation';
export default class QR_Code_Generator_LWC extends LightningElement {
  
    renderedCallback() {
        const urlParams = new URLSearchParams(window.location.search);
        const decodeBase64 = atob(urlParams.get('Id'));
        this.renderQR(decodeBase64);
        
    }

    renderQR(Id) {
        const qrCodeGenerated = new qrcode(0, 'H');
        let strForGenearationOfQRCode  = Id;
        qrCodeGenerated.addData(strForGenearationOfQRCode);
        qrCodeGenerated.make();
        let element = this.template.querySelector(".qrcode2");
        element.innerHTML = qrCodeGenerated.createSvgTag({});
    }

    
    
}