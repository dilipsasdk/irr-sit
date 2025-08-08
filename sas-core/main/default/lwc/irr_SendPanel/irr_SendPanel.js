/**
 * @author Niklas Lundkvist, Deloitte
 * @date 2020
 *
 * @description Send Panel for the Manual Communication app.
 */

import { LightningElement, api, track } from "lwc";

import { loadStyle } from "lightning/platformResourceLoader";

import c_ComboBoxInlineGrid from "@salesforce/resourceUrl/c_ComboBoxInlineGrid";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class irr_SendPanel extends LightningElement {
  @api templatesBySendMode = {};

  @api flightId = "";

  @api additionalRecipientCount;

  @track showTemplatePicklist = false;

  manualTemplate = {};

  sendMode = "CUSTOM";

  @track sendParameters = {};

  fileUploaded = false;
  @track uploadedFileData = {};

  formats = [
    // "font",
    "bold",
    "italic",
    "underline",
    "strike",
    "list",
    "indent",
    "align",
    "link",
    "clean",
    "code",
    "code-block",
    "color",
    "background",
    "mention",
    "header"
  ];

  get hideFlightIdTabs() {
    return this.flightId && this.flightId.indexOf(",") !== -1;
  }

  get customContentLabel() {
    const length =
      this.sendParameters && this.sendParameters["smscontent"]
        ? this.sendParameters["smscontent"].length
        : 0;
    const smsMessages = Math.ceil(length / 160);
    return length === 0
      ? "SMS Content"
      : `SMS Content - ${length} characters - ${smsMessages} SMS`;
  }

  get templatePicklistOptions() {
    return this.templatesBySendMode[this.sendMode].map((template) => {
      return { label: template.templateLabel, value: template.templateName };
    });
  }

  get additionalRecipientLabel() {
    return this.additionalRecipientCount
      ? `Add Recipients (${this.additionalRecipientCount})`
      : "Add Recipients";
  }

  handleTemplateChange(event) {
    const template = this.templatesBySendMode[this.sendMode].find(
      (template) => template.templateName === event.detail.value
    );
    this.setManualTemplate(template);
  }

  get cancelButtonClass() {
    return this.showTemplatePicklist ? "slds-p-right_small" : "";
  }

  connectedCallback() {
    loadStyle(this, c_ComboBoxInlineGrid);
    this.setSendMode(this.sendMode);
    if (this.flightId) this.sendParameters.flightId = this.flightId;
  }

  handleParameterChange(event) {
    this.sendParameters[event.target.name] =
      event.target.type === "checkbox"
        ? event.target.checked
        : event.target.value;
    console.log("event.target.value:::::" + event.target.value);
  }

  handleTabSwitch(event) {
    this.setSendMode(event.target.value);
  }

  setSendMode(sendMode) {
    if (sendMode && this.templatesBySendMode[this.sendMode]) {
      this.sendMode = sendMode;
      this.setManualTemplate(this.templatesBySendMode[this.sendMode][0]);
      this.showTemplatePicklist =
        this.templatesBySendMode[this.sendMode].length !== 1;
    }
  }

  setManualTemplate(template) {
    this.manualTemplate = template;
    const templateEvent = new CustomEvent("templatechange", {
      detail: { template: this.manualTemplate }
    });
    this.dispatchEvent(templateEvent);
  }

  validateFields() {
    const inputArray = [
      ...this.template.querySelectorAll(
        `lightning-input[data-tab-group="${this.sendMode}"]`
      )
    ];
    inputArray.push(
      ...this.template.querySelectorAll(
        `lightning-textarea[data-tab-group="${this.sendMode}"]`
      )
    );
    inputArray.push(
      ...this.template.querySelectorAll(
        `lightning-input-rich-text[data-tab-group="${this.sendMode}"]`
      )
    );
    if (this.sendMode == "CUSTOM") {
      let contentValueArray = inputArray.map(
        (eachEmailSMS) => eachEmailSMS.value
      );
      console.log("contentValueArray[0]:::" + contentValueArray[0]);
      if (contentValueArray[0] == "") {
        return inputArray.reduce(
          (previousValue, cmp) => cmp.reportValidity() && previousValue,
          true
        );
      }
      var filtered = contentValueArray.filter((elm) => elm);
      if (filtered.length <= 1) {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Incomplete field !!",
            message: "Please enter email or SMS content or both !!! ",
            variant: "Error",
            mode: "Sticky"
          })
        );
        return false;
      }
      return true;
    } else {
      return inputArray.reduce(
        (previousValue, cmp) => cmp.reportValidity() && previousValue,
        true
      );
    }
  }

  handleShowRecipientModal() {
    const event = new CustomEvent("showrecipientmodal");
    this.dispatchEvent(event);
  }

  handleSendEmail(event) {
    const file = event.target.files[0];
    // Convert the file to base64
    let reader = new FileReader();
    reader.onload = () => {
      let base64 = reader.result.split(",")[1];
      console.log("base64:::" + base64);
      this.uploadedFileData.base64Data = base64;
    };
    reader.readAsDataURL(file);
  }

  handleFileChange(event) {
    const file = event.target.files[0];

    if (file.size > 3000000) {
      alert("File size should be less than 3 MB");
      return;
    }

    if (file.type != "application/pdf") {
      alert("Only PDF file is supported");
      return;
    }

    this.uploadedFileData.file = file;
    this.uploadedFileData.fileName = file.name;
    this.uploadedFileData.fileType = file.type;

    this.fileUploaded = true;
    this.handleSendEmail(event);
  }

  removeEmailUploadedFile() {
    this.uploadedFileData = {};
    this.fileUploaded = false;
  }

  handleSend() {
    if (!this.validateFields()) return;
    console.log(
      "this.sendParameters email content:::" + this.sendParameters["content"]
    );
    console.log(
      "this.sendParameters sms content:::" + this.sendParameters["smscontent"]
    );
    console.log("this.manualTemplate:::" + this.manualTemplate);

    if (this.sendParameters["content"]) {
      let emailContent = this.sendParameters["content"]
        .replace(/<p><br><\/p>/g, "<br>")
        .replace(/<p>/g, "<br>")
        .replace(/<\/p>/g, "");
      emailContent = emailContent.trim();
      this.sendParameters["content"] = "<p>" + emailContent + "</p>";
    }

    const sendEvent = new CustomEvent("send", {
      detail: {
        sendMode: this.sendMode,
        parameters: this.sendParameters,
        manualTemplate: this.manualTemplate,
        fileUploaded: this.fileUploaded,
        uploadedFileData: this.uploadedFileData
      }
    });
    this.dispatchEvent(sendEvent);
  }

  handleCancel() {
    this.dispatchEvent(new CustomEvent("cancel"));
  }
}
