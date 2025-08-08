trigger EBVoucherPaymentApprovedTrigger on EBVoucherPaymentApproved__e(
  after insert
) {
  fflib_SObjectDomain.triggerHandler(EBVoucherPaymentApproved.class);
}
