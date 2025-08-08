/**
    Tests of calendar util functionality
    @author Peter Södergren
*/
@isTest
private class C_CalendarUtil_Test {
    /**
        Checks that a predefined set of holidays produces the expected dates as holidays
    */
    @isTest static void checkHolidays(){
        //Holidays to test
        Holiday[] hList = new Holiday[]{
            new Holiday(Name='T_Date1',         ActivityDate=Date.newInstance(2020,1,30),   IsAllDay=true,IsRecurrence=false,  RecurrenceDayOfMonth=null,   RecurrenceDayOfWeekMask=null,   RecurrenceStartDate=null,                           RecurrenceEndDateOnly=null,                         RecurrenceInstance=null,    RecurrenceInterval=null, RecurrenceMonthOfYear=null,        RecurrenceType=null                  ),
            new Holiday(Name='T_Date2',         ActivityDate=Date.newInstance(2020,2,20),   IsAllDay=true,IsRecurrence=false,  RecurrenceDayOfMonth=null,   RecurrenceDayOfWeekMask=null,   RecurrenceStartDate=null,                           RecurrenceEndDateOnly=null,                         RecurrenceInstance=null,    RecurrenceInterval=null, RecurrenceMonthOfYear=null,        RecurrenceType=null                  ),
            new Holiday(Name='T_Daily_WD',      ActivityDate=Date.newInstance(2020,1,15),   IsAllDay=true,IsRecurrence=true,   RecurrenceDayOfMonth=null,   RecurrenceDayOfWeekMask=62,     RecurrenceStartDate=Date.newInstance(2020,1,15),    RecurrenceEndDateOnly=Date.newInstance(2020,1,30),  RecurrenceInstance=null,    RecurrenceInterval=null, RecurrenceMonthOfYear=null,        RecurrenceType='RecursEveryWeekday'  ),
            new Holiday(Name='T_Daily_3',       ActivityDate=Date.newInstance(2019,12,25),  IsAllDay=true,IsRecurrence=true,   RecurrenceDayOfMonth=null,   RecurrenceDayOfWeekMask=null,   RecurrenceStartDate=Date.newInstance(2019,12,25),   RecurrenceEndDateOnly=Date.newInstance(2020,2,28),  RecurrenceInstance=null,    RecurrenceInterval=3,    RecurrenceMonthOfYear=null,        RecurrenceType='RecursDaily'         ),
            new Holiday(Name='T_Weekly_3',      ActivityDate=Date.newInstance(2020,1,2),    IsAllDay=true,IsRecurrence=true,   RecurrenceDayOfMonth=null,   RecurrenceDayOfWeekMask=80,     RecurrenceStartDate=Date.newInstance(2020,1,2),     RecurrenceEndDateOnly=Date.newInstance(2020,3,25),  RecurrenceInstance=null,    RecurrenceInterval=3,    RecurrenceMonthOfYear=null,        RecurrenceType='RecursWeekly'        ),
            new Holiday(Name='T_Monthly_2',     ActivityDate=Date.newInstance(2020,1,8),    IsAllDay=true,IsRecurrence=true,   RecurrenceDayOfMonth=8,      RecurrenceDayOfWeekMask=null,   RecurrenceStartDate=Date.newInstance(2020,1,8),     RecurrenceEndDateOnly=null,                         RecurrenceInstance=null,    RecurrenceInterval=2,    RecurrenceMonthOfYear=null,        RecurrenceType='RecursMonthly'       ),
            new Holiday(Name='T_Monthly_3_Nth', ActivityDate=Date.newInstance(2019,12,15),  IsAllDay=true,IsRecurrence=true,   RecurrenceDayOfMonth=null,   RecurrenceDayOfWeekMask=1,      RecurrenceStartDate=Date.newInstance(2019,12,15),   RecurrenceEndDateOnly=null,                         RecurrenceInstance='Third', RecurrenceInterval=3,    RecurrenceMonthOfYear=null,        RecurrenceType='RecursMonthlyNth'    ),
            new Holiday(Name='T_Yearly_1',      ActivityDate=Date.newInstance(2020,3,7),    IsAllDay=true,IsRecurrence=true,   RecurrenceDayOfMonth=7,      RecurrenceDayOfWeekMask=null,   RecurrenceStartDate=Date.newInstance(2020,3,7),     RecurrenceEndDateOnly=null,                         RecurrenceInstance=null,    RecurrenceInterval=null, RecurrenceMonthOfYear='March',     RecurrenceType='RecursYearly'        ),
            new Holiday(Name='T_Yearly_2_Nth',  ActivityDate=Date.newInstance(2020,3,17),   IsAllDay=true,IsRecurrence=true,   RecurrenceDayOfMonth=null,   RecurrenceDayOfWeekMask=4,      RecurrenceStartDate=Date.newInstance(2020,3,17),    RecurrenceEndDateOnly=null,                         RecurrenceInstance='Third', RecurrenceInterval=null, RecurrenceMonthOfYear='March',     RecurrenceType='RecursYearlyNth'     ),
            new Holiday(Name='T_Monthly_1_Nth', ActivityDate=Date.newInstance(2020,2,4),    IsAllDay=true,IsRecurrence=true,   RecurrenceDayOfMonth=null,   RecurrenceDayOfWeekMask=127,    RecurrenceStartDate=Date.newInstance(2020,2,4),     RecurrenceEndDateOnly=null,                         RecurrenceInstance='Fourth',RecurrenceInterval=1,    RecurrenceMonthOfYear=null,        RecurrenceType='RecursMonthlyNth'    ),
            new Holiday(Name='T_Monthly_4_Nth', ActivityDate=Date.newInstance(2019,12,31),  IsAllDay=true,IsRecurrence=true,   RecurrenceDayOfMonth=null,   RecurrenceDayOfWeekMask=4,      RecurrenceStartDate=Date.newInstance(2019,12,31),   RecurrenceEndDateOnly=null,                         RecurrenceInstance='Last',  RecurrenceInterval=4,    RecurrenceMonthOfYear=null,        RecurrenceType='RecursMonthlyNth'    ),
            new Holiday(Name='T_Yearly_3_Nth',  ActivityDate=Date.newInstance(2019,12,9),   IsAllDay=true,IsRecurrence=true,   RecurrenceDayOfMonth=null,   RecurrenceDayOfWeekMask=2,      RecurrenceStartDate=Date.newInstance(2019,12,9),    RecurrenceEndDateOnly=null,                         RecurrenceInstance='Second',RecurrenceInterval=null, RecurrenceMonthOfYear='December',  RecurrenceType='RecursYearlyNth'     )
        };
        C_CalendarUtil.holidayList = hList;
        
        //Pre-computed 
        Set<Date> holidays = new Set<Date>{
            Date.newInstance(2019,12,09),
            Date.newInstance(2019,12,15),
            Date.newInstance(2019,12,25),
            Date.newInstance(2019,12,28),
            Date.newInstance(2019,12,31),
            Date.newInstance(2020,01,02),
            Date.newInstance(2020,01,03),
            Date.newInstance(2020,01,04),
            Date.newInstance(2020,01,06),
            Date.newInstance(2020,01,08),
            Date.newInstance(2020,01,09),
            Date.newInstance(2020,01,12),
            Date.newInstance(2020,01,15),
            Date.newInstance(2020,01,16),
            Date.newInstance(2020,01,17),
            Date.newInstance(2020,01,18),
            Date.newInstance(2020,01,20),
            Date.newInstance(2020,01,21),
            Date.newInstance(2020,01,22),
            Date.newInstance(2020,01,23),
            Date.newInstance(2020,01,24),
            Date.newInstance(2020,01,25),
            Date.newInstance(2020,01,27),
            Date.newInstance(2020,01,28),
            Date.newInstance(2020,01,29),
            Date.newInstance(2020,01,30),
            Date.newInstance(2020,02,02),
            Date.newInstance(2020,02,04),
            Date.newInstance(2020,02,05),
            Date.newInstance(2020,02,08),
            Date.newInstance(2020,02,11),
            Date.newInstance(2020,02,13),
            Date.newInstance(2020,02,14),
            Date.newInstance(2020,02,15),
            Date.newInstance(2020,02,17),
            Date.newInstance(2020,02,20),
            Date.newInstance(2020,02,23),
            Date.newInstance(2020,02,26),
            Date.newInstance(2020,03,04),
            Date.newInstance(2020,03,05),
            Date.newInstance(2020,03,07),
            Date.newInstance(2020,03,08),
            Date.newInstance(2020,03,15),
            Date.newInstance(2020,03,17),
            Date.newInstance(2020,04,04),
            Date.newInstance(2020,04,28),
            Date.newInstance(2020,05,04),
            Date.newInstance(2020,05,08),
            Date.newInstance(2020,06,04),
            Date.newInstance(2020,06,21),
            Date.newInstance(2020,07,04),
            Date.newInstance(2020,07,08),
            Date.newInstance(2020,08,04),
            Date.newInstance(2020,08,25),
            Date.newInstance(2020,09,04),
            Date.newInstance(2020,09,08),
            Date.newInstance(2020,09,20),
            Date.newInstance(2020,10,04),
            Date.newInstance(2020,11,04),
            Date.newInstance(2020,11,08),
            Date.newInstance(2020,12,04),
            Date.newInstance(2020,12,14),
            Date.newInstance(2020,12,20),
            Date.newInstance(2020,12,29)
        };

        Date d = Date.newInstance(2019,1,1);
        Date dStop = Date.newInstance(2021,1,1);
        while(d<dStop){
            if(holidays.contains(d))System.assert(C_CalendarUtil.isHoliday(d),'Expected date '+d+' to be a holiday but it was not.');
            else System.assert(!C_CalendarUtil.isHoliday(d),'Expected date '+d+' to not be a holiday but it was.');
            d = d.addDays(1);
        }

        C_CalendarUtil.HolidayInstance[] hiList = C_CalendarUtil.getHoliday(Date.newInstance(2020,1,30));
        System.assertEquals(3,hiList.size());
        Set<String> hNames = new Set<String>{hiList[0].name,hiList[1].name,hiList[2].name};
        System.assert(hNames.contains('T_Date1'));
        System.assert(hNames.contains('T_Daily_WD'));
        System.assert(hNames.contains('T_Daily_3'));

        hiList = C_CalendarUtil.getHoliday(Date.newInstance(2020,7,8));
        System.assertEquals(1,hiList.size());
        System.assertEquals('T_Monthly_2',hiList[0].name);

        hiList = C_CalendarUtil.getHoliday(Date.newInstance(2020,1,19));
        System.assertEquals(0,hiList.size());
    }

    /**
        Checks that unrecognized holiday data generates exceptions
    */
    @isTest static void testUnrecognizedHolidayData(){
        Boolean error = false;
        //No month specified
        C_CalendarUtil.holidayList = new Holiday[]{new Holiday(Name='T_Yearly_2_Nth',  ActivityDate=Date.newInstance(2020,3,17),   IsAllDay=true,IsRecurrence=true,   RecurrenceDayOfMonth=null,   RecurrenceDayOfWeekMask=4,      RecurrenceStartDate=Date.newInstance(2020,3,17),    RecurrenceEndDateOnly=null,                         RecurrenceInstance='Third', RecurrenceInterval=null, RecurrenceMonthOfYear=null,     RecurrenceType='RecursYearlyNth'     )};
        try{
            C_CalendarUtil.getHolidays(Date.newInstance(2020, 1, 1), Date.newInstance(2020, 12, 31));
        }
        catch(C_CalendarUtil.CalendarException e){
            error = true;
        }
        System.assert(error);

        error = false;
        //No instance specified
        C_CalendarUtil.holidayList = new Holiday[]{new Holiday(Name='T_Yearly_2_Nth',  ActivityDate=Date.newInstance(2020,3,17),   IsAllDay=true,IsRecurrence=true,   RecurrenceDayOfMonth=null,   RecurrenceDayOfWeekMask=4,      RecurrenceStartDate=Date.newInstance(2020,3,17),    RecurrenceEndDateOnly=null,                         RecurrenceInstance=null, RecurrenceInterval=null, RecurrenceMonthOfYear='March',     RecurrenceType='RecursYearlyNth'     )};
        try{
            C_CalendarUtil.getHolidays(Date.newInstance(2020, 1, 1), Date.newInstance(2020, 12, 31));
        }
        catch(C_CalendarUtil.CalendarException e){
            error = true;
        }
        System.assert(error);

        error = false;
        //No recurrence type specified
        C_CalendarUtil.holidayList = new Holiday[]{new Holiday(Name='T_Yearly_2_Nth',  ActivityDate=Date.newInstance(2020,3,17),   IsAllDay=true,IsRecurrence=true,   RecurrenceDayOfMonth=null,   RecurrenceDayOfWeekMask=4,      RecurrenceStartDate=Date.newInstance(2020,3,17),    RecurrenceEndDateOnly=null,                         RecurrenceInstance='Third', RecurrenceInterval=null, RecurrenceMonthOfYear='March',     RecurrenceType=null     )};
        try{
            C_CalendarUtil.getHolidays(Date.newInstance(2020, 1, 1), Date.newInstance(2020, 12, 31));
        }
        catch(C_CalendarUtil.CalendarException e){
            error = true;
        }
        System.assert(error);
    }

    /**
        Checks that the correct day of weeks are calculated for pre computed dates
    */
    @isTest static void checkCorrectDayOfWeek(){
        System.assertEquals(C_CalendarUtil.DAY_OF_WEEK_FRIDAY,C_CalendarUtil.getDayOfWeek(Date.newInstance(2010,9,24)));
        System.assertEquals(C_CalendarUtil.DAY_OF_WEEK_WEDNESDAY,C_CalendarUtil.getDayOfWeek(Date.newInstance(2012,1,18)));
        System.assertEquals(C_CalendarUtil.DAY_OF_WEEK_MONDAY,C_CalendarUtil.getDayOfWeek(Date.newInstance(2014,6,23)));
        System.assertEquals(C_CalendarUtil.DAY_OF_WEEK_MONDAY,C_CalendarUtil.getDayOfWeek(Date.newInstance(2014,9,29)));
        System.assertEquals(C_CalendarUtil.DAY_OF_WEEK_WEDNESDAY,C_CalendarUtil.getDayOfWeek(Date.newInstance(2016,10,19)));
        System.assertEquals(C_CalendarUtil.DAY_OF_WEEK_FRIDAY,C_CalendarUtil.getDayOfWeek(Date.newInstance(2016,11,11)));
        System.assertEquals(C_CalendarUtil.DAY_OF_WEEK_TUESDAY,C_CalendarUtil.getDayOfWeek(Date.newInstance(2016,12,20)));
        System.assertEquals(C_CalendarUtil.DAY_OF_WEEK_FRIDAY,C_CalendarUtil.getDayOfWeek(Date.newInstance(2017,4,21)));
        System.assertEquals(C_CalendarUtil.DAY_OF_WEEK_FRIDAY,C_CalendarUtil.getDayOfWeek(Date.newInstance(2019,6,7)));
        System.assertEquals(C_CalendarUtil.DAY_OF_WEEK_WEDNESDAY,C_CalendarUtil.getDayOfWeek(Date.newInstance(2020,6,24)));
        System.assertEquals(C_CalendarUtil.DAY_OF_WEEK_MONDAY,C_CalendarUtil.getDayOfWeek(Date.newInstance(2020,11,23)));
        System.assertEquals(C_CalendarUtil.DAY_OF_WEEK_MONDAY,C_CalendarUtil.getDayOfWeek(Date.newInstance(2023,2,13)));
        System.assertEquals(C_CalendarUtil.DAY_OF_WEEK_SATURDAY,C_CalendarUtil.getDayOfWeek(Date.newInstance(2023,11,25)));
        System.assertEquals(C_CalendarUtil.DAY_OF_WEEK_THURSDAY,C_CalendarUtil.getDayOfWeek(Date.newInstance(2024,9,12)));
        System.assertEquals(C_CalendarUtil.DAY_OF_WEEK_WEDNESDAY,C_CalendarUtil.getDayOfWeek(Date.newInstance(2024,10,2)));
        System.assertEquals(C_CalendarUtil.DAY_OF_WEEK_FRIDAY,C_CalendarUtil.getDayOfWeek(Date.newInstance(2024,10,11)));
        System.assertEquals(C_CalendarUtil.DAY_OF_WEEK_SUNDAY,C_CalendarUtil.getDayOfWeek(Date.newInstance(2024,11,17)));
        System.assertEquals(C_CalendarUtil.DAY_OF_WEEK_THURSDAY,C_CalendarUtil.getDayOfWeek(Date.newInstance(2025,10,9)));
        System.assertEquals(C_CalendarUtil.DAY_OF_WEEK_FRIDAY,C_CalendarUtil.getDayOfWeek(Date.newInstance(2026,2,27)));
        System.assertEquals(C_CalendarUtil.DAY_OF_WEEK_MONDAY,C_CalendarUtil.getDayOfWeek(Date.newInstance(2027,1,11)));
        System.assertEquals(C_CalendarUtil.DAY_OF_WEEK_WEDNESDAY,C_CalendarUtil.getDayOfWeek(Date.newInstance(2027,3,10)));
        System.assertEquals(C_CalendarUtil.DAY_OF_WEEK_TUESDAY,C_CalendarUtil.getDayOfWeek(Date.newInstance(2029,8,14)));
        System.assertEquals(C_CalendarUtil.DAY_OF_WEEK_WEDNESDAY,C_CalendarUtil.getDayOfWeek(Date.newInstance(2029,12,12)));
        System.assertEquals(C_CalendarUtil.DAY_OF_WEEK_TUESDAY,C_CalendarUtil.getDayOfWeek(Date.newInstance(2030,8,13)));
        System.assertEquals(C_CalendarUtil.DAY_OF_WEEK_TUESDAY,C_CalendarUtil.getDayOfWeek(Date.newInstance(2030,11,19)));

        //Testing old dates
        System.assertEquals(C_CalendarUtil.DAY_OF_WEEK_SATURDAY,C_CalendarUtil.getDayOfWeek(Date.newInstance(1617,10,14)));
        System.assertEquals(C_CalendarUtil.DAY_OF_WEEK_THURSDAY,C_CalendarUtil.getDayOfWeek(Date.newInstance(1637,1,22)));
        System.assertEquals(C_CalendarUtil.DAY_OF_WEEK_TUESDAY,C_CalendarUtil.getDayOfWeek(Date.newInstance(1695,4,19)));
    }
    
    /**
        Checks that the correct logic is applied when computing which dates are week ends
    */
    @isTest static void checkWeekendLogic(){
        System.assertEquals(true,C_CalendarUtil.isWeekend(Date.newInstance(2023,11,25)));
        System.assertEquals(false,C_CalendarUtil.isWeekend(Date.newInstance(2024,9,12)));
        System.assertEquals(false,C_CalendarUtil.isWeekend(Date.newInstance(2024,10,2)));
        System.assertEquals(false,C_CalendarUtil.isWeekend(Date.newInstance(2024,10,11)));
        System.assertEquals(true,C_CalendarUtil.isWeekend(Date.newInstance(2024,11,17)));
        System.assertEquals(false,C_CalendarUtil.isWeekend(Date.newInstance(2025,10,9)));

        //Testing old dates
        System.assertEquals(true,C_CalendarUtil.isWeekend(Date.newInstance(1617,10,14)));
        System.assertEquals(false,C_CalendarUtil.isWeekend(Date.newInstance(1637,1,22)));
        System.assertEquals(false,C_CalendarUtil.isWeekend(Date.newInstance(1695,4,19)));
    }

    /**
        Checks that the week computation works for a set of pre-computed dates
    */
    @isTest static void checkWeekComputation(){
        C_CalendarUtil.Week w;
        w = C_CalendarUtil.getWeek(Date.newInstance(2017, 12, 31));
        System.assertEquals(Date.newInstance(2017,12,25),w.startDate);
        System.assertEquals(Date.newInstance(2017,12,31),w.endDate);
        System.assertEquals(2017,w.year);
        System.assertEquals(52,w.weekNumber);

        w = C_CalendarUtil.getWeek(Date.newInstance(2018, 1, 3));
        System.assertEquals(Date.newInstance(2018,1,1),w.startDate);
        System.assertEquals(Date.newInstance(2018,1,7),w.endDate);
        System.assertEquals(2018,w.year);
        System.assertEquals(1,w.weekNumber);

        w = C_CalendarUtil.getWeek(Date.newInstance(2018, 12, 31));
        System.assertEquals(Date.newInstance(2018,12,31),w.startDate);
        System.assertEquals(Date.newInstance(2019,1,6),w.endDate);
        System.assertEquals(2019,w.year);
        System.assertEquals(1,w.weekNumber);

        w = C_CalendarUtil.getWeek(Date.newInstance(2020, 12, 31));
        System.assertEquals(Date.newInstance(2020,12,28),w.startDate);
        System.assertEquals(Date.newInstance(2021,1,3),w.endDate);
        System.assertEquals(2020,w.year);
        System.assertEquals(53,w.weekNumber);

        w = C_CalendarUtil.getWeek(Date.newInstance(2021, 1, 2));
        System.assertEquals(Date.newInstance(2020,12,28),w.startDate);
        System.assertEquals(Date.newInstance(2021,1,3),w.endDate);
        System.assertEquals(2020,w.year);
        System.assertEquals(53,w.weekNumber);

        w = C_CalendarUtil.getWeek(Date.newInstance(2020, 6, 11));
        System.assertEquals(Date.newInstance(2020,6,8),w.startDate);
        System.assertEquals(Date.newInstance(2020,6,14),w.endDate);
        System.assertEquals(2020,w.year);
        System.assertEquals(24,w.weekNumber);

        w = C_CalendarUtil.getWeek(Date.newInstance(2023, 1, 1));
        System.assertEquals(Date.newInstance(2022,12,26),w.startDate);
        System.assertEquals(Date.newInstance(2023,1,1),w.endDate);
        System.assertEquals(2022,w.year);
        System.assertEquals(52,w.weekNumber);

        System.assertEquals(2022+'W'+52,w.toString());

        System.assertEquals(24,C_CalendarUtil.getWeekNumber(Date.newInstance(2020,6,11)));
    }

    /**
        Checks that the computation of previous occurrence of ddays works properly
    */
    @isTest static void checkPrevDayOccurranceComputation(){
        System.assertEquals(Date.newInstance(2019,12,14),C_CalendarUtil.getPrevOccurrenceOfDay(C_CalendarUtil.DAY_OF_WEEK_SATURDAY,Date.newInstance(2019,12,20),true));
        System.assertEquals(Date.newInstance(2019,12,14),C_CalendarUtil.getPrevOccurrenceOfDay(C_CalendarUtil.DAY_OF_WEEK_SATURDAY,Date.newInstance(2019,12,20),false));
        System.assertEquals(Date.newInstance(2019,12,21),C_CalendarUtil.getPrevOccurrenceOfDay(C_CalendarUtil.DAY_OF_WEEK_SATURDAY,Date.newInstance(2019,12,21),true));
        System.assertEquals(Date.newInstance(2019,12,14),C_CalendarUtil.getPrevOccurrenceOfDay(C_CalendarUtil.DAY_OF_WEEK_SATURDAY,Date.newInstance(2019,12,21),false));
        System.assertEquals(Date.newInstance(2019,12,21),C_CalendarUtil.getPrevOccurrenceOfDay(C_CalendarUtil.DAY_OF_WEEK_SATURDAY,Date.newInstance(2019,12,22),true));
        System.assertEquals(Date.newInstance(2019,12,21),C_CalendarUtil.getPrevOccurrenceOfDay(C_CalendarUtil.DAY_OF_WEEK_SATURDAY,Date.newInstance(2019,12,22),false));
    }
}