trigger Trig_Contact on Contact(after insert, after update)
{
try{
et4ae5.triggerUtility.automate('Contact');
}
catch(Exception e){
if(Test.isRunningTest()){
return;
} else {
throw e;
}
}
}