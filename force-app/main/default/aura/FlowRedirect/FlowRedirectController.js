({
    invoke : function(cmp, event, helper) {
        var url = cmp.get("v.url");
        var redirect = $A.get("e.force:navigateToURL");
        redirect.setParams({
            "url": url, 
            "isredirect": false
        });
        redirect.fire();
    }
})