/**
* @author Gaurav singh, Coforge
* @date 2022
*
* @description Concrete implementation of Icoupon integration functionality.
*/

public class IRR_SVC_ICouponServiceImpl implements IRR_SVC_IICouponService {

    private static final String NAMED_CREDENTIAL = 'callout:SAS_APIM_ICOUPON';
    Private static final String ICOUPON_Url = '/api/v2/flight/flightIrreg?preventDuplicates=true';
    Private static final String STANDALONE_ICOUPON_URL = '/api//v2/flight/pnr?generateBarcodes=true';
    private static final String AIRLINE_CODE = 'SK';
    Public static List<IRR_MOD_ICouponInfo> classCoupons;
    Public static  List<IRR_Icoupon_Voucher__mdt> serviceClassList;

    public  IRR_SVC_ICouponServiceImpl(){
        serviceClassList =new List<IRR_Icoupon_Voucher__mdt>();
        classCoupons = new List<IRR_MOD_ICouponInfo>();
        List<IRR_Icoupon_Voucher__mdt> serviceMtdList = IRR_SEL_IcouponVoucherSelector.newInstance().getIcouponVoucher();
        for(IRR_Icoupon_Voucher__mdt serviceMtd :serviceMtdList){
            
            serviceClassList.add(serviceMtd);
        }
        
      
    }

    private static C_IIntegrationExecutor integrationExecutor {
        get {
            if (integrationExecutor == null) {
                integrationExecutor =
                        IRR_Application.IntegrationExecutorBuilder.newInstance(IRR_Application.IntegrationType.REST)
                                .setBaseURL(NAMED_CREDENTIAL)
                                .enableSASTracking()
                                .build();
            }
            return integrationExecutor;
        }
        private set;
    }

  

    /**
     * @author Gaurav Singh, Coforge
     * @date 2022
     *
     * @description create Flight Voucher  for individual passenger.
     *
     * @param delayInfo     - delay info 
     * @param classWithPassenger - Passengers's service class with segment Id
     *
     * @return IRR_MOD_ICouponInfo
     */
    public List<IRR_MOD_ICouponInfo> createFlightIrregularity(IRR_MOD_DelayInfo delayInfo,Map<String ,List<String>> classWithPassenger) {


        for(String key :  classWithPassenger.keySet()){

           createIcouponRequestBody(delayInfo,key,classWithPassenger);
        }
        return classCoupons;

    }

  /**
     * @author Gaurav Singh, Coforge
     * @date 2022
     *
     * @description .Fetching voucher value from metadata
     *
     * @param delayminute - delay flight id 
     * @param airportcode - code of the airport
     * @param serviceClass - service Class of the pass
     *
     * @return IRR_Icoupon_Voucher__mdt
     */
    public IRR_Icoupon_Voucher__mdt selectCoupanValue(Integer delayInMinute,String airportCode, String serviceClass) {

        IRR_Icoupon_Voucher__mdt serviceMetadata = new IRR_Icoupon_Voucher__mdt();
        for(IRR_Icoupon_Voucher__mdt mtd :  serviceClassList){

           if( airportCode.toLowerCase()==  mtd.AirportCode__c.toLowerCase() &&
               serviceClass.toLowerCase()==mtd.Service_Class_Code__c.toLowerCase() &&
               mtd.Max_Delay__c !=null &&
               delayInMinute>=mtd.Min_Delay__c && delayInMinute < =mtd.Max_Delay__c
            ){
                serviceMetadata = mtd;
                break;
           }
           else if( airportCode.toLowerCase()==  mtd.AirportCode__c.toLowerCase() &&
                    serviceClass.toLowerCase()==mtd.Service_Class_Code__c.toLowerCase() &&
                    mtd.Max_Delay__c ==null &&
                    delayInMinute>=mtd.Min_Delay__c
           ){
               serviceMetadata = mtd;
                break;

           }
        }
        return serviceMetadata;
    }

 
    /**
     * @author Gaurav Singh, Coforge
     * @date 2022
     *
     * @description Creates Icoupon request body structure .
     *
     * @param delayInfo - delay info
     * @param serviceClass - service class of the pass
     *@param classWithPassenger - map of every pass with his class
     * @return void
     */   
    private void createIcouponRequestBody(IRR_MOD_DelayInfo delayInfo,String serviceClass,Map<String ,List<String>> classWithPassenger) {
        String iCouponType = 'Automated';
        Integer fliteNumber = getFliteNumber(delayInfo.flightRef);
           IRR_Icoupon_Voucher__mdt serviceMetadata =new IRR_Icoupon_Voucher__mdt();
           serviceMetadata = selectCoupanValue(delayInfo.delayedMinutes,delayInfo.stationDeparture,serviceClass);
           Decimal voucherAmount =serviceMetadata.CoupanValue__c;
           String currencyCode =serviceMetadata.Currency__c;

           Map<String, Object> icoupan = new Map<String, Object>{
                    'airportCode' => String.valueOf(delayInfo.stationDeparture),
                    'causingAirlineCode' =>String.valueOf(AIRLINE_CODE),
                    'causingFlightNumber' =>fliteNumber,
                    'causingFlightDate' => delayInfo.scheduledTimeOfDepartureUTC.Year()+'-'+delayInfo.scheduledTimeOfDepartureUTC.Month()+'-'+delayInfo.scheduledTimeOfDepartureUTC.Day(),//'2022-03-15', // delayInfo.scheduledTimeOfDepartureUTC,
                    'voucherValue' => voucherAmount,
                    'reasonComment' => serviceMetadata.ReasonComment__c,
                    'RedemptionPassDetails' => new Map<String, Object> {
                                            'airlineCode' =>  String.valueOf(AIRLINE_CODE),
                                            'flightNumber' => fliteNumber,
                                            'flightDate' => delayInfo.scheduledTimeOfDepartureUTC.Year()+'-'+delayInfo.scheduledTimeOfDepartureUTC.Month()+'-'+delayInfo.scheduledTimeOfDepartureUTC.Day(),//  '2022-03-15',// delayInfo.scheduledTimeOfDepartureUTC,
                     'boardingSequences' => classWithPassenger.get(serviceClass)

                    }
            };

          IRR_MOD_ICouponInfo iCouponRes   = new IRR_MOD_ICouponInfo();
          if(voucherAmount!=null && currencyCode!=null)
          {
          IRR_MOD_ICouponInfo resp = callIcouponAPI(icoupan,iCouponType);
              if(resp ==null){
                classCoupons.clear();  
              }
              else{
                  iCouponRes.serviceClassCode = serviceClass;
                  iCouponRes.voucherAmount = voucherAmount;
                  iCouponRes.currencyCode = currencyCode;
                  iCouponRes.couponBatchId = resp.couponBatchId;
                  classCoupons.add(iCouponRes);
              }
          }
    }
 /**
     * @author Gaurav Singh, Coforge
     * @date 2022
     *
     * @description removing char from flight number .
     *
     * @param flight number 
     * @return integer
     */ 
    Private  Integer getFliteNumber(String fliteNumber){
        String fNumber = fliteNumber.replaceAll('\\D+','');
        Integer fNumberInt = Integer.valueOf(fNumber);
        return fNumberInt;
    }

 /**
     * @author Gaurav Singh, Coforge
     * @date 2022
     *
     * @description making callout for icoupon .
     * Modified by Rati Mehra on 23Jan 2024 to identifiy the type of icoupon 'iCouponType'
     *
     * @param icoupon request body
     * @return IRR_MOD_ICouponInfo
     */ 
    public IRR_MOD_ICouponInfo callIcouponAPI(Map<String, Object> requestBody, String iCouponType) {
            C_IntegrationExecutor.IntegrationResponse responseObject = integrationExecutor.executeRequest(
             iCouponType=='Standard' || iCouponType=='Automated' ? ICOUPON_Url: STANDALONE_ICOUPON_URL, C_IntegrationExecutor.Method.POST, requestBody, null);
            
        IRR_MOD_ICouponInfo iCouponRes = new IRR_MOD_ICouponInfo();

       //if(responseObject.statusCode==200){
        iCouponRes = (IRR_MOD_ICouponInfo)Json.deserialize(responseObject.responseBody, IRR_MOD_ICouponInfo.Class);
       //}
       
       if(responseObject.statusCode!=200){
        throw new ICouponException('Error getting response from iCoupon: '+responseObject.statusCode+': '+responseObject.responseBody);
        }
        system.debug('ICOUPON RESPONSE---> ' + iCouponRes.toString());
       /*else if(responseObject.statusCode == 409 ){

            iCouponRes = null;
        }
           else if(responseObject.statusCode != 409 && responseObject.statusCode != 200 ){

            iCouponRes = null;
        }*/
        return iCouponRes;
    }

    /**
        JSON structure for the iCoupon response
    */
    private class ICouponResponse{
        IRR_MOD_ICouponInfo iCouponRes;
        String error;
        String error_description;
    }

    /**
     * Custom exception class for APIM auth exceptions
     */
    public class ICouponException extends Exception{}

}