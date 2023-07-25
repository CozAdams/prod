@IsTest
private class DonationBannerControllerTest {

    @TestSetup
    static void setup() {
        SObjectFactory.create(dn8n__Donation_Page__c.SObjectType);
        Folder theFolder = [SELECT Id FROM Folder WHERE AccessType = 'Public' AND Type = 'Document' LIMIT 1];
        SObjectFactory.create(Document.SObjectType, new Map<SObjectField, Object> {
                Document.IsPublic => true, Document.FolderId => theFolder.Id, Document.Name => 'Default Donation Banner'
        });
    }

    @IsTest
    static void testDefaultBanner() {
        dn8n__Donation_Page__c donationPage = [SELECT Id FROM dn8n__Donation_Page__c LIMIT 1];
        PageReference thisPage = Page.dn8n__SiteDonation;
        thisPage.getParameters().put('id', donationPage.Id);
        Test.setCurrentPage(thisPage);
        Test.startTest();
        DonationBannerController controller = new DonationBannerController();
        Test.stopTest();

        Document doc = [SELECT Id FROM Document WHERE Name = 'Default Donation Banner' LIMIT 1];
        System.assertEquals(DonationBannerController.DOCUMENT_URL + doc.Id + '&oid=' + UserInfo.getOrganizationId(),
            controller.imageUrl, 'Url returned from the controller should match one pointing to a Document.');
    }

    @IsTest
    static void testCustomBanner() {
        dn8n__Donation_Page__c donationPage = [SELECT Id FROM dn8n__Donation_Page__c LIMIT 1];
        Attachment attach = (Attachment) SObjectFactory.create(Attachment.SObjectType, new Map<SObjectField, Object> {
                Attachment.ParentId => donationPage.Id, Attachment.Name => 'Name',
                Attachment.Body => Blob.valueOf('Hi!'), Attachment.ContentType => 'image/jpg'
        });

        PageReference thisPage = Page.dn8n__SiteDonation;
        thisPage.getParameters().put('id', donationPage.Id);
        Test.setCurrentPage(thisPage);
        Test.startTest();
        DonationBannerController controller = new DonationBannerController();
        Test.stopTest();

        System.assertEquals(DonationBannerController.ATTACHMENT_URL + attach.Id, controller.imageUrl,
            'Url returned from the controller should match one pointing to an Attachment.');
    }
}