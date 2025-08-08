public with sharing class FetchEDWBookingResponse {
  public class TicketInfo {
    public String fltAirlCd;
    public String fltNm;
    public Long depDte;
    public Integer segTattoo;
    public String tktAirlCd;
    public String tktNo;
    public Integer tktCouponNo;
    public String recordOprType;
    public Integer resUpdNo;
    public Integer tktTattoo;
    public String fareBasis;
    public String boardingInd;
    public String acceptanceSts;
    public String seatNo;
    public Integer bagCnt;
    public Integer bagWeightQty;
    public Integer fltSegId;
    public String passengerTattoo;
  }

  public class Reservation {
    public String reservationNumber;
    public Long createdDate;
    public PassengerList passengerList;
    public SegmentList segmentList;
    public IrregularityList irregularityList;
    public TicketInfoList ticketInfoList;
  }

  public class TicketInfoList {
    public List<TicketInfo> ticketInfo;
  }

  public ReservationList reservationList;

  public class Irregularity {
    public String fltId;
    public String stnFrCd;
    public String stnToCd;
    public Long depDte;
    public Long arrDte;
    public String fltStatus;
    public Long stdTms;
    public Long staTms;
    public String aircraftRegistration;
    public Long etdTms;
    public Long etaTms;
    public Long atdTms;
    public Long ataTms;
    public Integer arrivalDelayMins;
    public Integer depDelayMins;
    public String changeReason;
    public String supplInfo;
    public String depStnDelayInfo;
    public String arvlStnDelayInfo;
    public String delayRsnCd;
    public String delaySubRsnCd;
    public Integer duration;
    public String delayRsnText;
    public Long delayEventDts;
    public String lastAvlDepStnDelayInfo;
    public String seqNr;
    public String state;
    public Long cnlEventDts;
    public String cnlSpplInfo;
    public String cnlRsnCd;
    public String status;
  }

  public class IrregularityList {
    public List<Irregularity> irregularity;
  }

  public class ReservationList {
    public List<Reservation> reservation;
  }

  public class SegmentList {
    public List<Segment> segment;
  }

  public class PassengerList {
    public List<Passenger> passenger;
  }

  public class Passenger {
    public String firstName;
    public String surName;
    public String email;
    public String mobile;
    public String fqtvAirlineCode;
    public String tier;
    public String ebNumber;
    public String passengerTattoo;
  }

  public class Segment {
    public String offCd;
    public String staffPNR;
    public Long resUpdTms;
    public String officeUpdating;
    public Integer segTattoo;
    public String recordOprType;
    public Integer resUpdateNo;
    public String actionCd;
    public String prevActionCd;
    public String fltAirlCd;
    public String fltNm;
    public String stnFrCd;
    public String stnToCd;
    public Long depDte;
    public String oprBkgCl;
    public String oprSvcCl;
    public Long arrDte;
    public String segStatus;
    public String aircraftRegistration;
    public String fltStatus;
    public Long stdTms;
    public Long staTms;
    public Long etdTms;
    public Long etaTms;
    public Long atdTms;
    public Long ataTms;
    public Integer arrivalDelayMins;
    public Integer depDelayMins;
    public String changeReason;
    public String supplInfo;
    public Integer isLatest;
  }

  public static FetchEDWBookingResponse parse(String response) {
    return (FetchEDWBookingResponse) System.JSON.deserialize(
      response,
      FetchEDWBookingResponse.class
    );
  }
}
