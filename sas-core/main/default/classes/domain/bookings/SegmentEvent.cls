public without sharing class SegmentEvent extends AbstractSObjectWrapper implements Comparable {
  public Segment_Event__c underlyingSObject { get; private set; }

  public Id segmentId;

  public StatusCode newStatus;
  public StatusCode previousStatus;
  public String officeCode;
  public OperationType operationType;
  public Datetime updateDate;
  public Decimal updateNumber;

  // These are all the operations we will be receiving from EDW
  public enum OperationType {
    C_XD,
    C_A,
    C_X,
    C_CD,
    C_C,
    C_AD
  }

  private static final Map<String, Boolean> OFFICE_CODE_TO_IS_CUSTOMER = new Map<String, Boolean>{
    'SK08RV' => true,
    'SK08MB' => true,
    'SK08VB' => true,
    'SK0001' => false
  }; // TODO extend, potentially: 08TC => true. Talk with process owner.

  private static final Map<String, String> OFFICE_CODE_TO_EXPLANATION = new Map<String, String>{
    'SK08RV' => 'The customer cancelled the trip on the website (regular tickets)',
    'SK08MB' => 'The customer cancelled the trip on a mobile phone',
    'SK08VB' => 'The customer cancelled the trip on the website (eurobonus tickets)',
    'SK0001' => 'SAS cancelled the trip'
  }; // TODO extend

  private static final Map<String, OperationType> OPERATION_TYPE_PICKLIST_VALUE_TO_ENUM = new Map<String, OperationType>{
    'XD' => OperationType.C_XD,
    'A' => OperationType.C_A,
    'X' => OperationType.C_X,
    'CD' => OperationType.C_CD,
    'C' => OperationType.C_C,
    'AD' => OperationType.C_AD
  };

  private static final Map<OperationType, String> OPERATION_ENUM_TO_PICKLIST_VALUE = new Map<OperationType, String>{
    OperationType.C_XD => 'XD',
    OperationType.C_A => 'A',
    OperationType.C_X => 'X',
    OperationType.C_CD => 'CD',
    OperationType.C_C => 'C',
    OperationType.C_AD => 'AD'
  };

  private static final Map<OperationType, String> opeartionTypeToDescription = new Map<OperationType, String>{
    OperationType.C_A => 'Added X',
    OperationType.C_C => 'Changed X',
    OperationType.C_X => 'Cancelled X',
    OperationType.C_AD => 'Added ?',
    OperationType.C_CD => 'Changed ?',
    OperationType.C_XD => 'Cancelled ?'
  };

  private static final Map<String, StatusCode> STATUS_PICKLIST_VALUE_TO_ENUM = new Map<String, StatusCode>{
    'AF' => StatusCode.C_AF,
    'AK' => StatusCode.C_AK,
    'AL' => StatusCode.C_AL,
    'AN' => StatusCode.C_AN,
    'BK' => StatusCode.C_BK,
    'BL' => StatusCode.C_BL,
    'BN' => StatusCode.C_BN,
    'CH' => StatusCode.C_CH,
    'CK' => StatusCode.C_CK,
    'CS' => StatusCode.C_CS,
    'DK' => StatusCode.C_DK,
    'DL' => StatusCode.C_DL,
    'DS' => StatusCode.C_DS,
    'DX' => StatusCode.C_DX,
    'EK' => StatusCode.C_EK,
    'FS' => StatusCode.C_FS,
    'GF' => StatusCode.C_GF,
    'GK' => StatusCode.C_GK,
    'GL' => StatusCode.C_GL,
    'GN' => StatusCode.C_GN,
    'GO' => StatusCode.C_GO,
    'HA' => StatusCode.C_HA,
    'HD' => StatusCode.C_HD,
    'HI' => StatusCode.C_HI,
    'HK' => StatusCode.C_HK,
    'HL' => StatusCode.C_HL,
    'HN' => StatusCode.C_HN,
    'HQ' => StatusCode.C_HQ,
    'HS' => StatusCode.C_HS,
    'HW' => StatusCode.C_HW,
    'HX' => StatusCode.C_HX,
    'IG' => StatusCode.C_IG,
    'IH' => StatusCode.C_IH,
    'IK' => StatusCode.C_IK,
    'IN' => StatusCode.C_IN,
    'IS' => StatusCode.C_IS,
    'IX' => StatusCode.C_IX,
    'KD' => StatusCode.C_KD,
    'KK' => StatusCode.C_KK,
    'KL' => StatusCode.C_KL,
    'LK' => StatusCode.C_LK,
    'LL' => StatusCode.C_LL,
    'MB' => StatusCode.C_MB,
    'MK' => StatusCode.C_MK,
    'ML' => StatusCode.C_ML,
    'MN' => StatusCode.C_MN,
    'MR' => StatusCode.C_MR,
    'NA' => StatusCode.C_NA,
    'NN' => StatusCode.C_NN,
    'NO' => StatusCode.C_NO,
    'NS' => StatusCode.C_NS,
    'OB' => StatusCode.C_OB,
    'OX' => StatusCode.C_OX,
    'PA' => StatusCode.C_PA,
    'PB' => StatusCode.C_PB,
    'PC' => StatusCode.C_PC,
    'PD' => StatusCode.C_PD,
    'PK' => StatusCode.C_PK,
    'PN' => StatusCode.C_PN,
    'PS' => StatusCode.C_PS,
    'PW' => StatusCode.C_PW,
    'RR' => StatusCode.C_RR,
    'SB' => StatusCode.C_SB,
    'SC' => StatusCode.C_SC,
    'SD' => StatusCode.C_SD,
    'SP' => StatusCode.C_SP,
    'SQ' => StatusCode.C_SQ,
    'SS' => StatusCode.C_SS,
    'TK' => StatusCode.C_TK,
    'TL' => StatusCode.C_TL,
    'TN' => StatusCode.C_TN,
    'UC' => StatusCode.C_UC,
    'UN' => StatusCode.C_UN,
    'US' => StatusCode.C_US,
    'UU' => StatusCode.C_UU,
    'WK' => StatusCode.C_WK,
    'WL' => StatusCode.C_WL,
    'WN' => StatusCode.C_WN,
    'XK' => StatusCode.C_XK,
    'XX' => StatusCode.C_XX,
    'YG' => StatusCode.C_YG,
    'YK' => StatusCode.C_YK,
    'ZK' => StatusCode.C_ZK
  };

  private static final Map<StatusCode, String> STATUS_ENUM_TO_PICKLIST_VALUE = new Map<StatusCode, String>{
    StatusCode.C_AF => 'AF',
    StatusCode.C_AK => 'AK',
    StatusCode.C_AL => 'AL',
    StatusCode.C_AN => 'AN',
    StatusCode.C_BK => 'BK',
    StatusCode.C_BL => 'BL',
    StatusCode.C_BN => 'BN',
    StatusCode.C_CH => 'CH',
    StatusCode.C_CK => 'CK',
    StatusCode.C_CS => 'CS',
    StatusCode.C_DK => 'DK',
    StatusCode.C_DL => 'DL',
    StatusCode.C_DS => 'DS',
    StatusCode.C_DX => 'DX',
    StatusCode.C_EK => 'EK',
    StatusCode.C_FS => 'FS',
    StatusCode.C_GF => 'GF',
    StatusCode.C_GK => 'GK',
    StatusCode.C_GL => 'GL',
    StatusCode.C_GN => 'GN',
    StatusCode.C_GO => 'GO',
    StatusCode.C_HA => 'HA',
    StatusCode.C_HD => 'HD',
    StatusCode.C_HI => 'HI',
    StatusCode.C_HK => 'HK',
    StatusCode.C_HL => 'HL',
    StatusCode.C_HN => 'HN',
    StatusCode.C_HQ => 'HQ',
    StatusCode.C_HS => 'HS',
    StatusCode.C_HW => 'HW',
    StatusCode.C_HX => 'HX',
    StatusCode.C_IG => 'IG',
    StatusCode.C_IH => 'IH',
    StatusCode.C_IK => 'IK',
    StatusCode.C_IN => 'IN',
    StatusCode.C_IS => 'IS',
    StatusCode.C_IX => 'IX',
    StatusCode.C_KD => 'KD',
    StatusCode.C_KK => 'KK',
    StatusCode.C_KL => 'KL',
    StatusCode.C_LK => 'LK',
    StatusCode.C_LL => 'LL',
    StatusCode.C_MB => 'MB',
    StatusCode.C_MK => 'MK',
    StatusCode.C_ML => 'ML',
    StatusCode.C_MN => 'MN',
    StatusCode.C_MR => 'MR',
    StatusCode.C_NA => 'NA',
    StatusCode.C_NN => 'NN',
    StatusCode.C_NO => 'NO',
    StatusCode.C_NS => 'NS',
    StatusCode.C_OB => 'OB',
    StatusCode.C_OX => 'OX',
    StatusCode.C_PA => 'PA',
    StatusCode.C_PB => 'PB',
    StatusCode.C_PC => 'PC',
    StatusCode.C_PD => 'PD',
    StatusCode.C_PK => 'PK',
    StatusCode.C_PN => 'PN',
    StatusCode.C_PS => 'PS',
    StatusCode.C_PW => 'PW',
    StatusCode.C_RR => 'RR',
    StatusCode.C_SB => 'SB',
    StatusCode.C_SC => 'SC',
    StatusCode.C_SD => 'SD',
    StatusCode.C_SP => 'SP',
    StatusCode.C_SQ => 'SQ',
    StatusCode.C_SS => 'SS',
    StatusCode.C_TK => 'TK',
    StatusCode.C_TL => 'TL',
    StatusCode.C_TN => 'TN',
    StatusCode.C_UC => 'UC',
    StatusCode.C_UN => 'UN',
    StatusCode.C_US => 'US',
    StatusCode.C_UU => 'UU',
    StatusCode.C_WK => 'WK',
    StatusCode.C_WL => 'WL',
    StatusCode.C_WN => 'WN',
    StatusCode.C_XK => 'XK',
    StatusCode.C_XX => 'XX',
    StatusCode.C_YG => 'YG',
    StatusCode.C_YK => 'YK',
    StatusCode.C_ZK => 'ZK'
  };

  // Source: https://support.travelport.com/webhelp/uapi/Content/Air/Shared_Air_Topics/PNR_Status_Codes.htm
  public enum StatusCode {
    C_AF,
    C_AK,
    C_AL,
    C_AN,
    C_BK,
    C_BL,
    C_BN,
    C_CH,
    C_CK,
    C_CS,
    C_DK,
    C_DL,
    C_DS,
    C_DX,
    C_EK,
    C_FS,
    C_GF,
    C_GK,
    C_GL,
    C_GN,
    C_GO,
    C_HA,
    C_HD,
    C_HI,
    C_HK,
    C_HL,
    C_HN,
    C_HQ,
    C_HS,
    C_HW,
    C_HX,
    C_IG,
    C_IH,
    C_IK,
    C_IN,
    C_IS,
    C_IX,
    C_KD,
    C_KK,
    C_KL,
    C_LK,
    C_LL,
    C_MB,
    C_MK,
    C_ML,
    C_MN,
    C_MR,
    C_NA,
    C_NN,
    C_NO,
    C_NS,
    C_OB,
    C_OX,
    C_PA,
    C_PB,
    C_PC,
    C_PD,
    C_PK,
    C_PN,
    C_PS,
    C_PW,
    C_RR,
    C_SB,
    C_SC,
    C_SD,
    C_SP,
    C_SQ,
    C_SS,
    C_TK,
    C_TL,
    C_TN,
    C_UC,
    C_UN,
    C_US,
    C_UU,
    C_WK,
    C_WL,
    C_WN,
    C_XK,
    C_XX,
    C_YG,
    C_YK,
    C_ZK
  } // IN is reserved => C_XX

  // Source: https://support.travelport.com/webhelp/uapi/Content/Air/Shared_Air_Topics/PNR_Status_Codes.htm
  public Map<StatusCode, String> statusCodeToDescription = new Map<StatusCode, String>{
    StatusCode.C_AF => 'AA Advantage ticket',
    StatusCode.C_AK => 'Passive - Confirmed outside Galileo system (This is only applicable in 1G)',
    StatusCode.C_AL => 'Passive- Waitlisted outside Galileo system (This is only applicable in 1G)',
    StatusCode.C_AN => 'Passive- Requested outside Galileo system (This is only applicable in 1G)',
    StatusCode.C_BK => 'Passive- Booked with carrier. Will generate message to carrier when air segment is cancelled.',
    StatusCode.C_BL => 'Passive- Waitlist segment',
    StatusCode.C_BN => 'Requested outside Galileo system',
    StatusCode.C_CH => 'Passive- Code share holds confirmed',
    StatusCode.C_CK => 'Advance check-in. Boarding pass issued',
    StatusCode.C_CS => 'Code share sell segment',
    StatusCode.C_DK => 'Link book last seat',
    StatusCode.C_DL => 'Deferred waitlist',
    StatusCode.C_DS => 'Desires segment',
    StatusCode.C_DX => 'Passive - Broken marriage / Active-Authorized partial cancellation within a marriage',
    StatusCode.C_EK => 'EMD confirmed',
    StatusCode.C_FS => 'Free sale',
    StatusCode.C_GF => 'Firm booking',
    StatusCode.C_GK => 'Guaranteed/Merged. Also used in 1V as Passive - Group confirmed',
    StatusCode.C_GL => 'Waitlist with carrier',
    StatusCode.C_GN => 'Group booking',
    StatusCode.C_GO => 'No action taken on group request.',
    StatusCode.C_HA => 'Have requested. Airline requested one of their own segments',
    StatusCode.C_HD => 'Holding confirmed; EMD required',
    StatusCode.C_HI => 'Holding confirmed EMD issued (EMD can only be issued if Ticket is Issued)',
    StatusCode.C_HK => 'Holds confirmed',
    StatusCode.C_HL => 'Holds waitlist',
    StatusCode.C_HN => 'Holds need/confirmed',
    StatusCode.C_HQ => 'Space prev. request',
    StatusCode.C_HS => 'CO changes',
    StatusCode.C_HW => 'Have waitlisted. Airline waitlisted one of their own segments',
    StatusCode.C_HX => 'Cancel confirm hold',
    StatusCode.C_IG => 'Involuntary upgrade',
    StatusCode.C_IH => 'Inhibit status code',
    StatusCode.C_IK => 'Infant no seat',
    StatusCode.C_IN => 'If not holding need',
    StatusCode.C_IS => 'If not holding sell',
    StatusCode.C_IX => 'If holding cancel',
    StatusCode.C_KD => 'Issue EMD',
    StatusCode.C_KK => 'Carrier confirmed',
    StatusCode.C_KL => 'Waitlist confirmed',
    StatusCode.C_LK => 'Passive - Link booking - guaranteed sell',
    StatusCode.C_LL => 'Add to waitlist',
    StatusCode.C_MB => 'Move reaccommodation - Pax was on standby status for flight affected',
    StatusCode.C_MK => 'Non messaging Passive segment.',
    StatusCode.C_ML => 'Waitlisted',
    StatusCode.C_MN => 'Not available',
    StatusCode.C_MR => 'Requested',
    StatusCode.C_NA => 'Need alternate',
    StatusCode.C_NN => 'Requesting segment',
    StatusCode.C_NO => 'No action taken',
    StatusCode.C_NS => 'No show',
    StatusCode.C_OB => 'Overbook',
    StatusCode.C_OX => 'Cancel only if requested segment is available',
    StatusCode.C_PA => 'Priority waitlist-emergency travel',
    StatusCode.C_PB => 'Priority waitlist',
    StatusCode.C_PC => 'Priority waitlist',
    StatusCode.C_PD => 'Priority waitlist',
    StatusCode.C_PK => 'Discounted passenger.',
    StatusCode.C_PN => 'Pending need',
    StatusCode.C_PS => 'Passive',
    StatusCode.C_PW => 'Priority waitlist',
    StatusCode.C_RR => 'Reconfirm',
    StatusCode.C_SB => 'Boarded standBy',
    StatusCode.C_SC => 'Schedule change',
    StatusCode.C_SD => 'Schedule change/re-booking; EMD already issued. Document number must be included in the SSR',
    StatusCode.C_SP => 'Passive-space protected',
    StatusCode.C_SQ => 'Space request - bilateral use',
    StatusCode.C_SS => 'Sell segment',
    StatusCode.C_TK => 'Schedule Change. Advise passenger of new scheduled times.',
    StatusCode.C_TL => 'Schedule change waitlist. Advise passenger of new scheduled times.',
    StatusCode.C_TN => 'Schedule change. Is Pending Need. Advise passenger of new scheduled times.',
    StatusCode.C_UC => 'Unable to confirm or waitlist',
    StatusCode.C_UN => 'Unable - no flight',
    StatusCode.C_US => 'Unable to sell',
    StatusCode.C_UU => 'Unable to confirm. Waitlist requested',
    StatusCode.C_WK => 'Schedule change of a confirmed segment',
    StatusCode.C_WL => 'Schedule change of a waitlisted segment',
    StatusCode.C_WN => 'Schedule change of a needed segment',
    StatusCode.C_XK => 'Cancel seg with change',
    StatusCode.C_XX => 'Cancel segment',
    StatusCode.C_YG => 'Involuntary upgrade',
    StatusCode.C_YK => 'Hold confirmed Airline space',
    StatusCode.C_ZK => 'Passive- API booking'
  };

  @TestVisible
  private SegmentEvent() {
    this.underlyingSObject = new Segment_Event__c();
  }

  public SegmentEvent(Segment_Event__c se) {
    super(se);
    this.underlyingSObject = se;

    this.segmentId = se.Segment__c;
    this.newStatus = STATUS_PICKLIST_VALUE_TO_ENUM.get(se.New_Status__c);
    this.officeCode = se.Office_Code__c;
    this.operationType = OPERATION_TYPE_PICKLIST_VALUE_TO_ENUM.get(
      se.Operation_Type__c
    );
    this.previousStatus = STATUS_PICKLIST_VALUE_TO_ENUM.get(
      se.Previous_Status__c
    );
    this.updateDate = se.Update_Date__c;
    this.updateNumber = se.Update_Number__c;
  }

  public override void updateSObjectFields() {
    this.underlyingSObject.Segment__c = this.segmentId;
    this.underlyingSObject.New_Status__c = STATUS_ENUM_TO_PICKLIST_VALUE.get(
      this.newStatus
    );
    this.underlyingSObject.Office_Code__c = this.officeCode;
    this.underlyingSObject.Operation_Type__c = OPERATION_ENUM_TO_PICKLIST_VALUE.get(
      this.operationType
    );
    this.underlyingSObject.Previous_Status__c = STATUS_ENUM_TO_PICKLIST_VALUE.get(
      this.previousStatus
    );
    this.underlyingSObject.Update_Date__c = this.updateDate;
    this.underlyingSObject.Update_Number__c = this.updateNumber;
  }

  public Boolean equals(Object other) {
    SegmentEvent otherSe = (SegmentEvent) other;
    if (
      this.operationType == otherSe.operationType &&
      this.newStatus == otherse.newStatus &&
      this.updateNumber == otherSe.updateNumber
    ) {
      return true;
    }

    return false;
  }

  public Integer compareTo(Object other) {
    SegmentEvent otherSe = (SegmentEvent) other;

    Integer toReturn = 0;

    if (otherSe == null) {
      return 1;
    }

    if (this.updateDate > otherSe.updateDate) {
      return 1;
    } else if (this.updateDate < otherSe.updateDate) {
      return -1;
    } else {
      if (otherSe.updateDate == null) {
        return 1;
      } else if (this.updateNumber == null) {
        return -1;
      } else if (this.updateNumber > otherSe.updateNumber) {
        return 1;
      } else if (this.updateNumber < otherSe.updateNumber) {
        return -1;
      } else {
        return 0;
      }
    }
  }

  // TODO: Refactor to make non static (issues connected to Trip and EU261claim)
  public static Boolean customerResponsibleForEvent(String officeResponsible) {
    if (officeResponsible == null || officeResponsible.length() < 4) {
      return null;
    }

    String countryNonSpecificCode = officeResponsible.substring(3);

    return OFFICE_CODE_TO_IS_CUSTOMER.get(countryNonSpecificCode);
  }

  // TODO: Refactor to make non static (issues connected to Trip and EU261claim)
  public static String getOfficeCodeExplanation(String officeResponsible) {
    if (officeResponsible == null || officeResponsible.length() < 4) {
      return null;
    }

    String countryNonSpecificCode = officeResponsible.substring(3);

    return OFFICE_CODE_TO_EXPLANATION.get(countryNonSpecificCode);
  }
  public static OperationType getOperationTypeFromPicklistValue(
    String picklistValue
  ) {
    return OPERATION_TYPE_PICKLIST_VALUE_TO_ENUM.get(picklistValue);
  }
  public static StatusCode getStatusCodeFromPicklistValue(
    String picklistValue
  ) {
    return STATUS_PICKLIST_VALUE_TO_ENUM.get(picklistValue);
  }
}
