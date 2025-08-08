@IsTest
public with sharing class FetchCAREClaimsResponse_Test {
  @IsTest
  public static void oneCases() {
    String s = '{"status": "SUCCESS","response": {"cases": {"case": {"settlements": {"settlement": {"amount": 4193,"settlementItem": {"stiAmount": 4193,"stiEurobonusPoints": 0,"stiVoucherSubtype": "","stiCusId": 1632164,"stiComments": "","stiCostAcc": 855},"amountInSEK": 4193,"type": 858,"controlState": 874,"csCategory": 542,"bankDetails": "banks","dateCreated": "2022-08-10T13:48:40Z","dateApproved": "2022-08-10T13:49:11Z","caseId": 2152349,"catName": "Complaint","customerId": 1632164,"currency": 1066}},"notes": {"note": [{"noteSeq": 0,"caseId": 2152349,"customerId": 1632164,"noteValue": "a"},{"noteSeq": 1,"caseId": 2152349,"customerId": 1632164,"noteValue": "b"},{"noteSeq": 2,"caseId": 2152349,"customerId": 1632164,"noteValue": "c"},{"noteSeq": 3,"caseId": 2152349,"customerId": 1632164,"noteValue": "d"},{"noteSeq": 4,"caseId": 2152349,"customerId": 1632164,"noteValue": "e"},{"noteSeq": 0,"caseId": 2152349,"customerId": 1632165,"noteValue": "f"},{"noteSeq": 1,"caseId": 2152349,"customerId": 1632165,"noteValue": "g"},{"noteSeq": 2,"caseId": 2152349,"customerId": 1632165,"noteValue": "h"},{"noteSeq": 3,"caseId": 2152349,"customerId": 1632165,"noteValue": "i"},{"noteSeq": 4,"caseId": 2152349,"customerId": 1632165,"noteValue": "j"},{"noteSeq": 0,"caseId": 2152349,"customerId": 1632166,"noteValue": "k"},{"noteSeq": 1,"caseId": 2152349,"customerId": 1632166,"noteValue": "l"},{"noteSeq": 2,"caseId": 2152349,"customerId": 1632166,"noteValue": "m"},{"noteSeq": 3,"caseId": 2152349,"customerId": 1632166,"noteValue": "n"},{"noteSeq": 4,"caseId": 2152349,"customerId": 1632166,"noteValue": "o"}]},"flightDate": "2022-06-04T00:00:00Z","pnrs": {"pnr": {"pnrId": 554830,"pnr": "QIW85C","caseId": 2152349}},"dateClosed": "2022-08-10T14:41:33Z","flightNumber": "SK1583","dateCreated": "2022-06-12T20:10:19Z","pnr": "QIW85C","caseId": 2152349,"pir": "AGPSK15731","decisions": {"decision": [{"dicCode": 146,"dczId": 949951,"caseId": 2152349,"customerId": 1632164,"dicName": "Claim paid in full","dicType": "APL"},{"dicCode": 146,"dczId": 949951,"caseId": 2152349,"customerId": 1632165,"dicName": "Claim paid in full","dicType": "APL"},{"dicCode": 146,"dczId": 949951,"caseId": 2152349,"customerId": 1632166,"dicName": "Claim paid in full","dicType": "APL"}]},"lastModified": "2022-08-12T18:01:26.663Z","customers": {"customer": [{"cusPirId": 173272,"caseId": 2152349,"customerId": 1632164,"cusFirstname": "per","cusLastname": "prentell","cusPnrId": ""},{"cusPirId": "","caseId": 2152349,"customerId": 1632165,"cusFirstname": "AGNETA","cusLastname": "PRENTELL","cusPnrId": 554830},{"cusPirId": "","caseId": 2152349,"customerId": 1632166,"cusFirstname": "PER","cusLastname": "PRENTELL","cusPnrId": 554830}]},"categories": {"category": [{"catId": 542,"caseId": 2152349,"customerId": 1632164,"CatName": "Complaint"},{"catId": 542,"caseId": 2152349,"customerId": 1632165,"CatName": "Complaint"},{"catId": 542,"caseId": 2152349,"customerId": 1632166,"CatName": "Complaint"}]}}}}}';

    FetchCAREClaimsResponse resp = FetchCAREClaimsResponse.parse(s);

    System.assertEquals('2152349', resp.response.cases[0].caseId);
  }

  @IsTest
  public static void twoCases() {
    String s = '{"status": "SUCCESS","response": {"cases": {"case": [{"settlements": {"settlement": {"amount": 5494,"settlementItem": [{"stiAmount": 2747,"stiEurobonusPoints": 0,"stiVoucherSubtype": "","stiCusId": 1632089,"stiComments": "","stiCostAcc": 851},{"stiAmount": 2747,"stiEurobonusPoints": 0,"stiVoucherSubtype": "","stiCusId": 1632090,"stiComments": "","stiCostAcc": 851}],"amountInSEK": 7886.19,"type": 858,"controlState": 874,"csCategory": 159,"bankDetails": "ders","dateCreated": "2022-06-29T14:00:32Z","dateApproved": "2022-07-28T09:30:34Z","caseId": 2152305,"catName": "Complaint","customerId": 1632089,"currency": 1067}},"notes": {"note": [{"noteSeq": 0,"caseId": 2152305,"customerId": 1632089,"noteValue": "w"},{"noteSeq": 1,"caseId": 2152305,"customerId": 1632089,"noteValue": "w"},{"noteSeq": 2,"caseId": 2152305,"customerId": 1632089,"noteValue": "w"},{"noteSeq": 3,"caseId": 2152305,"customerId": 1632089,"noteValue": "W"},{"noteSeq": 0,"caseId": 2152305,"customerId": 1632090,"noteValue": "w"},{"noteSeq": 1,"caseId": 2152305,"customerId": 1632090,"noteValue": "w"},{"noteSeq": 2,"caseId": 2152305,"customerId": 1632090,"noteValue": "w"},{"noteSeq": 3,"caseId": 2152305,"customerId": 1632090,"noteValue": "w"}]},"flightDate": "2022-06-11T00:00:00Z","pnrs": "","dateClosed": "2022-07-28T15:12:53Z","flightNumber": "SK2823","dateCreated": "2022-06-12T18:20:39Z","pnr": "L22OJX","caseId": 2152305,"pir": "","decisions": {"decision": [{"dicCode": 381,"dczId": 936218,"caseId": 2152305,"customerId": 1632089,"dicName": "Return - More info","dicType": "APL"},{"dicCode": 381,"dczId": 936218,"caseId": 2152305,"customerId": 1632090,"dicName": "Return - More info","dicType": "APL"}]},"lastModified": "2022-08-15T18:02:18.953Z","customers": {"customer": [{"cusPirId": "","caseId": 2152305,"customerId": 1632089,"cusFirstname": "Karina","cusLastname": "Nielsen","cusPnrId": ""},{"cusPirId": "","caseId": 2152305,"customerId": 1632090,"cusFirstname": "Betina","cusLastname": "Frendstrup Egedal","cusPnrId": ""}]},"categories": {"category": [{"catId": 159,"caseId": 2152305,"customerId": 1632089,"CatName": "Complaint"},{"catId": 159,"caseId": 2152305,"customerId": 1632090,"CatName": "Complaint"}]}},{"settlements": "","notes": {"note": [{"noteSeq": 0,"caseId": 2156567,"customerId": 1638569,"noteValue": "claim given under case id -2156568"},{"noteSeq": 0,"caseId": 2156567,"customerId": 1638569,"noteValue": "E"},{"noteSeq": 1,"caseId": 2156567,"customerId": 1638569,"noteValue": "e"},{"noteSeq": 2,"caseId": 2156567,"customerId": 1638569,"noteValue": "e"},{"noteSeq": 3,"caseId": 2156567,"customerId": 1638569,"noteValue": "e"},{"noteSeq": 0,"caseId": 2156567,"customerId": 1638570,"noteValue": "e"},{"noteSeq": 0,"caseId": 2156567,"customerId": 1638570,"noteValue": "e"},{"noteSeq": 1,"caseId": 2156567,"customerId": 1638570,"noteValue": "e"},{"noteSeq": 2,"caseId": 2156567,"customerId": 1638570,"noteValue": "e"},{"noteSeq": 3,"caseId": 2156567,"customerId": 1638570,"noteValue": "e"},{"noteSeq": 0,"caseId": 2156567,"customerId": 1638571,"noteValue": "e"},{"noteSeq": 0,"caseId": 2156567,"customerId": 1638571,"noteValue": "e"},{"noteSeq": 1,"caseId": 2156567,"customerId": 1638571,"noteValue": "e"},{"noteSeq": 2,"caseId": 2156567,"customerId": 1638571,"noteValue": "e"},{"noteSeq": 3,"caseId": 2156567,"customerId": 1638571,"noteValue": "e"}]},"flightDate": "2022-06-11T00:00:00Z","pnrs": "","dateClosed": "2022-07-25T09:15:26Z","flightNumber": "SK2823","dateCreated": "2022-06-21T09:03:46Z","pnr": "L22OJX","caseId": 2156567,"pir": "","decisions": {"decision": [{"dicCode": 239,"dczId": 940354,"caseId": 2156567,"customerId": 1638569,"dicName": "Duplicate case","dicType": "APL"},{"dicCode": 239,"dczId": 940354,"caseId": 2156567,"customerId": 1638570,"dicName": "Duplicate case","dicType": "APL"},{"dicCode": 239,"dczId": 940354,"caseId": 2156567,"customerId": 1638571,"dicName": "Duplicate case","dicType": "APL"}]},"lastModified": "2022-08-15T18:02:18.953Z","customers": {"customer": [{"cusPirId": "","caseId": 2156567,"customerId": 1638569,"cusFirstname": "Birte Alsing","cusLastname": "Petersen","cusPnrId": ""},{"cusPirId": "","caseId": 2156567,"customerId": 1638570,"cusFirstname": "KIRSTEN ARREBOE","cusLastname": "HELBIRK","cusPnrId": ""},{"cusPirId": "","caseId": 2156567,"customerId": 1638571,"cusFirstname": "MAJA","cusLastname": "GILSAGER","cusPnrId": ""}]},"categories": {"category": [{"catId": 159,"caseId": 2156567,"customerId": 1638569,"CatName": "Complaint"},{"catId": 159,"caseId": 2156567,"customerId": 1638570,"CatName": "Complaint"},{"catId": 159,"caseId": 2156567,"customerId": 1638571,"CatName": "Complaint"}]}}]}}}';

    FetchCAREClaimsResponse resp = FetchCAREClaimsResponse.parse(s);

    System.assertEquals(2, resp.response.cases.size());

    System.assertEquals('2152305', resp.response.cases[0].caseId);
    System.assertEquals('L22OJX', resp.response.cases[0].pnr);
    System.assertEquals(
      Datetime.valueOfGMT('2022-06-11 00:00:00'),
      resp.response.cases[0].flightDate
    );
    System.assertEquals(
      Datetime.valueOfGMT('2022-07-28 15:12:53'),
      resp.response.cases[0].dateClosed
    );
    System.assertEquals(
      Datetime.valueOfGMT('2022-06-12 18:20:39'),
      resp.response.cases[0].dateCreated
    );
    System.assertEquals(
      Datetime.valueOfGMT('2022-08-15 18:02:18.953'),
      resp.response.cases[0].lastModified
    );
    System.assertEquals('2152305', resp.response.cases[0].caseId);
    System.assertEquals('SK2823', resp.response.cases[0].flightNumber);
    System.assertEquals('', resp.response.cases[0].pir);

    System.assertEquals(8, resp.response.cases[0].notes.size());
    System.assertEquals(2, resp.response.cases[0].notes[2].noteSeq);
    System.assertEquals('w', resp.response.cases[0].notes[2].noteValue);

    System.assertEquals(2, resp.response.cases[0].decisions.size());
    System.assertEquals('936218', resp.response.cases[0].decisions[1].dczId);

    System.assertEquals(2, resp.response.cases[0].customers.size());
    System.assertEquals(
      '1632090',
      resp.response.cases[0].customers[1].customerId
    );

    System.assertEquals(1, resp.response.cases[0].settlements.size());
    System.assertEquals(
      2,
      resp.response.cases[0].settlements[0].settlementItems.size()
    );
    System.assertEquals(
      '1632090',
      resp.response.cases[0].customers[1].customerId
    );

    System.assertEquals('2156567', resp.response.cases[1].caseId);
  }

  @IsTest
  public static void twoSettlementsNoNotes() {
    String s = '{"status": "SUCCESS","response": {"cases": {"case": {"settlements": {"settlement": [{"amount": 5494,"settlementItem": [{"stiAmount": 2747,"stiEurobonusPoints": 0,"stiVoucherSubtype": "","stiCusId": 1632089,"stiComments": "","stiCostAcc": 851},{"stiAmount": 2747,"stiEurobonusPoints": 0,"stiVoucherSubtype": "","stiCusId": 1632090,"stiComments": "","stiCostAcc": 851}],"amountInSEK": 7886.19,"type": 858,"controlState": 874,"csCategory": 159,"bankDetails": "ders","dateCreated": "2022-06-29T14:00:32Z","dateApproved": "2022-07-28T09:30:34Z","caseId": 2152305,"catName": "Complaint","customerId": 1632089,"currency": 1067},{"amount": 5494,"settlementItem": {"stiAmount": 2747,"stiEurobonusPoints": 0,"stiVoucherSubtype": "","stiCusId": 1632089,"stiComments": "","stiCostAcc": 851},"amountInSEK": 7886.19,"type": 858,"controlState": 874,"csCategory": 159,"bankDetails": "ders","dateCreated": "2022-06-29T14:00:32Z","dateApproved": "2022-07-28T09:30:34Z","caseId": 2152305,"catName": "Complaint","customerId": 1632089,"currency": 1067}]},"notes": "","flightDate": "2022-06-11T00:00:00Z","pnrs": "","dateClosed": "2022-07-28T15:12:53Z","flightNumber": "SK2823","dateCreated": "2022-06-12T18:20:39Z","pnr": "L22OJX","caseId": 2152305,"pir": "","decisions": {"decision": [{"dicCode": 381,"dczId": 936218,"caseId": 2152305,"customerId": 1632089,"dicName": "Return - More info","dicType": "APL"},{"dicCode": 381,"dczId": 936218,"caseId": 2152305,"customerId": 1632090,"dicName": "Return - More info","dicType": "APL"}]},"lastModified": "2022-08-15T18:02:18.953Z","customers": {"customer": [{"cusPirId": "","caseId": 2152305,"customerId": 1632089,"cusFirstname": "Karina","cusLastname": "Nielsen","cusPnrId": ""},{"cusPirId": "","caseId": 2152305,"customerId": 1632090,"cusFirstname": "Betina","cusLastname": "Frendstrup Egedal","cusPnrId": ""}]},"categories": {"category": [{"catId": 159,"caseId": 2152305,"customerId": 1632089,"CatName": "Complaint"},{"catId": 159,"caseId": 2152305,"customerId": 1632090,"CatName": "Complaint"}]}}}}}';

    FetchCAREClaimsResponse resp = FetchCAREClaimsResponse.parse(s);

    System.assertEquals(1, resp.response.cases.size());
    System.assertEquals(2, resp.response.cases[0].settlements.size());
    System.assertEquals(2, resp.response.cases[0].customers.size());
    System.assertEquals(2, resp.response.cases[0].decisions.size());
    System.assertEquals(2, resp.response.cases[0].categories.size());
    System.assertEquals(0, resp.response.cases[0].notes.size());

    System.assertEquals(
      2,
      resp.response.cases[0].settlements[0].settlementItems.size()
    );

    System.assertEquals(
      1,
      resp.response.cases[0].settlements[1].settlementItems.size()
    );
  }
}
