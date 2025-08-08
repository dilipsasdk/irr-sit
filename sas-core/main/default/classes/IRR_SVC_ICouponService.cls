/**
* @author Gaurav Singh, Coforge
* @date 2022
*
* @description This is the entry point for icoupon system.
*/
public class IRR_SVC_ICouponService {
    
    private static final String AIRLINE = 'SK';

   public static List<IRR_MOD_ICouponInfo> createFlightIrregularity(IRR_MOD_DelayInfo delayInfo,Map<String ,List<String>> classWithPassenger) {
        return service().createFlightIrregularity(delayInfo,classWithPassenger);
     }


    /**
    * @author Gaurav Singh, Coforge
    * @date 2023
    *
    * @description generate qr code in IATA formate .
    *
    * @param passenger info
    * @return string
    */ 
   Public Static string getQRCodeFormat(IRR_MOD_PassengerInfo passInformation){
       Date scheduledTimeOfDepartureUTC = Date.valueOf(passInformation.thisSegment.departureTimeUTC);
       Integer day = scheduledTimeOfDepartureUTC.dayOfYear();
       Integer flightNumber  =  getFlightNumber(passInformation.thisSegment.flightNumber);
       //M10000000000000000 00 E000000 OSLCPHSK 0459 027M020F0003 000
       String qrCodeString = 'M10000000000000000 00 E000000 ';
              qrCodeString += passInformation.thisSegment.stationDeparture;
              qrCodeString += passInformation.thisSegment.stationArrival;
              qrCodeString += AIRLINE;
              qrCodeString += ' ';
              qrCodeString += String.valueOf(flightNumber).length() == 3 ? '0' + String.valueOf(flightNumber) : String.valueOf(flightNumber);
              qrCodeString += ' ' + String.valueOf(day).leftPad(3, '0');
              qrCodeString += passInformation.thisSegment.serviceClass;
              qrCodeString += passInformation.thisSegment.seat;
              qrCodeString += String.valueOf(passInformation.thisSegment.boardingSequenceNumber).leftPad(4, '0');
              qrCodeString += ' ';
              qrCodeString += '000';
              System.debug('qrCodeString ++++++ ' + qrCodeString);
       return qrCodeString ;
   }
   /**
    * @author Gaurav Singh, Coforge
    * @date 2023     *
    * @description removing char from flight number .
    *
    * @param flight number 
    * @return integer
    */ 
   Public Static Integer getFlightNumber(String flightNumber){
       String fNumber = flightNumber.replaceAll('\\D+','');
       Integer fNumberInt = Integer.valueOf(fNumber);
       return fNumberInt;
   }


 public static IRR_SVC_IICouponService service() {
     return (IRR_SVC_IICouponService) IRR_Application.Service.newInstance(IRR_SVC_IICouponService.class);
 }

 public class IcouponException extends Exception { }
}