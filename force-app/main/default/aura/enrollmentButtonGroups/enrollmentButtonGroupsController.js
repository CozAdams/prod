({
	handleEnrollmentEvent : function(component, event) {
		let eventResult = event.getParam("enrollmentType");
        component.set("v.selectedFormType", eventResult);
	}
})