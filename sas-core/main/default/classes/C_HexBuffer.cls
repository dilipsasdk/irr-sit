/**
    Class used to provide ability to process conversions between hexadecmial
    and integer values into buffer values.
*/
public with sharing class C_HexBuffer {
    /**
        Modes which the hex buffer can run under 
        VALUES: sets the hex buffer to hexadecimal values per index
        CHARS: sets the hex buffer to 
    */
    public enum Mode{VALUES,CHARS}
    /**
        Buffer of hexadecimal characters / values
    */
    Integer[] hexB;

    /**
        Buffer of the corresponding integer
    */
    Integer intB;
    /**
        The mode of the hex buffer
    */
    Mode m;

    /**
        Instantiates the char buffer
        @param m The mode of the hex buffer
    */
    public C_HexBuffer(Mode m){
        this.m = m;
        this.hexB = new Integer[8];
    }

    /**
        Sets the integer value and automatically sets the corresponding character buffer for the integer value
        @param iVal THe value to convert to hex characters
        @return The char buffer containing the hex characters for the provided integer value
    */
    public Integer[] set(Integer iVal){
        intB = iVal;
        Integer i0 = iVal >> 28 & 15;
        Integer i1 = iVal >> 24 & 15;
        Integer i2 = iVal >> 20 & 15;
        Integer i3 = iVal >> 16 & 15;
        Integer i4 = iVal >> 12 & 15;
        Integer i5 = iVal >>  8 & 15;
        Integer i6 = iVal >>  4 & 15;
        Integer i7 = iVal       & 15;
        if(m==Mode.VALUES){
            hexB[0] = i0;
            hexB[1] = i1;
            hexB[2] = i2;
            hexB[3] = i3;
            hexB[4] = i4;
            hexB[5] = i5;
            hexB[6] = i6;
            hexB[7] = i7;
        }
        else if(m==Mode.CHARS){
            //Unicode char 0=48, a=97
            hexB[0] = i0 + (i0 < 10 ? 48 : 87);
            hexB[1] = i1 + (i1 < 10 ? 48 : 87);
            hexB[2] = i2 + (i2 < 10 ? 48 : 87);
            hexB[3] = i3 + (i3 < 10 ? 48 : 87);
            hexB[4] = i4 + (i4 < 10 ? 48 : 87);
            hexB[5] = i5 + (i5 < 10 ? 48 : 87);
            hexB[6] = i6 + (i6 < 10 ? 48 : 87);
            hexB[7] = i7 + (i7 < 10 ? 48 : 87);
        }
        return hexB;
    }

    /**
        Sets the hex buffer from the hex array source and automatically set the corresponding integer
        If the provided length if lower than 8 then the hex values are set to the lowest bits of the buffer
        @param hexArr The source array from which to copy the values
        @param offset The offset from which to begin copying hex chars from the array
        @param len The number of hex chars to copy (should commonly be 8)
        @return The integer value for the provided hexadecimal representation
    */
    public Integer set(Integer[] hexArr,Integer offset,Integer len){
        if(len>8)throw new IllegalArgumentException('Cannot copy more than 8 characters to integer from hex buffer');
        hexB[7] = len > 0 ? hexArr[offset+len-1] : 0;
        hexB[6] = len > 1 ? hexArr[offset+len-2] : 0;
        hexB[5] = len > 2 ? hexArr[offset+len-3] : 0;
        hexB[4] = len > 3 ? hexArr[offset+len-4] : 0;
        hexB[3] = len > 4 ? hexArr[offset+len-5] : 0;
        hexB[2] = len > 5 ? hexArr[offset+len-6] : 0;
        hexB[1] = len > 6 ? hexArr[offset+len-7] : 0;
        hexB[0] = len > 7 ? hexArr[offset+len-8] : 0;

        if(m==Mode.VALUES){
            intB = hexB[0]<<28 | hexB[1]<<24 | hexB[2]<<20 | hexB[3]<<16 | hexB[4]<<12 | hexB[5]<<8 | hexB[6]<<4 | hexB[7];
        }
        else if(m==Mode.CHARS){
            intB = 0;
            for(Integer i=0;i<8;i++){
                Integer ch = hexB[i];
                //Unicode char 0=48, a=97
                if(ch>=48 && ch<=57)ch-=48;
                else if(ch>=97 && ch<=102)ch-=87;
                else if(ch!=0)throw new IllegalArgumentException('Invalid hex character: "'+ch+'"');
                //Shift 4 bits per hex char
                intB = intB | (ch<<((7-i)<<2));
            }
        }
        return intB;
    }
    /**
        Copies the buffer to the provided hex array
        @param hexArr The hex array to copy the buffer to
        @param offset The offset in the hex array at which to start copying the buffer
    */
    public void copy(Integer[] hexArr,Integer offset){
        copyHighShort(hexArr,offset);
        copyLowShort(hexArr, offset+4);
    }
    /**
        Copies the high short of the buffer to the provided hex array
        @param hexArr The hex array to copy the buffer to
        @param offset The offset in the hex array at which to start copying the buffer
    */
    public void copyHighShort(Integer[] hexArr,Integer offset){
        hexArr[offset]=hexB[0];
        hexArr[offset+1]=hexB[1];
        hexArr[offset+2]=hexB[2];
        hexArr[offset+3]=hexB[3];
    }

    /**
        Copies the low short of the buffer to the provided hex array
        @param hexArr The hex array to copy the buffer to
        @param offset The offset in the hex array at which to start copying the buffer
    */
    public void copyLowShort(Integer[] hexArr,Integer offset){
        hexArr[offset]=hexB[4];
        hexArr[offset+1]=hexB[5];
        hexArr[offset+2]=hexB[6];
        hexArr[offset+3]=hexB[7];
    }

}
