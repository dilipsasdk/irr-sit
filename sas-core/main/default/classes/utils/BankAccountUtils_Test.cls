@IsTest
private class BankAccountUtils_Test {
  @IsTest
  static void shouldInvalidateIBANAndReturnFalse() {
    // Given
    // Last entry especially important, Icelandic number but in a valid Slovenian format
    List<List<String>> invalidIBANList = new List<List<String>>{
      new List<String>{ 'AL35202111090000000004234567', 'Albania' },
      new List<String>{ 'AD1400080001001234267890', 'Andorra' },
      new List<String>{ 'AT483200000016345864', 'Austria' },
      new List<String>{ 'AZ96AZEJ00000000004234567890', 'Azerbaijan' },
      new List<String>{ 'BH02GITI00001077181611', 'Bahrain' },
      new List<String>{ 'IS19192001234567892', 'Slovenia' }
    };
    // When
    List<Boolean> results = new List<Boolean>();
    for (List<String> bankDetails : invalidIBANList) {
      try {
        results.add(
          BankAccountUtils.validateIBAN(
            bankDetails[0],
            bankDetails[1],
            'AXISINBB002'
          )
        );
      } catch (Exception e) {
        results.add(false);
      }
    }

    // Then
    for (Boolean res : results) {
      System.assert(
        !res,
        'Function validated (returned true) an invalid IBAN number'
      );
    }
  }

  @IsTest
  static void shouldValidateIBANAndReturnTrue() {
    // Should we validate "partial IBAN countries"? https://www.iban.com/structure
    // Given
    List<List<String>> validIBANList = new List<List<String>>{
      new List<String>{ 'AL35202111090000000001234567', 'Albania' },
      new List<String>{ 'AD1400080001001234567890', 'Andorra' },
      new List<String>{ 'AT483200000012345864', 'Austria' },
      new List<String>{ 'AZ96AZEJ00000000001234567890', 'Azerbaijan' },
      new List<String>{ 'BH02CITI00001077181611', 'Bahrain' },
      new List<String>{ 'BY86AKBB10100000002966000000', 'Belarus' },
      new List<String>{ 'BE71096123456769', 'Belgium' },
      new List<String>{ 'BA393385804800211234', 'Bosnia and Herzegovina' },
      new List<String>{ 'BG18RZBB91550123456789', 'Bulgaria' },
      new List<String>{ 'CR23015108410026012345', 'Costa Rica' },
      new List<String>{ 'HR1723600001101234565', 'Croatia' },
      new List<String>{ 'CY21002001950000357001234567', 'Cyprus' },
      new List<String>{ 'CZ5508000000001234567899', 'Czech Republic' },
      new List<String>{ 'DK9520000123456789', 'Denmark' },
      new List<String>{ 'DO22ACAU00000000000123456789', 'Dominican Republic' },
      new List<String>{ 'EE471000001020145685', 'Estonia' },
      new List<String>{ 'FO9264600123456789', 'Faroe Islands' },
      new List<String>{ 'FI1410093000123458', 'Finland' },
      new List<String>{ 'FR7630006000011234567890189', 'France' },
      new List<String>{ 'GE60NB0000000123456789', 'Georgia' },
      new List<String>{ 'DE75512108001245126199', 'Germany' },
      new List<String>{ 'GI04BARC000001234567890', 'Gibraltar' },
      new List<String>{ 'GR9608100010000001234567890', 'Greece' },
      new List<String>{ 'GL8964710123456789', 'Greenland' },
      new List<String>{ 'VA59001123000012345678', 'Vatican City' },
      new List<String>{ 'HU93116000060000000012345676', 'Hungary' },
      new List<String>{ 'IS750001121234563108962099', 'Iceland' },
      new List<String>{ 'IQ20CBIQ861800101010500', 'Iraq' },
      new List<String>{ 'IE64IRCE92050112345678', 'Ireland' },
      new List<String>{ 'IL170108000000012612345', 'Israel' },
      new List<String>{ 'IT60X0542811101000000123456', 'Italy' },
      new List<String>{ 'JO71CBJO0000000000001234567890', 'Jordan' },
      new List<String>{ 'KZ563190000012344567', 'Kazakhstan' },
      new List<String>{ 'KW81CBKU0000000000001234560101', 'Kuwait' },
      new List<String>{ 'LV97HABA0012345678910', 'Latvia' },
      new List<String>{ 'LB92000700000000123123456123', 'Lebanon' },
      new List<String>{ 'LI7408806123456789012', 'Liechtenstein' },
      new List<String>{ 'LT601010012345678901', 'Lithuania' },
      new List<String>{ 'LU120010001234567891', 'Luxembourg' },
      new List<String>{ 'MT31MALT01100000000000000000123', 'Malta' },
      new List<String>{ 'MR1300020001010000123456753', 'Mauritania' },
      new List<String>{ 'MU43BOMM0101123456789101000MUR', 'Mauritius' },
      new List<String>{ 'MD21EX000000000001234567', 'Moldova' },
      new List<String>{ 'MC5810096180790123456789085', 'Monaco' },
      new List<String>{ 'ME25505000012345678951', 'Montenegro' },
      new List<String>{ 'NL02ABNA0123456789', 'Netherlands' },
      new List<String>{ 'MK07200002785123453', 'North Macedonia' },
      new List<String>{ 'NO8330001234567', 'Norway' },
      new List<String>{ 'PS92PALS000000000400123456702', 'Palestine' },
      new List<String>{ 'PL10105000997603123456789123', 'Poland' },
      new List<String>{ 'PT50002700000001234567833', 'Portugal' },
      new List<String>{ 'QA54QNBA000000000000693123456', 'Qatar' },
      new List<String>{ 'RO09BCYP0000001234567890', 'Romania' },
      new List<String>{ 'SM76P0854009812123456789123', 'San Marino' },
      new List<String>{ 'SA4420000001234567891234', 'Saudi Arabia' },
      new List<String>{ 'RS35105008123123123173', 'Serbia' },
      new List<String>{ 'SC52BAHL01031234567890123456USD', 'Seychelles' },
      new List<String>{ 'SK8975000000000012345671', 'Slovakia' },
      new List<String>{ 'SI56192001234567892', 'Slovenia' },
      new List<String>{ 'ES7921000813610123456789', 'Spain' },
      new List<String>{ 'SE7280000810340009783242', 'Sweden' },
      new List<String>{ 'CH5604835012345678009', 'Switzerland' },
      new List<String>{ 'TN5904018104004942712345', 'Tunisia' },
      new List<String>{ 'TR320010009999901234567890', 'Turkey' },
      new List<String>{ 'UA903052992990004149123456789', 'Ukraine' },
      new List<String>{ 'AE460090000000123456789', 'United Arab Emirates' },
      new List<String>{ 'VG21PACG0000000123456789', 'Virgin Islands (British)' }
    };

    // When
    List<Boolean> results = new List<Boolean>();
    for (List<String> bankDetails : validIBANList) {
      try {
        results.add(
          BankAccountUtils.validateIBAN(
            bankDetails[0],
            bankDetails[1],
            'AXISINBB002'
          )
        );
      } catch (Exception e) {
        results.add(false);
      }
    }

    // Then
    for (Boolean res : results) {
      System.assert(
        res,
        'Function invalidated (returned false) a valid IBAN number'
      );
    }
  }
  @isTest
  static void shouldInvalidateABAAndReturnFalse() {
    // Given
    List<String> invalidABAList = new List<String>{
      '123ABA123456789',
      '12345678ABA0111030931',
      'ABA123456789',
      '123ABA0111030330',
      '123ABA0670148320',
      '123ABA2112744600',
      '123ABA2113705550',
      '123ABA0540017350',
      '123ABA2113705550',
      '123ABA0114000810',
      '123ABA0312013700',
      '123ABA0260136830',
      '123ABA0213025770',
      '123ABA0360018180',
      '123ABA0116000430',
      '123ABA011103093ABA2',
      '01110309',
      '123ABA123ABA0111030930',
      '123456789ABA123456789',
      'N/A12347ABA123456789',
      'NAABA123456789',
      'AXISINBB002ABA123456789'
    };
    // When
    List<Boolean> results = new List<Boolean>();
    for (String num : invalidABAList) {
      results.add(
        BankAccountUtils.validateIBAN(num, 'United States', 'AXISINBB002')
      );
    }

    // Then
    for (Boolean res : results) {
      System.assert(
        !res,
        'Function validated (returned true) an invalid ABA number'
      );
    }
  }
  @isTest
  static void shouldValidateABAAndReturnTrue() {
    // Given
    List<String> validABAList = new List<String>{
      '123456ABA011103093',
      '123456ABA067014822',
      '123456ABA211274450',
      '123456ABA211370545',
      '123456ABA054001725',
      '123456ABA211370545',
      '123456ABA011400071',
      '123456ABA031201360',
      '123456ABA026013673',
      '123456ABA021302567',
      '123456ABA053902197',
      '123456ABA036001808',
      '123456ABA011600033'
    };

    // When
    List<Boolean> results = new List<Boolean>();
    for (String num : validABAList) {
      results.add(
        BankAccountUtils.validateIBAN(num, 'United States', 'AXISINBB002')
      );
    }

    // Then
    for (Boolean res : results) {
      System.assert(
        res,
        'Function invalidated (returned false) a valid ABA number'
      );
    }
  }

  @isTest
  static void shouldValidateOtherAndReturnTrue() {
    // Given
    List<String> randomNumbers = new List<String>{
      'SSDJKA',
      '123',
      'ASDÖ123BBBKKKKS',
      '12341234123412341',
      'ASDFASDFASDFASDFASDFASDFASDFASDFASDFASDFASDFASDFASDFASDFASDFASDFASDFASDF',
      'ASASD123123ASDFASDF213ASDF213',
      'XX35202111090000000004234567',
      'LY38021001000000123456789'
    };

    // When
    List<Boolean> results = new List<Boolean>();
    for (String num : randomNumbers) {
      results.add(BankAccountUtils.validateIBAN(num, 'Libya', 'AXISINBB002')); // Libya because of the last entry
    }

    // Then
    for (Boolean res : results) {
      System.assert(
        res,
        'Function invalidated (returned false) a valid random number'
      );
    }
  }

  @IsTest
  static void shouldInvalidateBICNumberAndReturnFalse() {
    // Given
    List<String> invalidBICList = new List<String>{
      'MIDLGB3223',
      'M1IDLGB22XXX',
      'BARCGB22AJSD',
      'BARCGB22XXXs',
      'ABNANL2A12',
      'A1NANL2AXXX',
      '1ITIUS33',
      'CITI1S33XXX',
      '111'
    };
    // When
    List<Boolean> results = new List<Boolean>();
    for (String num : invalidBICList) {
      results.add(BankAccountUtils.validateBIC(num));
    }

    // Then
    for (Boolean res : results) {
      System.assert(
        !res,
        'The function validated (returned true) an invalid BIC number'
      );
    }
  }

  @IsTest
  static void shouldValidateBICNumberAndReturnTrue() {
    // Given
    List<String> validBICList = new List<String>{
      'MIDLGB22',
      'MIDLGB22XXX',
      'BARCGB22',
      'BARCGB22XXX',
      'ABNANL2A',
      'ABNANL2AXXX',
      'CITIUS33',
      'CITIUS33XXX',
      'WFBIUS6S',
      'WFBIUS6SXXX',
      'NWBKGB2L',
      'NWBKGB2LXXX',
      'COBADEFF',
      'COBADEFFXXX',
      'BNPAFRPP',
      'BNPAFRPPXXX',
      'POALILIT',
      'POALILITXXX',
      'LOYDGB2L',
      'LOYDGB2LXXX',
      'NTSBDEB1',
      'NTSBDEB1XXX',
      'DEUTDEDBPAL',
      'AXISINBB002'
    };

    // When
    List<Boolean> results = new List<Boolean>();
    for (String num : validBICList) {
      results.add(BankAccountUtils.validateBIC(num));
    }

    // Then
    for (Boolean res : results) {
      System.assert(
        res,
        'The function invalidated (returned false) a valid BIC number'
      );
    }
  }

  @IsTest
  static void shouldInValidateAddressAndReturnFalse() {
    // Given
    List<List<String>> inValidAddList = new List<List<String>>{
      new List<String>{ '123 N´d kings trollhattan', 'Albania' },
      new List<String>{ '123 N.? trollhattan', 'Sweden ' },
      new List<String>{ '123 N. trollhattan', 'Sweden ??' },
      new List<String>{ '34c´gh', '' }
    };

    // When
    List<Boolean> results = new List<Boolean>();
    for (List<String> addr : inValidAddList) {
      results.add(BankAccountUtils.validateAddress(addr[0], addr[1]));
    }

    // Then
    for (Boolean res : results) {
      System.assert(
        !res,
        'The function invalidated (returned true) Invalid Address'
      );
    }
  }

  @IsTest
  static void shouldValidateAddressAndReturnTrue() {
    // Given
    List<List<String>> validAddList = new List<List<String>>{
      new List<String>{ '123 N kings trollhattan', 'Albania' },
      new List<String>{ '123 N. trollhattan', 'Albania121' }
    };

    // When
    List<Boolean> results = new List<Boolean>();
    for (List<String> addr : validAddList) {
      results.add(BankAccountUtils.validateAddress(addr[0], addr[1]));
    }

    // Then
    for (Boolean res : results) {
      System.assert(
        res,
        'The function invalidated (returned false) a valid Address'
      );
    }
  }
}
