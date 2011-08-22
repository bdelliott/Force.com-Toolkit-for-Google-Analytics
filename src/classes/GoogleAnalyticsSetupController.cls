public class GoogleAnalyticsSetupController {
    
    public Site_Metric_Settings__c settings {get;set;}
    
    public GoogleAnalyticsSetupController() {
    	
    	Map<String, Site_Metric_Settings__c> allSettingsMap = Site_Metric_Settings__c.getall();
    	
    	Integer numSettings = allSettingsMap.size();
    	
    	if (numSettings > 1) {
	    	// We could add support for importing analytics data from multiple sites, but for this first iteration, we're limiting configuration to 1 site only as a datasource.
    		throw new GoogleAnalytics.GoogleAnalyticsException('Only 1 Site_Metric_Settings is allowed.  Please manually delete any extras created via the Setup interface.');
    	}
    	
    	if (numSettings == 0) {
    		// give user a blank form to fill our their settings instance:
	    	settings = new Site_Metric_Settings__c();
    	} else {
    		// a setting was already previously created: 
    		settings = allSettingsMap.values().get(0);
    	}

    }   

    public PageReference save() {
    	
    	System.debug(LoggingLevel.INFO, 'Saving Site Metric Settings');
    	
        if (settings.id == null)
            insert settings;
        else
            update settings;
        
        ApexPages.Message message = new ApexPages.Message(ApexPages.severity.INFO, 'Site Settings saved.');
        ApexPages.addMessage(message);
        
        // schedule jobs to do the initial and daily imports:
        try {
        	scheduleInitialImport();
    		scheduleNightlyImport();
    		
        } catch (System.AsyncException e) {
        	// jobs are likely already scheduled.  there's no way to check apriori if this is the case
        	System.debug(LoggingLevel.WARN, 'Failed to schedule import jobs.  Already scheduled? message=' + e.getMessage());
        }
    	
        return null;        
    }
    
    public void scheduleInitialImport() {
        // chedule a job to run in 1 minute to cover the initial import of 30 days.  this is a convenience so reports & dashboards will have data immediately!
    	
    	System.debug(LoggingLevel.INFO, 'Scheduling initial analytics data import');
    	
        Importer importer = new Importer(settings.name);
        
        DateTime now = Datetime.now(); // gmt date and time
         
		Datetime initialImportDateTime = now.addMinutes(1);
		
		Date d = initialImportDateTime.date(); // local date
		Time t = initialImportDateTime.time(); // local time
		
        // Seconds  Minutes  Hours  Day_of_month  Month  Day_of_week  optional_year
        String schedule = t.second() + ' ' + t.minute() + ' ' + t.hour() + ' ' + d.day() + ' ' + d.month() + ' ? ' + d.year();
        
        if (!Test.isRunningTest()) {
        	System.schedule('Google Analytics initial import job', schedule, importer);
        }
    }
    
    public void scheduleNightlyImport() {
    	// now schedule a nightly job to grab daily statistics:
    	
    	System.debug(LoggingLevel.INFO, 'Scheduling nightly analytics data import');

    	Importer importer = new Importer(settings.name);
    	
        // Seconds  Minutes  Hours  Day_of_month  Month  Day_of_week  optional_year
        String schedule = '0 0 0 * * ?'; // run every day at midnight
    	
    	if (!Test.isRunningTest()) {
    		System.schedule('Google Analytics nightly import job', schedule, importer);
    	}
    	
    }

}