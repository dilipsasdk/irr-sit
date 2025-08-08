/**
    Utility class with methods used to get compute information
    related to dates, week dates and holidays.
    @author Peter Södergren
*/
global with sharing class C_CalendarUtil {
    /**
        Custom exception thrown when issues with calendar functions
    */
    global class CalendarException extends Exception{}
    /**
        Helper table to compute the day of the week
    */
    static final Integer[] dayOfWeekHelperTable = new Integer[]{0,3,2,5,0,3,5,1,4,6,2,4};

    /**
        Recurrence where a holiday recurrs on a daily basis without a frequency
    */
    static final String RECURRENCE_TYPE_EVERY_WEEKDAY = 'RecursEveryWeekday';
    /**
        Recurrence where a holiday recurrs on a daily basis with a frequency
    */
    static final String RECURRENCE_TYPE_DAILY = 'RecursDaily';
    /**
        Recurrence where a holiday recurrs on a weekly basis
    */
    static final String RECURRENCE_TYPE_WEEKLY = 'RecursWeekly';
    /**
        Recurrence where a holiday recurrs on a monthly basis
    */
    static final String RECURRENCE_TYPE_MONTHLY = 'RecursMonthly';
    /**
        Recurrence where a holiday recurrs on a monthly basis of the nth instance of a day
    */
    static final String RECURRENCE_TYPE_MONTHLY_NTH = 'RecursMonthlyNth';
    /**
        Recurrence where a holiday recurrs on a yearly basis
    */
    static final String RECURRENCE_TYPE_YEARLY = 'RecursYearly';
    /**
        Recurrence where a holiday recurrs on a yearly basis of the nth instance of a day
    */
    static final String RECURRENCE_TYPE_YEARLY_NTH = 'RecursYearlyNth';
    /**
        Integer used to represent sunday
    */
    public static final Integer DAY_OF_WEEK_SUNDAY=0;
    /**
        Integer used to represent monday
    */
	public static final Integer DAY_OF_WEEK_MONDAY=1;
    /**
        Integer used to represent tuesday
    */
	public static final Integer DAY_OF_WEEK_TUESDAY=2;
    /**
        Integer used to represent wednesday
    */
	public static final Integer DAY_OF_WEEK_WEDNESDAY=3;
    /**
        Integer used to represent thursday
    */
	public static final Integer DAY_OF_WEEK_THURSDAY=4;
    /**
        Integer used to represent friday
    */
	public static final Integer DAY_OF_WEEK_FRIDAY=5;
    /**
        Integer used to represent saturday
    */
	public static final Integer DAY_OF_WEEK_SATURDAY=6;

    /**
        List of holidays used when computing holidays (fetched from DB on first use)
    */
    @TestVisible private static Holiday[] holidayList;

    /**
		Cached holiday dates
	*/
	private static Set<Date> HSC;
	/**
		Cached holiday dates from year
	*/
	private static Integer HSC_FROM;
	/**
		Cached holiday dates to year
	*/
	private static Integer HSC_TO;


    /**
		Returns day of week where Sunday=0 and Saturday=6 for a given Date
		@param d The Date
		@return The day of the week
	*/
	public static Integer getDayOfWeek(Date d){
		return getDayOfWeek(d.year(),d.month(),d.day());
	}

    /**
		Sakamotos method to calculate the day of the week
		With fallback to use date time formatting construct
		@param y The year
		@param m The month (1-12)
		@param d The day of month
	*/
	public static Integer getDayOfWeek(Integer y,Integer m,Integer d){
		if(y>1800){
			if(m<3)y--;
			return Math.mod(y + y/4 - y/100 + y/400 + dayOfWeekHelperTable[m-1] + d,7);
		}
		//Use fallback if the year is prior to 1800
		String dayString = DateTime.newInstance(y,m,d).format('EEEE');
		Integer dayNum=-1;
		if(dayString=='Sunday')dayNum=0;
		if(dayString=='Monday')dayNum=1;
		if(dayString=='Tuesday')dayNum=2;
		if(dayString=='Wednesday')dayNum=3;
		if(dayString=='Thursday')dayNum=4;
		if(dayString=='Friday')dayNum=5;
		if(dayString=='Saturday')dayNum=6;
		if(dayNum==-1)throw new TypeException();
		return dayNum;
	}

    /**
		Returns whether the supplied date occurs on a weekend
		@param y The year
		@param m The month (1-12)
		@param d The day of month
		@return whether the supplied date occurs on a weekend
	*/
	global static Boolean isWeekend(Integer y,Integer m,Integer d){
		Integer dow = getDayOfWeek(y,m,d);
		return dow == DAY_OF_WEEK_SATURDAY || dow == DAY_OF_WEEK_SUNDAY;
	}

    /**
        Returns whether the supplied date occurs on a weekend
        @param d The date to check
        @return Whether the date occurs on a weekend

    */
    global static Boolean isWeekend(Date d){
        return isWeekend(d.year(),d.month(),d.day());
    }

    /**
		Returns the ISO-8601 week number for the supplied date
		ISO-8601 week numbers are used in most of the world except in North America and Islamic countries
		See: https://en.wikipedia.org/wiki/Week#Week_numbering for more information
		@param d The date for which to get the week number
		@return The week number
	*/
	global static Integer getWeekNumber(Date d){
		return getWeek(d).weekNumber;
	}

	/**
		Represents a week in a given year
		@author Peter Södegren
	*/
	global class Week{
		/**
			The year which the week is assigned to
		*/
		global Integer year;
		/**
			The week number in the given year
		*/
		global Integer weekNumber;
		/**
			The start date of the week (inclusive)
		*/
		global Date startDate;
		/**
			The end date of the week (inclusive)
		*/
		global Date endDate;

		/**
			Creates a week instance
			@param year The year which the week is assigned to
			@param weekNumber The week number in the given year
			@param startDate The start date of the week (inclusive)
			@param endDate The end date of the week (inclusive)
		*/
		global Week(Integer year,Integer weekNumber,Date startDate,Date endDate){
			this.year = year;
			this.weekNumber = weekNumber;
			this.startDate = startDate;
			this.endDate = endDate;
		}

		/**
			@return A string representation of the week in the format yyyy'W'w
		*/
		global override String toString(){
			return year+'W'+weekNumber;
		}
	}

	/**
		Returns the ISO-8601 week number for the supplied date
		ISO-8601 week numbers are used in most of the world except in North America and Islamic countries
		See: https://en.wikipedia.org/wiki/Week#Week_numbering for more information
		@param d The date for which to get the week number
		@return The week as a WeekWithYear object
	*/
	global static Week getWeek(Date d){
		Integer dayOfYear = d.dayOfYear();
		Date dayInFirstWeekOfThisYear = Date.newInstance(d.year(),1,4);
        Integer dowThisYear = getDayOfWeek(dayInFirstWeekOfThisYear);
        Integer iso8601DowThisYear = dowThisYear==0 ? 6 : dowThisYear-1;
		Integer firstDayOfFirstWeekThisYear = 4 - iso8601DowThisYear;
		Integer dow = getDayOfWeek(d);
		Integer iso8601Dow = dow==0 ? 6 : dow-1;
		Date weekStartDate = d.addDays(-iso8601Dow);
		Date weekEndDate = weekStartDate.addDays(6);

		Date dayInFirstWeekOfNextYear = Date.newInstance(d.year()+1,1,4);
		Integer dowNextYear = getDayOfWeek(dayInFirstWeekOfNextYear);
        Integer iso8601DowNextYear = dowNextYear==0 ? 6 : dowNextYear-1;
		Date firstDateOfFirstWeekNextYear = dayInFirstWeekOfNextYear.addDays(-iso8601DowNextYear);

		if(dayOfYear<firstDayOfFirstWeekThisYear){
			Integer diff = firstDayOfFirstWeekThisYear-dayOfYear;
			if(diff==3)return new Week(d.year()-1,53,weekStartDate,weekEndDate);
			if(diff==2){
				Integer daysOfLastYear = Date.newInstance(d.year()-1,12,31).dayOfYear();
				if(daysOfLastYear==365)return new Week(d.year()-1,52,weekStartDate,weekEndDate);
				else return new Week(d.year()-1,53,weekStartDate,weekEndDate);
			}
			if(diff==1)return new Week(d.year()-1,52,weekStartDate,weekEndDate);
		}
		if(d>=firstDateOfFirstWeekNextYear)return new Week(d.year()+1,1,weekStartDate,weekEndDate);
		return new Week(d.year(),(Integer)Math.floor((dayOfYear-firstDayOfFirstWeekThisYear)/7)+1,weekStartDate,weekEndDate);
	}

    /**
		Returns the previous occurrence of the specified date
		@dayOfWeek The day of week which should be used
		@d The current date
		@inclusive Whether the current date may be returned if the current date is the specified day of week
		@return the previous occurrence of the specified day of week
	*/
	public static Date getPrevOccurrenceOfDay(Integer dayOfWeek,Date d,Boolean inclusive){
		Integer dateDayOfWeek = getDayOfWeek(d);
		Integer diff = dayOfWeek - dateDayOfWeek;
		if((diff>0 && inclusive) || (diff>=0 && !inclusive))diff-=7;
		return d.addDays(diff);
    }


    /**
        Computes the holiday instances for the given year range
        @param fromYear The year from which to compute the holidays
        @param toYear The year to which to compute the holidays
    */
    global static HolidayInstance[] getHolidays(Date fromDate,Date toDate){
        if(holidayList==null)holidayList = [SELECT Id,Name,ActivityDate,IsAllDay,IsRecurrence,RecurrenceDayOfMonth,RecurrenceDayOfWeekMask,RecurrenceStartDate,RecurrenceEndDateOnly,RecurrenceInstance,RecurrenceInterval,RecurrenceMonthOfYear,RecurrenceType FROM Holiday WHERE IsAllDay=true];
        List<HolidayInstance> hInstList = new List<HolidayInstance>();
        for(Integer i=0,sz=holidayList.size();i<sz;i++){
            Holiday h = holidayList[i];
            Date endDate = (h.RecurrenceEndDateOnly==null || h.RecurrenceEndDateOnly>toDate) ? toDate : h.RecurrenceEndDateOnly;
            if(h.IsRecurrence && h.RecurrenceStartDate<=toDate && endDate>=fromDate){
                if(h.RecurrenceType==RECURRENCE_TYPE_DAILY || h.RecurrenceType==RECURRENCE_TYPE_EVERY_WEEKDAY){
                    Integer interval = h.RecurrenceType==RECURRENCE_TYPE_EVERY_WEEKDAY ? 1 : h.RecurrenceInterval;
                    Boolean excludeWeekends = h.RecurrenceType==RECURRENCE_TYPE_EVERY_WEEKDAY;
                    Date d = h.RecurrenceStartDate;
                    while(d<=endDate){
                        Integer y = d.year();
                        if(d>=fromDate && d<=toDate && (!excludeWeekends || !isWeekend(d))){
                            hInstList.add(new HolidayInstance(h.Name,d));
                        }
                        d = d.addDays(interval);
                    }
                }
                else if(h.RecurrenceType==RECURRENCE_TYPE_WEEKLY){
                    Integer interval = 7 * h.RecurrenceInterval;
                    Date d = h.RecurrenceStartDate;
                    d = d.addDays(-getDayOfWeek(d));
                    //Computes week by week
                    while(d<=endDate){
                        //Computing every day of the week
                        for(Integer dow=0;dow<7;dow++){
                            if(d>=h.RecurrenceStartDate && d>=fromDate && d<=endDate && (h.RecurrenceDayOfWeekMask & (1<<dow))!=0){
                                hInstList.add(new HolidayInstance(h.Name,d));
                            }
                            d = d.addDays(1);
                        }
                        //Skipping weeks if week intervals are applied
                        d = d.addDays(7*(h.RecurrenceInterval-1));
                    }
                }
                else if(h.RecurrenceType==RECURRENCE_TYPE_MONTHLY || h.RecurrenceType==RECURRENCE_TYPE_MONTHLY_NTH){
                    Boolean nth = h.RecurrenceType==RECURRENCE_TYPE_MONTHLY_NTH;
                    Integer y = h.RecurrenceStartDate.year();
                    Integer m = h.RecurrenceStartDate.month();
                    Integer yn = endDate.year();
                    Integer mn = endDate.month();
                    while(y<yn || (y==yn && m<=mn)){
                        Date d = nth ? getNthDayInMonth(y,m,h.RecurrenceInstance,h.RecurrenceDayOfWeekMask) : Date.newInstance(y,m,h.RecurrenceDayOfMonth);
                        if(d>=h.RecurrenceStartDate && d>=fromDate && d<=endDate){
                            hInstList.add(new HolidayInstance(h.Name,d));
                        }
                        m+=h.RecurrenceInterval;
                        if(m>12){
                            y++;
                            m-=12;
                        }
                    }
                }
                else if(h.RecurrenceType==RECURRENCE_TYPE_YEARLY || h.RecurrenceType==RECURRENCE_TYPE_YEARLY_NTH){
                    Boolean nth = h.RecurrenceType==RECURRENCE_TYPE_YEARLY_NTH;
                    Integer y = h.RecurrenceStartDate.year();
                    Integer m = 0;
                    switch on h.RecurrenceMonthOfYear{
                        when 'January' {m=1;}
                        when 'Febuary' {m=2;}
                        when 'March' {m=3;}
                        when 'April' {m=4;}
                        when 'May' {m=5;}
                        when 'June' {m=6;}
                        when 'July' {m=7;}
                        when 'August' {m=8;}
                        when 'September' {m=9;}
                        when 'October' {m=10;}
                        when 'November' {m=11;}
                        when 'December' {m=12;}
                        when else{throw new CalendarException('Unknown holiday month of year: '+h.RecurrenceMonthOfYear);}
                    }
                    Integer yn = endDate.year();
                    Integer mn = endDate.month();
                    while(y<yn || (y==yn && m<=mn)){
                        Date d = nth ? getNthDayInMonth(y,m,h.RecurrenceInstance,h.RecurrenceDayOfWeekMask) : Date.newInstance(y,m,h.RecurrenceDayOfMonth);
                        if(d>=h.RecurrenceStartDate && d>=fromDate && d<=endDate){
                            hInstList.add(new HolidayInstance(h.Name,d));
                        }
                        y++;
                    }
                }
                else throw new CalendarException('Unknown holiday reccurence type: '+h.RecurrenceType);
            }
            else {
                Integer y = h.ActivityDate.year();
                if(h.ActivityDate>=fromDate && h.ActivityDate<=endDate){
                    hInstList.add(new HolidayInstance(h.Name,h.ActivityDate));
                }
            }
        }
        return hInstList;
    }
    /**
        Calculates the nth instnace of a day of week in a given month
        @param y The year for which to calculate the date
        @param m The month for which to calculate the date
        @param recurrenceInstance The Holiday recurrence instance, i.e. whether its the First, Second, Third, Forth or Last Instance of the day
        @param dowMask The day of week mask which states which days of the week should count as an instance
    */
    private static Date getNthDayInMonth(Integer y,Integer m,String recurrenceInstance,Integer dowMask){
        Date d = null;
        Integer instance = -1;
        if(recurrenceInstance=='First')instance = 1;
        else if(recurrenceInstance=='Second')instance = 2;
        else if(recurrenceInstance=='Third')instance = 3;
        else if(recurrenceInstance=='Fourth')instance = 4;
        if(instance!=-1){
            Integer dom = 1;
            Integer dow = getDayOfWeek(y,m,1);
            if((dowMask & (1<<dow))!=0)instance--;
            while(instance>0){
                dom++;
                dow++;
                if(dow>6)dow-=7;
                if((dowMask & (1<<dow))!=0)instance--;
            }
            d = Date.newInstance(y,m,dom);
        }
        else if(recurrenceInstance=='Last'){
            d = Date.newInstance(y,m,1).addMonths(1).addDays(-1);
            Integer negD = 0;
            Integer dow = getDayOfWeek(d);
            while((dowMask & (1<<dow))==0){
                negD++;
                dow--;
                if(dow<0)dow+=7;
            }
            d = d.addDays(-negD);
        }
        else throw new CalendarException('Unknown holiday recurrence instance: '+recurrenceInstance);
        return d;
    }

    /**
        Updates the holiday cache with holidays 
        @param yFrom The start year of the range which should be incldued in the cache
        @param yTo The end year of the range which should be included in the cache
    */
    private static void updateHolidayCache(Integer yFrom,Integer yTo){
        Boolean upd = false;
        if(HSC==null){
            HSC = new Set<Date>();
            upd = true;
        }
        else if(yFrom<HSC_FROM || yTo>HSC_TO){
            //Auto expand range to cover all values in between
            if(yTo<HSC_FROM)yTo = HSC_FROM-1;
            if(yFrom>HSC_TO)yFrom = HSC_TO+1;
            upd = true;
        }
        if(upd){
            HolidayInstance[] hiList = getHolidays(Date.newInstance(yFrom,1,1), Date.newInstance(yTo,12,31));
            for(Integer i=0,sz=hiList.size();i<sz;i++){
                HSC.add(hiList[i].holidayDate);
            }
            //Setting new range of cached values
            if(HSC_FROM==null || yFrom<HSC_FROM)HSC_FROM=yFrom;
            if(HSC_TO==null || yTo>HSC_TO)HSC_TO=yTo;
        }
    }

    /**
        Calculates whether the supplied date is a holiday
        Note: only all day holidays are considered
        @param d The date to check whether it is a holiday
        @return Whether the date is a holiday
    */
    global static Boolean isHoliday(Date d){
        Integer y = d.year();
        updateHolidayCache(y,y);
        return HSC.contains(d);
    }


    /**
        Retrieve the name of the holiday on the given date
        This method returns an empty list if the date does not occur on a holiday
        Note: only all day holidays are considered
        @param d The date to get the holiday of
        @return The holidays of the date
    */
    global static HolidayInstance[] getHoliday(Date d){
        return getHolidays(d, d);
    }

    /**
        Class to represent a holiday instance
    */
    global class HolidayInstance{
        /**
            The name of the holiday
        */
        global String name;
        /**
            The date of the holiday
        */
        global Date holidayDate;

        /**
            Creates a holiday instance
            @param name The name of the holiday
            @param fromDate The start date of the holiday
            @param toDate The end date of the holiday
        */
        HolidayInstance(String name,Date holidayDate){
            this.name = name;
            this.holidayDate = holidayDate;
        }
    }


}
