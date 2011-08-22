global class Importer implements Schedulable {

	String settingsName;
	 
	public Importer(String settingsName) {
		this.settingsName = settingsName;
	}
	
	global void execute(SchedulableContext sc) {
		
		// schedule job entry point for importing data:
		doImport();
	}
	
    public void doImport() {

		System.debug(LoggingLevel.DEBUG, 'Fetching site metric settings for name: ' + this.settingsName);
		
		Site_Metric_Settings__c settings = [Select o.name, o.email__c, o.password__c, o.table_id__c, o.visitors__c, o.page_views_per_visit__c, o.percent_new_visits__c, o.visit_bounce_rate__c, o.average_time_on_site__c From Site_Metric_Settings__c o where o.name = :this.settingsName];
		
		System.debug(Logginglevel.INFO, 'Performing initial import using Site Metric Settings with Name = ' + settings.name);  	

		// We don't know the previous import history, so grab the last metrics date stored in the database to determine where to resume imports:
		Date lastImportDate = getLastImportDate();
		
		Date endDate = Date.today();
		Date startDate;
		
		if (lastImportDate == null) {
			// we have no previous metric dates, so we know to do the initial import of the last 30 days:
			startDate = endDate.addDays(-30); 		

		} else {
			// pick up where the last successful import left off:
			startDate = lastImportDate.addDays(1);
		}
		 		
		System.debug(LoggingLevel.INFO, 'Date range: [' + startDate + ' to ' + endDate + ']');

		List<string> metrics = chooseMetrics(settings);
		
		if (!Test.isRunningTest()) {
			importAnalyticsData(settings.name, settings.email__c, settings.password__c, settings.table_id__c, startDate, endDate, metrics);
		}
    }
    
    public List<string> chooseMetrics(Site_Metric_Settings__c settings) {
    	
    	List<string> metrics = new List<string>();
    	
		if (settings.Visitors__c) {
			// import visitors metric:
			System.debug(LoggingLevel.INFO, 'Importing visitors metric');
			metrics.add(GoogleAnalytics.VisitorsMetric);
		}
		
		if (settings.Page_views_per_visit__c) {
			// import page views per visit metric:
			System.debug(LoggingLevel.INFO, 'Importing page views per visit metric');
			metrics.add(GoogleAnalytics.PageViewsPerVisitMetric);
		}
		
		if (settings.Percent_new_visits__c) {
			// import percentage of new visits metric:
			System.debug(LoggingLevel.INFO, 'Importing percent new visits metric');
			metrics.add(GoogleAnalytics.PercentNewVisitsMetric);
			
		}
		
		if (settings.Visit_bounce_rate__c) {
			// import visitor bounce rate metric:
			System.debug(LoggingLevel.INFO, 'Importing visit bounce rate metric');
			metrics.add(GoogleAnalytics.VisitBounceRateMetric);
			
		}
		
		if (settings.Average_time_on_site__c) {
			// import average time on site:
			System.debug(LoggingLevel.INFO, 'Importing average time on site metric');
			metrics.add(GoogleAnalytics.AverageTimeOnSiteMetric);
		}		
		
		return metrics;
    }
    
    public Date getLastImportDate() {
    	// determine latest site metrics date in the database:
    	List <Site_Metric_Date__c> dates = [Select d.Start_Date__c from Site_Metric_Date__c d order by d.Start_Date__c desc];
     	System.debug(LoggingLevel.INFO, 'dates counts: ' + dates.size());
     	
     	if (dates.size() == 0) {
     		return null;
     	} else {
	     	Site_Metric_Date__c d = dates.get(0);
	     	System.debug(LoggingLevel.INFO, d);
	     	
	     	return d.Start_Date__c;
     	}
    }
	
	@future (callout=true)
	public static void importAnalyticsData(String settingsName, String email, String password, String tableId, Date startDate, Date endDate, List<string> metrics) {
		
		System.debug(LoggingLevel.INFO, 'Performing initial import of settings ' + settingsName);
	
		GoogleAnalytics ga = new GoogleAnalytics(email, password, tableId);
		
		ga.insertDailyMetrics(startDate, endDate, metrics);
	}

	
	public static void dataPurge() {
		// admin helper method to purge data:
		List<Site_Metric__c> objs = new List<Site_Metric__c>();

		objs = [Select o.Name From Site_Metric__c o];
		System.debug(LoggingLevel.INFO, 'Retrieved ' + objs.size() + ' site metric records to purge.');

		delete objs;

		// retrieve again to verify the purge:		
		objs = [Select o.Name From Site_Metric__c o];
		System.debug(LoggingLevel.INFO, 'Post-purge there are: ' + objs.size() + ' site metric records.');
	
	
		// purge corresponding site metric dates:
		List<Site_Metric_Date__c> dates = new List<Site_Metric_Date__c>();	

		dates = [Select o.Name From Site_Metric_Date__c o];
		System.debug(LoggingLevel.INFO, 'Retrieved ' + dates.size() + ' site metric date records to purge.');
		delete dates;

		// retrieve again to verify the purge:		
		dates = [Select o.Name From Site_Metric_Date__c o];
		System.debug(LoggingLevel.INFO, 'Post-purge there are: ' + dates.size() + ' site metric date records.');

	}
}