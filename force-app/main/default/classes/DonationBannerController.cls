public without sharing class DonationBannerController {
    public String imageUrl {get; set;}
    @TestVisible
    private static final String ATTACHMENT_URL = 'servlet/servlet.FileDownload?file=';
    @TestVisible
    private static final String DOCUMENT_URL = 'servlet/servlet.ImageServer?id=';

    public DonationBannerController() {
        String pageId = ApexPages.currentPage().getParameters().get('id');
        if (pageId != null) {
            List<Attachment> attachments = [SELECT Id FROM Attachment WHERE ParentId = :pageId AND ContentType LIKE '%image%' LIMIT 1];
            if (attachments.size() > 0) {
                imageUrl = ATTACHMENT_URL + attachments.get(0).Id;
            }
        }
        if (String.isBlank(imageUrl)) {
            List<Document> documents = [SELECT Id FROM Document WHERE Name = 'Default Donation Banner' LIMIT 1];
            if (documents.size() > 0) {
                imageUrl = DOCUMENT_URL + documents.get(0).Id + '&oid=' + UserInfo.getOrganizationId();
            }
        }
    }
}