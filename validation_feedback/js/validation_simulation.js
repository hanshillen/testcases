$(function() {
	// The purpose of this script is to randomly generate a form a simulate an invalid form submission

	// Hans Hillen, TPG 2012
	//Configuration

	var useFloats = true; // if true, use floats for the form field containers rather than CSS display: table styles (overridden by checkbox)
	var colNumbers = 3; // Number of columns in form fields grid, only used with useFloats is false
	var useFieldInstructions = false; // Whether to add lorem ipsum text of variable length before each form field (to show alignment of fields)

	var groups = ["Personal", "Office", "Overseas", "Emergency Details"]; // The formfield groups to create in the demo

	// The field each formfield group will have. They will randomly be made a textfield or textarea
	// In each group, a randomly subset of "chosen fields" will be used to simulate invalid data
	var groupFields = ["First Name", "Last Name", "Address", "Zip Code", "City", "Date of Birth", "High School", "Country", "Maiden Name"];

	var groupDescriptions = [
		"This information is required by the IRS",
		"We would like to know a bit more abour yourself",
		"This information will not be shared with third parties",
		"A copy of this information will be sent to our sales department",
		"This information will be used to generate your profile"
	];

	// Texts used to randomly assign constraint texts for chosen fields
	var constraints = [
		"Should not be more than 100 characters",
		"Must be unique",
		"Enter the value as it appears on your tax statement",
		"Must be answered truthfully",
		"Must be answered with your eyes closed",
		"The expected format is MM-DD-YYYY",
		"This should be a valid social security number",
		"You can find this information on your driver's license"
	];

	// Error texts used to simulate invalid data on chosen form fields
	var errors = [
		"The value you entered was not recognized",
		"The value you entered is too short",
		"This is not a valid address",
		"Does not compute",
		"Too many typos",
		"Value is not allowed",
		"Required characters are missing",
		"Must be 10 digits",
		"Must be in the format 'MM-DD-YYYY'"
	];

	var errorRatio = 0.5; // Number between 0 and 1, indicating how many fields will have an error when the form submission is simulated

	//Random Text used to populate formfield group and formfield descriptions
	var loremIpsumShort = "Lorem ipsum dolor sit amet";

	// End configuration

	var chosenFields = [];

	// Optionally set parameters from URL
	if ($_GET("useFloats")) {
		useFloats = $_GET("useFloats") == "true";
	}

	if ($_GET("colNumbers")) {
		var tempVar = $_GET("colNumbers");
		if (!isNaN(tempVar)) {
			if (tempVar < 2)
				tempVar = 2;
			if (tempVar > 10)
				tempvar = 10;
			colNumbers = tempVar;
		}
	}

	if ($_GET("useFieldInstructions")) {
		useFieldInstructions = $_GET("useFieldInstructions") == "true";
	}
	//Functions

	//Get search parameter from URL
	function $_GET(q,s) {
        s = s ? s : window.location.search;
        var re = new RegExp('&'+q+'(?:=([^&]*))?(?=&|$)','i');
        return (s=s.replace(/^\?/,'&').match(re)) ? (typeof s[1] == 'undefined' ? '' : decodeURIComponent(s[1])) : undefined;
	}

	// Return random boolean, based on a threshhold betwene 0 and 1
	function randomBool(threshold) {
		if (!threshold)
			threshold = 0.5;
		return Math.random() >= threshold;
	}

	//Return random array item
	function randomItem(arr) {
		return arr[Math.floor(Math.random() * arr.length)];
	}

	//randomly repeat a string or number
	function randomlyMultiply(text, max, min) {
		if (min === undefined)
			min = 0;
		var factor = Math.floor(Math.random() * max);
		if (!isNaN)
			return factor * parseInt(text, 10);
		var newText = "";
		for (var i = 0; i < factor; i++) {
			newText += text;
		}
		return newText;
	}


	// Apply validation feedback to chosen fields and and vaidation summaries
	function simulateValidation(event) {
		event.preventDefault();
		var errorGroups = [];
		//Form simulation can ony happen once, otherwise the page has to be refreshed
		$(".triggerValidation").attr("disabled", "disabled");
		//assign an empty array to each formfield group, to store potential errors
		$.each(groups, function(i,e) {
			errorGroups[i] = [];
		});

		// the fields in chosenFields will be treated as invalid
		$.each(chosenFields, function(index, id) {
			var field = $("#" + id);
			var tokens = id.split("_");
			var groupNumber = tokens[0];
			var fieldNumber = tokens[1];
			var error = randomItem(errors);

			// Field level feedback: aria-invalid, tooltip and icon
			field.addClass("invalid").attr("aria-invalid", "true").after("<img src='images/exclamation-red.png' alt='invalid' />");
			field.attr("title", error).tooltip({
				position: {
					my: "left bottom-2",
					at: "center+5 top"
				},
				tooltipClass: "errorTooltip"});

			// Add this error to the appropriate formfield group's validation summary data
			errorGroups[groupNumber].push({fieldId : id, error : error });
		});

		//Page level summary
		var totalErrors = 0;
		// Get rid of groups that had no errors, and count total of errors in the whole form
		for (var i = errorGroups.length - 1; i>= 0; i--) {
			if (!errorGroups[i].length) {
				errorGroups.splice(i, 1);
			}
			else {
				totalErrors += errorGroups[i].length;
			}
		}
		// Generate the page level summary
		createErrorSummary(null, errorGroups, totalErrors);

		if (errorGroups.length > 0) {
			// Add feedback messages next to submit button, with a link to the page level summary
			var feedbackMsg = $("<p class='feedbackMsg'>Your form submission contained errors. Press Ctrl + Shift + Home or the 0 access key to go to the </p>");
			var summaryLink = $("<a href='#'>validation summary</a>").click(function(event){$("#pageSummary").focus();});
			feedbackMsg.append(summaryLink).insertAfter(".triggerValidation");
			//Make the feedback messgae an alert, so that it will be announced by screen readers
			$(".feedbackMsg:eq(0)").attr("role", "alert");
			// Assign global shortcut for moving focus to the page summary
			$(document).keyup(function(event){
				if (event.keyCode == 36 && event.ctrlKey && event.shiftKey) {
					$("#pageSummary").focus();
				}
			});
			// Update the page title to reflect the validation status
			document.title = document.title + " - " + chosenFields.length + " Errors in Form Submission";

			//Group level summarries
			$.each(errorGroups, function(i, group) {
				createErrorSummary("heading" + i, group);
			});
		}
		// After submission, move focus to the page summary
		$("#pageSummary").focus();
	}


	//Generates eitehr a page summary or a group summary
	// HeadingId is the heading that will be converted to a summary header, If null, the summary is assumed to be a page summary
	// ErrorGroup is the array containing info about invalid groups (for page summary) or fields (for group summary)
	// totalErrors: Number of errors in page / group
	function createErrorSummary(headingId, errorGroup, totalErrors) {
		var summaryContainer, heading, pageLevel = false;
		if (!totalErrors)
			totalErrors = errorGroup.length;
		if (!headingId) {
			//Generate a page level summary, create a new heading
			pageLevel = true;
			heading = $("<h2 id='pageSummaryHeading'></h2>")
				.addClass("errorSummaryHeading")
				.text(totalErrors + (totalErrors == 1 ? " error " : " errors ") + " in form submission");

			// The accesskey attribute is applied as a fallback for the global shortcut alreay defined
			summaryContainer = $("<div id='pageSummary' accesskey='0' class='formGroup' role='group' aria-labelledby='pageSummaryHeading'></div>")
				.append(heading);
				
			summaryContainer.insertAfter("#sampleForm > h2:eq(0)");
		}
		else {
			// Generate a group level summary, use an existing heading
			heading = $("#" + headingId);
			heading.text(heading.text() + " - " + errorGroup.length + (totalErrors == 1 ? " error " : " errors "));
			summaryContainer = heading.closest(".formGroup");
		}
		summaryContainer.addClass("errorGroup").attr("tabindex", "-1");

		if (!heading.length || !summaryContainer.length)
			return;

		// Generate the actual error list
		var errorList = $("<ul class='errorSummaryList'></ul>");

		$.each(errorGroup, function(i, e) {
			var item = $("<li></li>");
			var link = $("<a></a>");
			var target;
			if (pageLevel) {
				target = $("#group" + i);
				link.html("The '<strong>" + groups[i] + "</strong>' section has " + e.length +  (e.length == 1 ? " error " : " errors "));
			}
			else {
				target = $("#" + e.fieldId);
				link.text(target.data("lblTxt") + ": " + e.error);
			}
			link.attr("href", "#" + target.attr("id"))
				.click(function(event){ event.preventDefault(); target.focus();})
				.mouseover(function(event){ target.addClass("highlighted");})
				.focus(function(event){ target.addClass("highlighted");})
				.mouseout(function(event){ target.removeClass("highlighted");})
				.blur(function(event){ target.removeClass("highlighted");});

			item.append(link).appendTo(errorList);
		});
		errorList.insertAfter(heading);
	}

	// End Functions


	// Init
	var form = $("#sampleForm").prepend("<h2>Form Start</h2>");
	var submitBtn = $("<input type='submit' class='triggerValidation' value='Simulate Form Submission' />").click(simulateValidation).appendTo(form);
	var i;
	// Randomly choose fields to be treated as "invalid" submission simulation
	// 'Chosen' fields will be marked up as required, given a constraint text, and show a validation error after submission
	for (i = 0; i < groups.length; i++) {
		for (var j = 0; j < groupFields.length; j++) {
			if (randomBool(errorRatio)) {
				chosenFields.push(i + "_" + j);
			}
		}
	}

	// Generate form fields
	$.each(groups, function(i, groupName ) {
		var group, heading, groupDesc, grid, row;
		group = $("<div></div>").attr({id : "group"+ i,
			role : "group",
			"aria-labelledby" : "heading" + i,
			"aria-describedby" : "groupDesc" + i})
			.addClass("formGroup").appendTo(form);
		heading = $("<h2></h2>").attr("id", "heading" + i).text(groupName).appendTo(group);
		groupDesc = $("<p></p>").attr("id", "groupDesc" + i).addClass("groupDesc").text(randomItem(groupDescriptions)).insertAfter(heading);
		grid = $("<div></div>").addClass(useFloats ? "ui-helper-clearfix useFloats" : "gridLayout useCSSTables").appendTo(group);
		$.each(groupFields, function(j, groupField) {
			var container, label, instructions, required, input, constraint;
			var id = i + "_" +j;
			var chosen = $.inArray(id, chosenFields) != -1;
			if (!useFloats) {
				if (j % colNumbers === 0) {
					row = $("<div></div>").addClass("gridLayoutRow").appendTo(grid);
				}
			}
			container = $("<div></div>").addClass("fieldContainer");
			label = $("<label></label>").text(groupField).attr("for", id);

			input = $(randomBool() ? "<input type='text' />" : "<textarea></textarea>").attr("id", id).data("lblTxt", groupField)
				.attr("placeholder", "Enter text here...");

			container.append(label, input).appendTo(useFloats ? grid : row);

			if (useFieldInstructions) {
				instructions = $("<p></p>").addClass("fieldInstructions").text(randomlyMultiply(loremIpsumShort, 6)).insertAfter(label);
			}


			if (chosen) {
				label.addClass("required")
					.prepend($("<img />").attr({src : "images/required_asterisk.png", alt : ""}));

				input.attr("aria-required", "true");
				constraint = $("<span tabindex='-1'></span>")
					.addClass("constraint")
					.text(randomItem(constraints))
					.attr("id", "constraint_" + id)
					.insertAfter(input);
				input.attr("aria-describedby", constraint.attr("id"));
			}
		});

		if (useFloats) {
			grid.find(".fieldInstructions").equalHeights();
			grid.find(".fieldContainer").equalHeights();
		}
		else {
			var rows = group.find(".gridLayoutRow").each(function(i, val){
				var row = $(this);
				row.find(".fieldInstructions").equalHeights();
			});
		}
	});

	//add second submit button
	submitBtn.clone(true).appendTo(form);

	// Add demo configuration options
	var configurationOptions = $("<div></div>").addClass("configurationOptions");
	
	$("h1:eq(0)").after("<p>This is a fake form that only simulates validation feedback. " +
		"It is not necessary to fill in any fields, validation errors are randomly created when " +
		"the 'Simulate Form Submission' button is pressed. The constraint texts " +
		"and validation messages are randomized and do not match each other .To clear the validation results, click the 'recreate form' button.</p>",
		"<h2>Demo Configuration Options</h2>",
		configurationOptions
		);
	
	/*
	var columnSelector = $("<select id='columnSelector'></select>").appendTo(configurationOptions)
			.before("<label for='columnSelector'>Number of Columns</label>");

	for (i = 1; i <= 10; i++) {
		var option = $("<option></option>").text(i).attr("value", i).appendTo(columnSelector);
		if (i == colNumbers)
			option.attr("selected", "selected");

	}
	if (useFloats) {
		columnSelector.attr("disabled", "disabled");
	}
	*/
	var useFloatsChk = "";//$("<input />").attr("type", "checkbox").attr("id", "useFloatsChk")
		//.prop("checked", useFloats).appendTo(configurationOptions).after("<label for='useFloatsChk'>Use CSS floats rather than table display styles</label>");

	var useFieldInstructionsChk = "";// $("<input />").attr("type", "checkbox").attr("id", "useFieldInstructionsChk")
		//.prop("checked", useFieldInstructions).appendTo(configurationOptions).after("<label for='useFieldInstructionsChk'>Add lorem ipsum field instructions</label>");

	var refreshBtn = $("<button>Regenerate Demo Form</button>").click(function(event){
		document.location="index.html"; //?useFloats=" + useFloatsChk.prop("checked") + "&colNumbers=" + columnSelector.val() +
			//"&useFieldInstructions="; //+ useFieldInstructionsChk.prop("checked");
	}).appendTo(configurationOptions);
});