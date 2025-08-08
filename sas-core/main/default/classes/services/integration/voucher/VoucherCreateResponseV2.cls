public with sharing class VoucherCreateResponseV2 {
  public List<Voucher> vouchers;
  public String description;
  public String link;
  public String expiry;
  public String caseId;

  public class Voucher {
    public String id;
    public String voucherNumber;
    public String expiry;
  }

  public static Map<String, String> replacementMap = new Map<String, String>{
    'number' => 'voucherNumber'
  };

  public static VoucherCreateResponseV2 parse(String response) {
    ffhttp_JsonDeserializer jsonDeserializer = new ffhttp_JsonDeserializer(
      VoucherCreateResponseV2.class,
      replacementMap
    );
    return (VoucherCreateResponseV2) jsonDeserializer.deserialize(response);
  }

  public static List<VoucherCreateResponseV2> parseArray(String response) {
    ffhttp_JsonDeserializer jsonDeserializer = new ffhttp_JsonDeserializer(
      List<VoucherCreateResponseV2>.class,
      replacementMap
    );
    return (List<VoucherCreateResponseV2>) jsonDeserializer.deserialize(
      response
    );
  }
}
