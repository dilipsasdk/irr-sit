/**
    Test class for the hex buffer class to ensure that the correct values are converted
*/
@isTest 
private class C_HexBuffer_Test {
    /**
        Tests converting characters to integers
    */
    @isTest static void hexCharsToInt(){
        C_HexBuffer hb = new C_HexBuffer(C_HexBuffer.Mode.CHARS);
        Integer[] chArr = 'f1234567890abcdef'.getChars();
        System.assertEquals(hb.set(chArr, 0, 8),-249346713);
        System.assertEquals(hb.set(chArr, 1, 8),305419896);
        System.assertEquals(hb.set(chArr, 2, 8),591751049);
        System.assertEquals(hb.set(chArr, 3, 8),878082192);
        System.assertEquals(hb.set(chArr, 4, 8),1164413194);
        System.assertEquals(hb.set(chArr, 5, 8),1450741931);
        System.assertEquals(hb.set(chArr, 6, 8),1737034428);
        System.assertEquals(hb.set(chArr, 7, 8),2022747085);
        System.assertEquals(hb.set(chArr, 8, 8),-1995784994);
        System.assertEquals(hb.set(chArr, 9, 8),-1867788817);

        System.assertEquals(hb.set(chArr, 1, 6),1193046);
        System.assertEquals(hb.set(chArr, 1, 4),4660);
        System.assertEquals(hb.set(chArr, 1, 2),18);

        System.assertEquals(hb.set(chArr, 11, 6),11259375);
        System.assertEquals(hb.set(chArr, 13, 4),52719);
        System.assertEquals(hb.set(chArr, 15, 2),239);

        System.assertEquals(hb.set(chArr, 5, 3),1383);
    }

    /**
        Tests converting hex values to integers
    */
    @isTest static void hexValsToInt(){
        C_HexBuffer hb = new C_HexBuffer(C_HexBuffer.Mode.VALUES);
        Integer[] valArr = new Integer[]{15,1,2,3,4,5,6,7,8,9,0,10,11,12,13,14,15};
        System.assertEquals(hb.set(valArr, 0, 8),-249346713);
        System.assertEquals(hb.set(valArr, 1, 8),305419896);
        System.assertEquals(hb.set(valArr, 2, 8),591751049);
        System.assertEquals(hb.set(valArr, 3, 8),878082192);
        System.assertEquals(hb.set(valArr, 4, 8),1164413194);
        System.assertEquals(hb.set(valArr, 5, 8),1450741931);
        System.assertEquals(hb.set(valArr, 6, 8),1737034428);
        System.assertEquals(hb.set(valArr, 7, 8),2022747085);
        System.assertEquals(hb.set(valArr, 8, 8),-1995784994);
        System.assertEquals(hb.set(valArr, 9, 8),-1867788817);

        System.assertEquals(hb.set(valArr, 1, 6),1193046);
        System.assertEquals(hb.set(valArr, 1, 4),4660);
        System.assertEquals(hb.set(valArr, 1, 2),18);

        System.assertEquals(hb.set(valArr, 11, 6),11259375);
        System.assertEquals(hb.set(valArr, 13, 4),52719);
        System.assertEquals(hb.set(valArr, 15, 2),239);

        System.assertEquals(hb.set(valArr, 5, 3),1383);
    }

    /**
        Tests converting integers to hex characters
    */
    @isTest static void intToHexChars(){
        C_HexBuffer hb = new C_HexBuffer(C_HexBuffer.Mode.CHARS);
        System.assertEquals('00000000',String.fromCharArray(hb.set(0)));
        System.assertEquals('00000001',String.fromCharArray(hb.set(1)));
        System.assertEquals('000013f9',String.fromCharArray(hb.set(5113)));
        System.assertEquals('09ec1f76',String.fromCharArray(hb.set(166469494)));
        System.assertEquals('ffffffff',String.fromCharArray(hb.set(-1)));
        System.assertEquals('fe12f0d5',String.fromCharArray(hb.set(-32313131)));
        System.assertEquals('002088a7',String.fromCharArray(hb.set(2132135)));
        System.assertEquals('1b423ab3',String.fromCharArray(hb.set(457325235)));
        System.assertEquals('02d84af2',String.fromCharArray(hb.set(47729394)));
        System.assertEquals('0093587b',String.fromCharArray(hb.set(9656443)));
        System.assertEquals('006781bd',String.fromCharArray(hb.set(6783421)));
        System.assertEquals('ffdf39a3',String.fromCharArray(hb.set(-2147933)));
    }

    /**
        Tests converting integers to hex values
    */
    @isTest static void intToHexVals(){
        C_HexBuffer hb = new C_HexBuffer(C_HexBuffer.Mode.VALUES);
        validateArrays(new Integer[]{00,00,00,00,00,00,00,00}, hb.set(0));
        validateArrays(new Integer[]{00,00,00,00,00,00,00,01}, hb.set(1));
        validateArrays(new Integer[]{00,00,00,00,01,03,15,09}, hb.set(5113));
        validateArrays(new Integer[]{00,09,14,12,01,15,07,06}, hb.set(166469494));
        validateArrays(new Integer[]{15,15,15,15,15,15,15,15}, hb.set(-1));
        validateArrays(new Integer[]{15,14,01,02,15,00,13,05}, hb.set(-32313131));
        validateArrays(new Integer[]{00,00,02,00,08,08,10,07}, hb.set(2132135));
        validateArrays(new Integer[]{01,11,04,02,03,10,11,03}, hb.set(457325235));
        validateArrays(new Integer[]{00,02,13,08,04,10,15,02}, hb.set(47729394));
        validateArrays(new Integer[]{00,00,09,03,05,08,07,11}, hb.set(9656443));
        validateArrays(new Integer[]{00,00,06,07,08,01,11,13}, hb.set(6783421));
        validateArrays(new Integer[]{15,15,13,15,03,09,10,03}, hb.set(-2147933));
    }
    /**
        Tests the copy buffer function of the hex buffer
    */
    @isTest static void copyBuffer(){
        C_HexBuffer hb = new C_HexBuffer(C_HexBuffer.Mode.CHARS);
        Integer[] chArr = '1234567890abcdef'.getChars();
        hb.set(chArr, 0, 8);
        Integer[] hexArr = new Integer[12];
        hb.copy(hexArr, 0);
        System.assertEquals(chArr[0],hexArr[0]);
        System.assertEquals(chArr[1],hexArr[1]);
        System.assertEquals(chArr[2],hexArr[2]);
        System.assertEquals(chArr[3],hexArr[3]);
        System.assertEquals(chArr[4],hexArr[4]);
        System.assertEquals(chArr[5],hexArr[5]);
        System.assertEquals(chArr[6],hexArr[6]);
        System.assertEquals(chArr[7],hexArr[7]);
        System.assertEquals(null,hexArr[8]);
        System.assertEquals(null,hexArr[9]);
        System.assertEquals(null,hexArr[10]);
        System.assertEquals(null,hexArr[11]);
        hb.copy(hexArr, 4);
        System.assertEquals(chArr[0],hexArr[0]);
        System.assertEquals(chArr[1],hexArr[1]);
        System.assertEquals(chArr[2],hexArr[2]);
        System.assertEquals(chArr[3],hexArr[3]);
        System.assertEquals(chArr[0],hexArr[4]);
        System.assertEquals(chArr[1],hexArr[5]);
        System.assertEquals(chArr[2],hexArr[6]);
        System.assertEquals(chArr[3],hexArr[7]);
        System.assertEquals(chArr[4],hexArr[8]);
        System.assertEquals(chArr[5],hexArr[9]);
        System.assertEquals(chArr[6],hexArr[10]);
        System.assertEquals(chArr[7],hexArr[11]);
        hb.copyHighShort(hexArr, 8);
        hb.copyLowShort(hexArr, 0);
        System.assertEquals(chArr[4],hexArr[0]);
        System.assertEquals(chArr[5],hexArr[1]);
        System.assertEquals(chArr[6],hexArr[2]);
        System.assertEquals(chArr[7],hexArr[3]);
        System.assertEquals(chArr[0],hexArr[4]);
        System.assertEquals(chArr[1],hexArr[5]);
        System.assertEquals(chArr[2],hexArr[6]);
        System.assertEquals(chArr[3],hexArr[7]);
        System.assertEquals(chArr[0],hexArr[8]);
        System.assertEquals(chArr[1],hexArr[9]);
        System.assertEquals(chArr[2],hexArr[10]);
        System.assertEquals(chArr[3],hexArr[11]);
    }


    /**
        Validates the array values in the provided arrays of 8 in length
        @param exp The expected array result
        @param act The actual array result
    */
    private static void validateArrays(Integer[] exp,Integer[] act){
        System.assertEquals(8,exp.size());
        System.assertEquals(8,act.size());
        System.assertEquals(exp[0],act[0]);
        System.assertEquals(exp[1],act[1]);
        System.assertEquals(exp[2],act[2]);
        System.assertEquals(exp[3],act[3]);
        System.assertEquals(exp[4],act[4]);
        System.assertEquals(exp[5],act[5]);
        System.assertEquals(exp[6],act[6]);
        System.assertEquals(exp[7],act[7]);

    }   
}