/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class Importer_Test {

	static Site_Metric_Settings__c settings = new Site_Metric_Settings__c(Name = 'Test Site', email__c='test@test.com', password__c='gummybear', table_id__c='ga:12345', visitors__c=true,
																		 Page_views_per_visit__c=true, Percent_new_visits__c=true, Visit_bounce_rate__c=true, Average_time_on_site__c=true);

	static Site_Metric_Date__c metricDate = new Site_Metric_Date__c(Name = 'Test date', Start_Date__c = Date.newInstance(2011, 1, 1));
	
	static {
		
		// test method requires a clean database!
		// verify the database is clean before beginning:
		try {
	   		Site_Metric_Date__c d = [Select o.name from Site_Metric_Date__c o limit 1];
			System.assert(false, 'Cannot test imports without a clean database.  Run Importer.dataPurge() to delete relevant records');
			
	   		Site_Metric__c m = [Select o.name from Site_Metric__c o limit 1];
			System.assert(false, 'Cannot test imports without a clean database.  Run Importer.dataPurge() to delete relevant records');
			
		} catch (QueryException e) {
			// pass
		}

		// run the following to scrub the site metrics and dates.  this will delete all data:
		//Importer.dataPurge();

		insert settings;
		
	}

    static testMethod void importTest() {
        

        Importer imp = new Importer(settings.name);
        imp.doImport();
        
        Date lastImport = imp.getLastImportDate();
        System.assert(lastImport == null);
        
 		insert metricDate;		
 		lastImport = imp.getLastImportDate();
 		System.assert(lastImport == metricDate.Start_Date__c);
 		
 		List <string> metrics = imp.chooseMetrics(settings);
 		System.assertEquals(metrics.size(), 5);
 		
 		// database known to be clean, so this is safe
 		Importer.dataPurge();
 		
 		
    }
    
}