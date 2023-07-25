({
    loadAvatar : function(cmp){
        let action = cmp.get('c.getAvatarURL');

        action.setCallback(this, function(response){
            let state = response.getState();
            if(state === 'SUCCESS'){
                cmp.set('v.avatarURL', response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },
	loadData : function(cmp) {
		let action = cmp.get('c.retrieveRunningUserContact');

		action.setCallback(this, function(response){
			let state = response.getState();
			if(state === 'SUCCESS'){
				cmp.set('v.contact', response.getReturnValue());
				this.loadSettings(cmp);
			} else if (state === 'ERROR'){
			    this.showToast('Could not load Contact. Please ensure you are logged into the community!');
			}
		});
		$A.enqueueAction(action);
	},
    loadSettings: function(cmp) {
        let action = cmp.get('c.retrieveCalculatorSetting');

        action.setCallback(this, function(response){
            let state = response.getState();
            if(state === 'SUCCESS'){
                cmp.set('v.calculatorSetting', response.getReturnValue());
                cmp.set('v.salaryMin', cmp.get('v.calculatorSetting.Salary_Lower_Bounds__c').toString());
                cmp.set('v.salaryMax', cmp.get('v.calculatorSetting.Salary_Upper_Bounds__c').toString());
                this.initializeValues(cmp);
            } else if (state === 'ERROR'){
                this.showToast('Could not load calculator settings!');
            }
        });
        $A.enqueueAction(action);
    },
	initializeValues : function(cmp) {
		let contact = cmp.get('v.contact');

		// Profile
		let dob = $A.localizationService.parseDateTimeISO8601(contact.Birthdate);
        cmp.set('v.birthdate', this.formatPrintableDate(dob));
        let birthYear = dob.getFullYear();

        let date65 = $A.localizationService.parseDateTimeISO8601(dob.valueOf());
        date65.setFullYear(birthYear + 65);
        cmp.set('v.date65', this.formatISODate(date65));

        let eligDate = this.calcEligDate(date65);
        cmp.set('v.eligDate', this.formatISODate(eligDate));
        cmp.set('v.memberPIN', contact.PIN__c);

        // Calculations
        let today = new Date();
        if (today < eligDate) {
            cmp.set('v.retireDate', this.formatISODate(eligDate));
            this.calcRetirementAge(cmp);
        } else {
            eligDate = today;
            eligDate.setDate(1);
            eligDate.setMonth(eligDate.getMonth() + 1);
            cmp.set('v.retireDate', this.formatISODate(eligDate));
            this.calcRetirementAge(cmp);
        }
        if (contact.DB_Membership_Status__c == 'Inactive' || contact.DB_Membership_Status__c === 'Refund Vested' || contact.DB_Membership_Status__c === 'Unclaimed Balance') {
            cmp.set('v.salary', 0);
        } else {
            const calculatorSetting = cmp.get('v.calculatorSetting');
            cmp.set('v.salary', contact.Annual_Salary__c >= calculatorSetting.Salary_Upper_Bounds__c ? calculatorSetting.Salary_Upper_Bounds__c : contact.Annual_Salary__c);
        }
        cmp.set('v.yearlyPercentageSalaryIncrease', 3);

        // Current Portfolio
        cmp.set('v.pensionCredits', contact.Pension_Credits__c);
        cmp.set('v.specialApportionmentCredits', contact.Special_Apportionment_Credits__c);
        cmp.set('v.lateRetirementCredits', contact.Late_Retirement_Credits__c);
		cmp.set('v.currentPensionCredits', contact.Total_Credits__c);

        this.calculateDynamicValues(cmp);
        this.calculateSalaryIncrement(cmp);
        this.initChart(cmp);
	},
    calculateSalaryIncrement: function(cmp) {
        let today = new Date();
        let contact = cmp.get('v.contact');
        let dob = $A.localizationService.parseDateTimeISO8601(contact.Birthdate);
        let birthYear = dob.getFullYear();
        let date65 = $A.localizationService.parseDateTimeISO8601(dob.valueOf());
        date65.setFullYear(birthYear + 65);
        let date70 = $A.localizationService.parseDateTimeISO8601(dob.valueOf());
        date70.setFullYear(birthYear + 70);

        if (today.getDate() !== 1) {
            today.setDate(1);
            today.setMonth(today.getMonth() + 1);
        }

        let monthsToRetirement = 0;
        if (contact.DB_Membership_Status__c === 'Payout' || contact.DB_Membership_Status__c === 'Inactive' || contact.DB_Membership_Status__c === 'Refund Vested' || contact.DB_Membership_Status__c === 'Ministerial Relief' || contact.DB_Membership_Status__c === 'Unclaimed Balance') {
            cmp.set('v.monthlyProjPension65', this.round(cmp.get('v.currentPensionCredits') / 12, 2));
        } else {
            if (today < date65) {
                monthsToRetirement = this.calcMonthsToRetirement(today, date65);
            }
            cmp.set('v.monthlyProjPension65', this.round((cmp.get('v.currentPensionCredits') + this.getAdditionalCreditsThroughRetirement(cmp, contact, monthsToRetirement, 0, cmp.get('v.retirementAge'))) / 12, 2));
        }
        if (today < date70) {
            monthsToRetirement = this.calcMonthsToRetirement(today, date70);
        }
        let additionalCreditsThroughRetirement = this.getAdditionalCreditsThroughRetirement(cmp, contact, monthsToRetirement, 60, 70);
        cmp.set('v.monthlyProjPension70', this.round(this.round((cmp.get('v.currentPensionCredits') + additionalCreditsThroughRetirement +
            this.getAdditionalLateRetirementCredits(cmp, contact, additionalCreditsThroughRetirement, 60)), 2) / 12, 2));
    },
    calculateDynamicValues: function(cmp) {
        let today = new Date();
        let eligDate = cmp.get('v.eligDate');
        let contact = cmp.get('v.contact');
        let dob = $A.localizationService.parseDateTimeISO8601(contact.Birthdate);
        let birthYear = dob.getFullYear();
        let date65 = $A.localizationService.parseDateTimeISO8601(dob.valueOf());
        date65.setFullYear(birthYear + 65);
        let date70 = $A.localizationService.parseDateTimeISO8601(dob.valueOf());
        date70.setFullYear(birthYear + 70);

        if (today.getDate() !== 1) {
            today.setDate(1);
            today.setMonth(today.getMonth() + 1);
        }
        cmp.set('v.monthsUntilRetirement', this.calcMonthsToRetirement(today, cmp.get('v.retireDate')));
        cmp.set('v.pensionCredsPerMonth', this.getPensionCreditsPerMonth(cmp));
        let monthsBetweenEligAndRetirement = this.calcMonthsToRetirement(eligDate, cmp.get('v.retireDate'));
        if (date65 <= $A.localizationService.parseDateTimeISO8601(cmp.get('v.lateRetirementCreditStartDate'))) {
            cmp.set('v.monthsOfEarlyLateRetirement', this.calcMonthsToRetirement($A.localizationService.parseDateTimeISO8601(cmp.get('v.lateRetirementCreditStartDate')), date70));
            monthsBetweenEligAndRetirement = cmp.get('v.monthsOfEarlyLateRetirement');
        } else if ($A.localizationService.parseDateTimeISO8601(cmp.get('v.retireDate')) > date70) {
            cmp.set('v.monthsOfEarlyLateRetirement', this.calcMonthsToRetirement(eligDate, date70));
        } else {
            cmp.set('v.monthsOfEarlyLateRetirement', this.calcMonthsToRetirement(eligDate, $A.localizationService.parseDateTimeISO8601(cmp.get('v.retireDate'))));
        }

        // Future Estimated Portfolio
        cmp.set('v.addtlCredsThruRetirement', this.round(
            this.getAdditionalCreditsThroughRetirement(cmp, contact, cmp.get('v.monthsUntilRetirement'), monthsBetweenEligAndRetirement, cmp.get('v.retirementAge')), 2));
        if (cmp.get('v.retirementAge') >= 70) {
            let monthsToRetirement = 0;
            if (this.calcMonthsToRetirement(today, date70) >= 0) {
                monthsToRetirement = this.calcMonthsToRetirement(today, date70);
            }
            cmp.set('v.addtlLateRetirementCreds', this.round(
                this.getAdditionalLateRetirementCredits(cmp, contact, this.round(
                    this.getAdditionalCreditsThroughRetirement(cmp, contact, monthsToRetirement, 60), 2),
                    monthsBetweenEligAndRetirement), 2)
            );
        } else {
            cmp.set('v.addtlLateRetirementCreds', this.round(
                this.getAdditionalLateRetirementCredits(cmp, contact, cmp.get('v.addtlCredsThruRetirement'), monthsBetweenEligAndRetirement), 2));
        }
        if (monthsBetweenEligAndRetirement < 0) {
            cmp.set('v.totalCredsAtProjRetirement', (this.getPensionCreditsPerMonth(cmp) * cmp.get('v.monthsUntilRetirement')) + cmp.get('v.currentPensionCredits') + cmp.get('v.addtlCredsThruRetirement') + cmp.get('v.addtlLateRetirementCreds'));
        } else {
            cmp.set('v.totalCredsAtProjRetirement', cmp.get('v.currentPensionCredits') + cmp.get('v.addtlCredsThruRetirement') + cmp.get('v.addtlLateRetirementCreds'));
        }
        cmp.set('v.monthlyProjPension', this.round(cmp.get('v.totalCredsAtProjRetirement') / 12, 2));
    },

    getPensionCreditsPerMonth : function(cmp, monthsUntilRetirement) {
        if (monthsUntilRetirement == null) {
            monthsUntilRetirement = cmp.get('v.monthsUntilRetirement');
        }
        let yearsUntilRetirement = parseInt(monthsUntilRetirement / 12);
        let yearlyPercentageSalaryIncrease = parseFloat(cmp.get('v.yearlyPercentageSalaryIncrease'));
        let salary = parseFloat(cmp.get('v.salary'));
        let totalIncome = 0;

        if (yearsUntilRetirement === 0) {
            yearsUntilRetirement = 1;
        }

        for(let i = 0; i < yearsUntilRetirement; i++) {
            totalIncome = totalIncome + salary;
            salary = salary * (1+(yearlyPercentageSalaryIncrease / 100));
        }

        let avgSalary = totalIncome / yearsUntilRetirement;
        return this.round(avgSalary / 12 * 0.14 * 11 / 14 / 7.35, 2);
    },

    getAdditionalCreditsThroughRetirement: function(cmp, contact, monthsUntilRetirement, monthsOfEarlyLateRetirement, retirementAge) {
        if ((contact.DB_Membership_Status__c === 'Payout' || contact.DB_Membership_Status__c === 'Inactive' || contact.DB_Membership_Status__c === 'Refund Vested' || contact.DB_Membership_Status__c === 'Ministerial Relief' || contact.DB_Membership_Status__c === 'Unclaimed Balance') && retirementAge >= 65) {
            return 0;
        }
        let earlyRetirementFactor = this.round(1 - (monthsOfEarlyLateRetirement * .006), 3);
        let totalMonthlyCredits = this.getPensionCreditsPerMonth(cmp, monthsUntilRetirement) * monthsUntilRetirement;
        // Early Retirement
        if (monthsOfEarlyLateRetirement < 0 && earlyRetirementFactor > 0) {
            return (totalMonthlyCredits + cmp.get('v.currentPensionCredits')) - ((totalMonthlyCredits + cmp.get('v.currentPensionCredits')) * earlyRetirementFactor);
        } else { // Retirement at 65+
            return totalMonthlyCredits;
        }
    },
    getAdditionalLateRetirementCredits: function(cmp, contact, additionalCreditsThroughRetirement, monthsOfEarlyLateRetirement) {
        if (contact.DB_Membership_Status__c === 'Payout' || contact.DB_Membership_Status__c === 'Inactive' || contact.DB_Membership_Status__c === 'Refund Vested' || contact.DB_Membership_Status__c === 'Ministerial Relief' || contact.DB_Membership_Status__c === 'Unclaimed Balance' || monthsOfEarlyLateRetirement <= 0) {
            return 0;
        }
        let lateRetirementFactor = 0;
        if(monthsOfEarlyLateRetirement > 59) {
            lateRetirementFactor = 0.3;
        } else {
            lateRetirementFactor = monthsOfEarlyLateRetirement * 0.005;
        }
        return (additionalCreditsThroughRetirement + cmp.get('v.currentPensionCredits')) * lateRetirementFactor;
    },
    initChart: function(cmp) {
	    let labels = ['Desired','65', '70'];
        cmp.set('v.chart', new Chart(cmp.find('chart').getElement(),{
            type: 'bar',
            data: {
                labels: labels,
                datasets: [{
                    label: 'Estimated Monthly Pension',
                    backgroundColor: ['rgb(64, 91, 130)','rgb(64, 91, 130)','rgb(64, 91, 130)'],
                    data: [
                        cmp.get('v.monthlyProjPension').toFixed(2),
                        cmp.get('v.monthlyProjPension65').toFixed(2),
                        cmp.get('v.monthlyProjPension70').toFixed(2)
                    ]
                }]
            },
            options: {
                events: false,
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    yAxes: [{
                        ticks: {
                            beginAtZero: true,
                            fontFamily: 'Brandon-Regular'
                        }
                    }],
                    xAxes:[{
                        ticks:{
                              fontFamily: 'Brandon-Regular'
                        }
                    }]

                },
                animation: {
                    onComplete: function() {
                        let chartInstance = this.chart;
                        let ctx = chartInstance.ctx;
                        ctx.textAlign = 'center';
                        ctx.fillStyle = 'white';
                        ctx.fontFamily= 'Brandon-Regular';

                        this.data.datasets.forEach(function (dataset, i) {
                            let meta = chartInstance.controller.getDatasetMeta(i);
                            meta.data.forEach(function (bar, index) {
                                let data = dataset.data[index];
                                data = data.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
                                ctx.fillText('$' + data, bar._model.x, bar._model.y + 15);
                            });
                        });
                    }
                },
                tooltips: {
                    enabled: false
                },
                legend: {
                    labels: {
                        fontFamily: 'Brandon-Regular'
                    }
                }
            }
        }));
    },
    updateChart: function(cmp) {
        let chart = cmp.get('v.chart');
        if (chart !== null) {
            chart.data.datasets[0].data[0] = cmp.get('v.monthlyProjPension').toFixed(2);
            chart.data.datasets[0].data[1] = cmp.get('v.monthlyProjPension65').toFixed(2);
            chart.data.datasets[0].data[2] = cmp.get('v.monthlyProjPension70').toFixed(2);
            chart.update();
        }
    },
	calcMonthsToRetirement : function(fromDate, toDate) {
		fromDate = $A.localizationService.parseDateTimeISO8601(fromDate);
		toDate = $A.localizationService.parseDateTimeISO8601(toDate);
		return (toDate.getFullYear() - fromDate.getFullYear()) * 12
			+ (toDate.getMonth() - fromDate.getMonth())
            + (fromDate.getDate() < toDate.getDate() ? 1 : 0);
	},
	calcEligDate : function(retireDate){
		let eligDate = $A.localizationService.parseDateTimeISO8601(retireDate.valueOf());
		if(retireDate.getMonth() < 11){
            eligDate.setDate(1);
			eligDate.setMonth(retireDate.getMonth() + 1);
		} else if(retireDate.getMonth() === 11){
            eligDate.setDate(1);
			eligDate.setMonth(0);
			eligDate.setFullYear(retireDate.getFullYear() + 1);
		}
		return eligDate;
	},
	formatISODate : function(d){
		d = $A.localizationService.parseDateTimeISO8601(d);
		return d.getFullYear()
			+ '-' + this.padNumber(d.getMonth() + 1, 2)
			+ '-' + this.padNumber(d.getDate(''), 2);
	},
    // This is necessary because there's a bug in lightning:formattedDateTime where any date with a year < 1970 and month
    // February will automatically make that date fall in March of that year
    formatPrintableDate: function(d) {
        let monthNames = [
            "Jan", "Feb", "Mar", "Apr", "May", "Jun",
            "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
        ];

        let day = d.getDate();
        let monthIndex = d.getMonth();
        let year = d.getFullYear();

        return  monthNames[monthIndex] + ' ' + day + ', ' + year;
    },
	padNumber : function(n, l){
		let str = '' + n;
		while(str.length < l){
			str = '0' + str;
		}
		return str;
	},
	saveCalc : function(cmp) {
        let retirementCalculation = cmp.get('v.saveRetirementCalculation');
        retirementCalculation.Projection_Date__c = new Date();
        retirementCalculation.Annual_Salary__c = cmp.get('v.salary');
        retirementCalculation.Contact__c = cmp.get('v.contact.Id');
        retirementCalculation.Monthly_Pension_Credits__c = this.getPensionCreditsPerMonth(cmp);
        retirementCalculation.Desired_Retirement_Date__c = cmp.get('v.retireDate');
        retirementCalculation.Name = 'Age ' + cmp.get('v.retirementAge') + ' - $' + cmp.get('v.salary');
        retirementCalculation.Salary_Percentage_Increase__c = cmp.get('v.yearlyPercentageSalaryIncrease');

        let action = cmp.get('c.saveCalculations');
        action.setParam('newCalc', retirementCalculation);
        action.setCallback(this, function(response){
            let state = response.getState();
            if(state === 'SUCCESS'){
                this.showToast('Calculation saved successfully!', 'success');
                this.loadCalculations(cmp);
            } else {
                this.showToast('Failed to save calculation!');
            }
        });
        $A.enqueueAction(action);
	},
    closeCard : function(cmp, cardName) {
	    let card = cmp.find(cardName + 'Card');
	    let buttonGroup = cmp.find('actionButton');
	    for (let i = 0; i < buttonGroup.length; i++) {
            $A.util.removeClass(buttonGroup[i], 'slds-hide');
        }
        $A.util.addClass(card, 'slds-hide');
	},
    openCard : function(cmp, cardName) {
        let card = cmp.find(cardName + 'Card');
        let buttonGroup = cmp.find('actionButton');
        for (let i = 0; i < buttonGroup.length; i++) {
            $A.util.addClass(buttonGroup[i], 'slds-hide');
        }
        $A.util.removeClass(card, 'slds-hide');
	},
    loadCalculations : function(cmp) {
        let action = cmp.get('c.loadCalculations');

        action.setCallback(this, function(response){
            let state = response.getState();
            if(state === 'SUCCESS'){
                let calculations = response.getReturnValue();
                cmp.set('v.calcList', calculations);
            } else if (state === 'ERROR'){
                this.showToast('Failed to load Calculations!');
            }
        });

        $A.enqueueAction(action);
    },
    calcRetirementDate: function(cmp) {
        let retirementAge = cmp.get('v.retirementAge');
        let retireDate = $A.localizationService.parseDateTimeISO8601(cmp.get('v.birthdate'));
        if(retireDate && retirementAge){
            retireDate.setFullYear(parseInt(retireDate.getFullYear()) + parseInt(retirementAge));
            retireDate = this.calcEligDate(retireDate);
            cmp.set('v.retireDate', this.formatISODate(retireDate));
        }
    },
    calcRetirementAge : function(cmp) {
        let birthdate = $A.localizationService.parseDateTimeISO8601(cmp.get('v.birthdate'));
        let retireDate = $A.localizationService.parseDateTimeISO8601(cmp.get('v.retireDate'));
        if (birthdate && retireDate && (retireDate.getFullYear() + '').length === 4) {
            if (retireDate.getFullYear() - birthdate.getFullYear() < 60) {
                cmp.set('v.retirementAge', 60);
                this.calcRetirementDate(cmp);
            } else {
                let age = retireDate.getFullYear() - birthdate.getFullYear();
                if (retireDate.getMonth() - birthdate.getMonth() < 0) {
                    age = age - 1;
                } else if (retireDate.getMonth() === birthdate.getMonth() && retireDate.getDate() - birthdate.getDate() < 0) {
                    age = age - 1;
                }
                cmp.set('v.retirementAge', age);
            }
        }
    },
    deleteCalculation : function(cmp, calculationId) {
        let action = cmp.get('c.deleteCalculations');
        action.setParam('calculationId', calculationId);
        action.setCallback(this, function(response){
            let state = response.getState();
            if(state === 'SUCCESS'){
                this.showToast('Calculation deleted successfully!', 'success');
                this.loadCalculations(cmp);
            } else if (state === 'ERROR'){
                this.showToast('Failed to delete Calculation!');
            }
        });

        $A.enqueueAction(action);
    },
    isDateInPast: function(dateChosen) {
        return dateChosen < new Date();
    },
    isDateFirstOfTheMonth: function(dateChosen) {
        return dateChosen.getDate() === 1;
    },
    round: function(initialNumber, decimalPlaces) {
        let factor = Math.pow(10, decimalPlaces);
        return Math.round(initialNumber * factor) / factor;
    },
    showToast: function (message, aType) {
        let type = 'error';
        if (aType != null) {
            type = aType;
        }
        let toast = $A.get('e.force:showToast');
        toast.setParams({
            mode: 'dismissable',
            message: message,
            duration: 5,
            type: type
        });
        toast.fire();
    }
})