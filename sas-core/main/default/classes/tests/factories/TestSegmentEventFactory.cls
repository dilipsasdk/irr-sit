@IsTest
public with sharing class TestSegmentEventFactory {
  public static SegmentEvent create(
    Segment s,
    SegmentEvent.StatusCode newStatus,
    SegmentEvent.OperationType operationType,
    Datetime updateDate,
    SegmentEvent previous
  ) {
    SegmentEvent se = new SegmentEvent();

    se.segmentId = s.Id;

    se.officeCode = 'STOSK00OC';
    se.newStatus = newStatus;
    se.operationType = operationType;
    se.updateDate = updateDate;

    if (previous != null) {
      se.previousStatus = previous.newStatus;
    }

    return se;
  }

  /*
    Based on an example segment from EDW:
    res_id;res_crea_dte;off_cd;staff_pnr;res_upd_tms;office_updating;seg_tattoo;record_opr_type;res_upd_no;action_cd;prev_action_cd;flt_airl_cd;flt_nb;stn_fr_cd;stn_to_cd;dep_dte;opr_bkg_cl;opr_svc_cl;arr_dte;seg_status;aircraft_registration;flt_status;std_tms;sta_tms;etd_tms;eta_tms;atd_tms;ata_tms;arrival_delay_mins;dep_delay_mins;change_reason;is_latest
    "P6YFBJ ";2022-09-03;LUXSK08RV;N;2022-09-03 09:43:00;LUXSK08RV;1;"A ";0;HK;"  ";"SK ";1560;"CDG  ";"CPH  ";2022-10-09;V;M;2022-10-09;ACTIVE;"LNRGL   ";X;2022-10-09 18:05:00;2022-10-09 19:50:00;NULL;NULL;NULL;NULL;NULL;NULL;TECH;0
    "P6YFBJ ";2022-09-03;LUXSK08RV;N;2022-09-03 09:44:00;LUXSK08RV;1;"C ";2;HK;HK;"SK ";1560;"CDG  ";"CPH  ";2022-10-09;V;M;2022-10-09;ACTIVE;"LNRGL   ";X;2022-10-09 18:05:00;2022-10-09 19:50:00;NULL;NULL;NULL;NULL;NULL;NULL;TECH;0
    "P6YFBJ ";2022-09-03;LUXSK08RV;N;2022-10-09 10:09:00;STOSK00OC;1;"C ";6;UN;HK;"SK ";1560;"CDG  ";"CPH  ";2022-10-09;V;M;2022-10-09;CANCELLED;"LNRGL   ";X;2022-10-09 18:05:00;2022-10-09 19:50:00;NULL;NULL;NULL;NULL;NULL;NULL;TECH;1
    
    "P6YFBJ ";2022-09-03;LUXSK08RV;N;2022-10-09 10:09:00;STOSK00OC;2;"A ";6;TK;"  ";"SK ";1560;"CDG  ";"CPH  ";2022-10-10;V;M;2022-10-10;ACTIVE;"OYKAU   ";F;2022-10-10 17:45:00;2022-10-10 19:30:00;NULL;2022-10-10 19:33:00;2022-10-10 17:54:00;2022-10-10 19:38:00;8;9;"    ";1
  */
  public static List<SegmentEvent> createForDefaultCancellation(
    Segment s,
    Datetime timeAdded,
    Datetime timeCancelled
  ) {
    List<SegmentEvent> events = new List<SegmentEvent>{};
    SegmentEvent se1 = create(
      s,
      SegmentEvent.StatusCode.C_HK,
      SegmentEvent.OperationType.C_A,
      timeAdded,
      null
    );
    SegmentEvent se2 = create(
      s,
      SegmentEvent.StatusCode.C_HK,
      SegmentEvent.OperationType.C_C,
      timeAdded.addSeconds(60),
      se1
    );
    SegmentEvent se3 = create(
      s,
      SegmentEvent.StatusCode.C_UN,
      SegmentEvent.OperationType.C_C,
      timeCancelled,
      se2
    );

    events.addAll(new List<SegmentEvent>{ se1, se2, se3 });

    return events;
  }

  // Based on an example segment from EDW
  public static List<SegmentEvent> createForDefaultConfirmed(
    Segment s,
    Datetime timeAdded
  ) {
    List<SegmentEvent> events = new List<SegmentEvent>{};
    SegmentEvent se1 = create(
      s,
      SegmentEvent.StatusCode.C_HK,
      SegmentEvent.OperationType.C_A,
      timeAdded,
      null
    );
    SegmentEvent se2 = create(
      s,
      SegmentEvent.StatusCode.C_HK,
      SegmentEvent.OperationType.C_C,
      timeAdded.addSeconds(60),
      se1
    );

    events.addAll(new List<SegmentEvent>{ se1, se2 });

    return events;
  }

  // Based on an example segment from EDW
  public static List<SegmentEvent> createForDefaultReplacement(
    Segment s,
    Datetime timeAdded
  ) {
    List<SegmentEvent> events = new List<SegmentEvent>{};
    SegmentEvent se1 = create(
      s,
      SegmentEvent.StatusCode.C_TK,
      SegmentEvent.OperationType.C_A,
      timeAdded,
      null
    );

    events.addAll(new List<SegmentEvent>{ se1 });

    return events;
  }

  /**
    Based on an example segment from EDW:
    res_id;res_crea_dte;off_cd;staff_pnr;res_upd_tms;office_updating;seg_tattoo;record_opr_type;res_upd_no;action_cd;prev_action_cd;flt_airl_cd;flt_nb;stn_fr_cd;stn_to_cd;dep_dte;opr_bkg_cl;opr_svc_cl;arr_dte;seg_status;aircraft_registration;flt_status;std_tms;sta_tms;etd_tms;eta_tms;atd_tms;ata_tms;arrival_delay_mins;dep_delay_mins;change_reason;is_latest
    
    "P6MIGO ";2022-06-01;BLLWT28AA;N;2022-06-01 08:04:00;BLLWT28AA;1;"A ";0;HK;"  ";"SK ";2961;"CPH  ";"FLR  ";2022-06-26;E;M;2022-06-26;ACTIVE;"SEROS   ";F;2022-06-26 11:35:00;2022-06-26 13:55:00;NULL;2022-06-26 14:11:00;2022-06-26 12:00:00;2022-06-26 14:12:00;17;25;"    ";0
    "P6MIGO ";2022-06-01;BLLWT28AA;N;2022-06-01 08:33:00;CPHWT2181;1;"C ";8;HK;HK;"SK ";2961;"CPH  ";"FLR  ";2022-06-26;E;M;2022-06-26;ACTIVE;"SEROS   ";F;2022-06-26 11:35:00;2022-06-26 13:55:00;NULL;2022-06-26 14:11:00;2022-06-26 12:00:00;2022-06-26 14:12:00;17;25;"    ";1
    
    "P6MIGO ";2022-06-01;BLLWT28AA;N;2022-06-01 08:04:00;BLLWT28AA;2;"A ";0;HK;"  ";"SK ";2962;"FLR  ";"CPH  ";2022-07-07;K;M;2022-07-07;ACTIVE;"SEROK   ";X;2022-07-07 14:50:00;2022-07-07 17:00:00;NULL;NULL;NULL;NULL;NULL;NULL;INDU;0
    "P6MIGO ";2022-06-01;BLLWT28AA;N;2022-06-01 08:33:00;CPHWT2181;2;"C ";8;HK;HK;"SK ";2962;"FLR  ";"CPH  ";2022-07-07;K;M;2022-07-07;ACTIVE;"SEROK   ";X;2022-07-07 14:50:00;2022-07-07 17:00:00;NULL;NULL;NULL;NULL;NULL;NULL;INDU;0
    "P6MIGO ";2022-06-01;BLLWT28AA;N;2022-07-06 13:58:00;CPHWT2621;2;"X ";24;XX;HK;"SK ";2962;"FLR  ";"CPH  ";2022-07-07;K;NULL;2022-07-07;CANCELLED;"SEROK   ";X;2022-07-07 14:50:00;2022-07-07 17:00:00;NULL;NULL;NULL;NULL;NULL;NULL;INDU;1
   */
  public static List<SegmentEvent> createForRemovedNotCancelled(
    Segment s,
    Datetime timeAdded,
    Datetime timeRemoved
  ) {
    List<SegmentEvent> events = new List<SegmentEvent>{};
    SegmentEvent se1 = create(
      s,
      SegmentEvent.StatusCode.C_HK,
      SegmentEvent.OperationType.C_A,
      timeAdded,
      null
    );
    SegmentEvent se2 = create(
      s,
      SegmentEvent.StatusCode.C_HK,
      SegmentEvent.OperationType.C_C,
      timeAdded.addMinutes(30),
      se1
    );
    SegmentEvent se3 = create(
      s,
      SegmentEvent.StatusCode.C_XX,
      SegmentEvent.OperationType.C_X,
      timeRemoved,
      se2
    );

    events.addAll(new List<SegmentEvent>{ se1, se2, se3 });

    return events;
  }

  /**
    Based on an example segment from EDW:
    2022-03-29 17:36:00     ORD       CPH             3              A            0        HK                    2022-07-07 2022-07-08
    2022-03-29 17:41:00     ORD       CPH             3              C            2        HK             HK     2022-07-07 2022-07-08
    2022-07-06 19:46:00     ORD       CPH             3              C           25        UN             HK     2022-07-07 2022-07-08
    2022-07-06 21:34:00     ORD       CPH             3              X           40        UN             UN     2022-07-07 2022-07-08 
   */
  public static List<SegmentEvent> createForDoubleUnconfirmed(
    Segment s,
    Datetime timeAdded,
    Datetime timeCancelled
  ) {
    List<SegmentEvent> events = new List<SegmentEvent>{};
    Datetime timeRemoved = timeCancelled.addHours(2);
    SegmentEvent se1 = create(
      s,
      SegmentEvent.StatusCode.C_HK,
      SegmentEvent.OperationType.C_A,
      timeAdded,
      null
    );
    SegmentEvent se2 = create(
      s,
      SegmentEvent.StatusCode.C_HK,
      SegmentEvent.OperationType.C_C,
      timeAdded.addMinutes(30),
      se1
    );
    SegmentEvent se3 = create(
      s,
      SegmentEvent.StatusCode.C_UN,
      SegmentEvent.OperationType.C_C,
      timeCancelled,
      se2
    );
    SegmentEvent se4 = create(
      s,
      SegmentEvent.StatusCode.C_UN,
      SegmentEvent.OperationType.C_X,
      timeRemoved,
      se3
    );

    events.addAll(new List<SegmentEvent>{ se1, se2, se3, se4 });

    return events;
  }

  /**
    Based on an example segment from EDW:
    2022-03-10 15:12:00     TRD       OSL             1              A           1         HK             HK           NaN 2022-06-22 2022-06-22
    2022-06-22 07:29:00     TRD       OSL             1              C           24        TK             HK               2022-06-22 2022-06-22
    2022-06-22 07:29:00     TRD       OSL             1              C           25        UC             TK               2022-06-22 2022-06-22
   */
  public static List<SegmentEvent> createWithUnableToConfirm(
    Segment s,
    Datetime timeAdded
  ) {
    List<SegmentEvent> events = new List<SegmentEvent>{};
    SegmentEvent se1 = create(
      s,
      SegmentEvent.StatusCode.C_HK,
      SegmentEvent.OperationType.C_A,
      timeAdded,
      null
    );
    SegmentEvent se2 = create(
      s,
      SegmentEvent.StatusCode.C_TK,
      SegmentEvent.OperationType.C_C,
      timeAdded.addDays(90),
      se1
    );
    SegmentEvent se3 = create(
      s,
      SegmentEvent.StatusCode.C_UC,
      SegmentEvent.OperationType.C_C,
      timeAdded.addDays(90),
      se2
    );

    events.addAll(new List<SegmentEvent>{ se1, se2, se3 });

    return events;
  }

  /**
    Based on an example segment from EDW:
    TI829V  2022-08-12 14:22:00     CPH       EDI            10              A            1        GK                          NaN 2022-08-19 2022-08-19
   */
  public static List<SegmentEvent> createGroup(
    Segment s,
    Datetime timeAdded
  ) {
    List<SegmentEvent> events = new List<SegmentEvent>{};
    SegmentEvent se1 = create(
      s,
      SegmentEvent.StatusCode.C_GK,
      SegmentEvent.OperationType.C_A,
      timeAdded,
      null
    );


    events.addAll(new List<SegmentEvent>{ se1 });

    return events;
  }
}
