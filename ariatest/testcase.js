/*
 * Role Tester v1.2
 *
 * Hans Hillen, TPG
 *
 */

/*
 * TODO: finish filter controls, expand collapse, allow both roles and states to be included and excluded
 * TODO: Add more realistic use cases:
 * composite controls, e.g. role="toolbar" or role="dialog" actually contains content rather than being an empty focusable span.
 *
 * TODO: Auto focus advancer, to automate traversal of all elements (somehow tie this into automated logging of what the browser exposes and the AT announces so that a report can be automatically generated)
 *
 */

/*jslint browser: true, devel: true, nomen: true, plusplus: true*/
/*global $, jQuery, alert, console*/
/*jslint indent: 4 */

$(function () {
    "use strict";
    var widgetRoles = {
            "alert": ["aria-expanded"],
            "alertdialog": ["aria-expanded"],
            "button": ["aria-expanded", "aria-pressed"],
            "checkbox": ["aria-checked"],
            "dialog": ["aria-expanded"],
            "gridcell": ["aria-readonly", "aria-required", "aria-selected", "aria-expanded"],
            "link": ["aria-expanded"],
            "log": ["aria-expanded"],
            "marquee": ["aria-expanded"],
            "menuitem": [],
            "menuitemcheckbox": ["aria-checked"],
            "menuitemradio": ["aria-checked", "aria-posinset", "aria-selected", "aria-setsize"],
            "option": ["aria-checked", "aria-posinset", "aria-selected", "aria-setsize"],
            "progressbar": ["aria-valuenow aria-valuetext aria-valuemax aria-valuemin"],
            "radio": ["aria-posinset", "aria-selected", "aria-setsize"],
            "scrollbar": ["aria-controls", "aria-orientation", "aria-valuemax", "aria-valuemin", "aria-valuenow", "aria-valuetext"],
            "slider": ["aria-valuenow aria-valuetext aria-valuemax aria-valuemin", "aria-orientation"],
            "spinbutton": ["aria-valuenow aria-valuetext aria-valuemax aria-valuemin aria-required"],
            "status": ["aria-expanded"],
            "tab": ["aria-expanded", "aria-selected"],
            "tabpanel": ["aria-expanded"],
            "textbox": ["aria-activedescendant", "aria-autocomplete", "aria-multiline", "aria-readonly", "aria-required"],
            "timer": ["aria-expanded"],
            "tooltip": ["aria-expanded"],
            "treeitem": ["aria-level", "aria-posinset", "aria-setsize", "aria-expanded", "aria-checked", "aria-posinset", "aria-selected", "aria-setsize"]
        },
        compositeRoles = {
            "combobox": ["aria-autocomplete", "aria-required", "aria-activedescendant"],
            "grid": ["aria-level", "aria-multiselectable", "aria-readonly", "aria-activedescendant", "aria-expanded"],
            "listbox": ["aria-multiselectable", "aria-required", "aria-expanded", "aria-activedescendant", "aria-expanded"],
            "menu": ["aria-activedescendant", "aria-expanded"],
            "menubar": ["aria-activedescendant", "aria-expanded", "aria-activedescendant"],
            "radiogroup": ["aria-required", "aria-activedescendant", "aria-expanded"],
            "tablist": ["aria-level", "aria-activedescendant", "aria-expanded"],
            "tree": ["aria-multiselectable", "aria-required", "aria-activedescendant", "aria-expanded"],
            "treegrid": ["aria-level", "aria-multiselectable", "aria-readonly", "aria-activedescendant", "aria-expanded", "aria-multiselectable", "aria-required"]
        },
        documentStructureRoles = {
            "article": ["aria-expanded"],
            "columnheader": ["aria-sort", "aria-readonly", "aria-required", "aria-selected", "aria-expanded"],
            "definition": ["aria-expanded"],
            "directory": ["aria-expanded"],
            "document": ["aria-expanded"],
            "group": ["aria-activedescendant", "aria-expanded"],
            "heading": ["aria-level", "aria-expanded"],
            "img": ["aria-expanded"],
            "list": ["aria-expanded"],
            "listitem": ["aria-level", "aria-posinset", "aria-setsize", "aria-expanded"],
            "math": ["aria-expanded"],
            "note": ["aria-expanded"],
            "presentation": [],
            "region": ["aria-expanded"],
            "row": ["aria-level", "aria-selected", "aria-activedescendant", "aria-expanded"],
            "rowgroup": ["aria-activedescendant", "aria-expanded"],
            "rowheader": ["aria-sort", "aria-readonly", "aria-required", "aria-selected", "aria-expanded"],
            "separator": ["aria-expanded", "aria-orientation"],
            "toolbar": ["aria-activedescendant", "aria-expanded"]
        },
        landmarkRoles = {
            "application": ["aria-expanded"],
            "banner": ["aria-expanded"],
            "complementary": ["aria-expanded"],
            "contentinfo": ["aria-expanded"],
            "form": ["aria-expanded"],
            "main": ["aria-expanded"],
            "navigation": ["aria-expanded"],
            "search": ["aria-expanded"]
        },
        ariaStates = {
            //widgetStates
            "aria-autocomplete": ["none", "list", "inline", "both"],
            "aria-checked": ["true", "false", "mixed"],
            "aria-disabled": ["true", "false"],
            "aria-expanded": ["true", "false"],
            "aria-hidden": ["true", "false"],
            "aria-haspopup": ["true", "false"],
            "aria-invalid": ["grammar", "true", "false", "spelling"],
            "aria-label": ["My label"],
            "aria-level": ["%n", 1],
            "aria-multiline": ["true", "false"],
            "aria-multiselectable": ["true", "false"],
            "aria-orientation": ["horizontal", "vertical"],
            "aria-pressed": ["true", "false"],
            "aria-readonly": ["true", "false"],
            "aria-required": ["true", "false"],
            "aria-selected": ["true", "false"],
            "aria-sort": ["ascending", "descending", "none", "other"],
            "aria-valuemax": ["%n", 100],
            "aria-valuemin": ["%n", 0],
            "aria-valuenow": ["%n", 25],
            "aria-valuetext": ["%s", "25 dollar"],
            //liveRegionStates
            "aria-atomic": ["true", "false"],
            "aria-busy": ["true", "false"],
            "aria-live": ["off", "polite", "assertive"],
            "aria-relevant": ["additions", "removals", "text", "all"],
            //dragAndDropStates
            "aria-dropeffect": ["copy", "move", "link", "execute", "popup", "none"],
            "aria-grabbed": ["true", "false"],
            //relationShipStates
            "aria-activedescendant": ["%idr_activeDescendant"],
            "aria-controls": ["%idr_controls"],
            "aria-describedby": ["%idr_describedBy"],
            "aria-flowto": ["%idr_flowTo"],
            "aria-labelledby": ["%idr_labelledBy"],
            "aria-owns": ["%idr_owns"],
            "aria-posinset": ["%n", 10],
            "aria-setsize": ["%n", 100],
            "htmlLabel": ["%idr_htmlLabel"],
            "title": ["my title"],
            "role": ["toggle role"]
        },
        globalStates = ["role", "aria-controls", "aria-disabled", "aria-grabbed", "aria-dropeffect", "aria-haspopup", "aria-hidden", "aria-labelledby", "aria-label", "aria-describedby", "aria-owns", "aria-flowto", "aria-live", "aria-atomic", "aria-busy", "aria-relevant", "htmlLabel", "title"],
        groups = {
            "Widget Roles": widgetRoles,
            "Composite Roles": compositeRoles,
            "Document Structure Roles": documentStructureRoles,
            "Landmark Roles": landmarkRoles
        },
        widgetIncrement = 0,
        $roles,
        currentFocusIndex;

    function toggleState(elem, backwards) {
        var stateDescHTML = "",
            dStateDescHTML = "",
            noUpdate = false,
            result,
            stateName,
            stateValue,
            stateValues,
            newValue,
            newStateValue,
            stateValueIndex,
            newStateValueIndex,
            pattern = /dState-(\S+)/g;

        function replaceStateValue(match, match1, match2, match3) {
            var newValue = backwards ? parseInt(match2, 10) - 1 : parseInt(match2, 10) + 1;
            return match1 + newValue + match3;
        }

        while ((result = pattern.exec(elem.attr("class"))) !== null) {
            stateName = result[1];
            if ($.inArray(stateName, ["aria-controls", "aria-owns", "aria-flowto", "aria-describedby", "aria-labelledby"]) !== -1) {
                return;
            }
            stateValue = elem.attr(stateName);
            stateValues = ariaStates[stateName];

            if (stateName !== "role" && (!stateValue || !stateValues)) {
                return;
            }

            switch (stateValues[0]) {
            case "%n":
                if (!isNaN(stateValue)) {
                    newStateValue = backwards ? parseInt(stateValue, 10) - 1 : parseInt(stateValue, 10) + 1;
                }
                break;
            case "%s":
                newStateValue = stateValue.replace(/(\D*)([0-9]+)(\D*)/, replaceStateValue);
                break;
            case "toggle role":
                if (elem.attr("role")) {
                    elem.data("role", elem.attr("role"));
                    elem.removeAttr("role");
                    stateDescHTML = "Role is not set";
                } else {
                    elem.attr("role", elem.data("role"));
                    stateDescHTML = "Role is set";
                }
                noUpdate = true;
                break;
            default:
                stateValueIndex = stateValues.indexOf(stateValue);
                if (stateValueIndex === -1) {
                    stateValueIndex = 0;
                }

                newStateValueIndex = backwards ? --stateValueIndex : ++stateValueIndex;
                if (newStateValueIndex >= stateValues.length) {
                    newStateValueIndex = 0;
                } else if (newStateValueIndex < 0) {
                    newStateValueIndex = stateValues.length - 1;
                }
                newStateValue = stateValues[newStateValueIndex];
            }
            if (!noUpdate) {
                elem.attr(stateName, newStateValue);
                stateDescHTML += stateName + " = '" + newStateValue + "'<br />";
            }
        }
        elem.closest(".widgetDemo").find(".dStateDesc").html(stateDescHTML);
    }

    function moveToAdjacentGroup(target, backwards) {
        var group = target.closest(".roleGroup"),
            adjacentGroup;
        if (!group) {
            return;
        }
        adjacentGroup = backwards ? group.prev(".roleGroup") : group.next(".roleGroup");
        if (!adjacentGroup.length) {
            adjacentGroup = group.siblings(".roleGroup")[backwards ? "last" : "first"]();
        }
        if (!adjacentGroup.length) {
            return;
        }
        adjacentGroup.find(".roleTest:first").focus();
    }

    function moveToAdjacentRole(target, forward) {
        var index = $roles.index(target),
            newIndex = 0;
        if (forward) {
            newIndex = index >= $roles.length ? 0 : index + 1;
        } else {
            newIndex = index <= 0 ? $roles.length - 1 : index - 1;
        }
        $roles.eq(newIndex).focus();
    }

    $("#demoContent").delegate(".roleTest", "keydown", function (e) {
        var target,
            dState,
            forward;
        if ($.inArray(e.keyCode, [13, 32, 37, 38, 39, 40]) === -1) {
            return;
        }
        event.stopPropagation();
        event.preventDefault();
        target = $(event.target);
        switch (e.keyCode) {
        case 13:
        case 32:
            toggleState(target, event.shiftKey ? true : false);
            break;
        case 37:
        case 39:
            forward = e.keyCode === 39;
            if (event.shiftKey) {
                moveToAdjacentRole(target, forward);
            }
            toggleState(target, forward);
            break;
        case 38:
        case 40:
            forward = e.keyCode === 40;
            if (event.shiftKey) {
                moveToAdjacentGroup(target, forward);
            } else {
                toggleState(target, forward);
            }
            break;
        }
    });




    $("#demoContent").delegate(".roleTest", "click", function (event) {
        toggleState($(event.target), false);
    });



    $.each(groups, function (groupName, roles) {
        $("#demoContent").append("<h2>" + groupName + "</h2>");

        $.each(roles, function (roleName, roleStates) {
            var section = $("<div class='clearfix roleGroup' role='presentation'></div>").appendTo("#demoContent");
            section.append("<h3>role='" + roleName + "'</h3>");
            $.merge(roleStates, globalStates);
            $.each(roleStates, function (i, state) {
                var stateNames = state.split(" "),
                    html = "",
                    preHTML = "",
                    attribHTML = " ",
                    stateHTML = " ",
                    postHTML = "",
                    contentHTML = "",
                    noState = false,
                    noDState = false,
                    dStateHTML = " ",
                    stateDescHTML = "",
                    dStateName = "",
                    dStateDescHTML = "",
                    stateIsDynamic = false,
                    noStateDesc = false;
                $.each(stateNames, function (j, stateName) {
                    if (stateName === "role") {
                        noState = true;
                        noStateDesc = true;
                        dStateDescHTML = "role is set";
                        dStateHTML += " dState-role";
                    }
                    if (!ariaStates[stateName]) {
                        return;
                    }
                    var stateValues = ariaStates[stateName],
                        stateValue = stateValues[0];
                    switch (stateValue) {
                    case "%idr_labelledBy":
                        stateValue = "lbl1 lbl2";
                        break;
                    case "%idr_describedBy":
                        stateValue = "desc1 desc2";
                        break;
                    case "%idr_flowTo":
                        stateValue = "flowTo1 flowTo2";
                        break;
                    case "%idr_controls":
                        stateValue = "controls1 controls2";
                        break;
                    case "%idr_owns":
                        stateValue = "owns1 owns2";
                        break;
                    case "%idr_htmlLabel":
                        noState = true;
                        noStateDesc = true;
                        postHTML += "<label for='role" + widgetIncrement + "'>My Label</label>";
                        stateDescHTML = "HTML Label";
                        break;
                    case "%n":
                    case "%s":
                        stateValue = stateValues[1];
                        break;
                    case "%idr_activeDescendant":
                        return;

                    }

                    if (!noState) {
                        stateHTML += stateName + "='" + stateValue + "' ";
                    }
                    //for some reason accProbe only tracks objects with an accessible name, so for now set a title on everything
                    if (stateName !== "title") {
                        stateHTML += " title='test' ";
                    }
                    if (!noStateDesc) {
                        if (j === 0 || stateIsDynamic) {
                            dStateDescHTML += stateName + " = '" + stateValue + "'<br />";
                            dStateHTML += " dState-" + stateName;
                            stateIsDynamic = false;
                        } else {
                            stateDescHTML += stateName + " = '" + stateValue + "'<br />";
                        }
                    }
                    stateIsDynamic = false;
                    if (stateName === "aria-valuenow") {
                        stateIsDynamic = true;
                    }
                });

                switch (roleName) {
                case "alert":
                    contentHTML = "This is an alert";
                    break;
                default:
                    contentHTML = "&nbsp;&nbsp;&nbsp;&nbsp;";
                }

                html += "<div class='widgetDemo' role='presentation'><p class='stateDesc'><span class='dStateDesc'>" + dStateDescHTML + "</span>" + stateDescHTML + "</p>" + preHTML + "<span id='role" + (widgetIncrement++) + "' class='roleTest " + roleName + dStateHTML + "' tabindex='0' role='" + roleName + "' " + attribHTML + stateHTML + " >" + contentHTML + "</span>" + postHTML + "</div>";
                section.append(html);
            });

        });
    });

    $.each(ariaStates, function (key, value) {
        var id = key.replace("-", ""),
            $li = $("<li></li>"),
            $checkbox = $("<input type='checkbox' id='" + id + "Chk' checked='checked' />"),
            $label,
            $currentFocus;
        currentFocusIndex = 0;
        $checkbox.data("state", key);
        $label = $("<label for=" + id + ">" + key + "</label>");
        $li.append($checkbox, $label);
        $("#filterList").append($li);
    });

    $("#settings :checkbox").change(function (e) {
        var $chk = $(this),
            $states = $(".dState-" + $chk.data("state"));
        console.log($(this).val());
        if ($chk.is(":checked")) {
            $states.closest(".widgetDemo").show();
        } else {
            $states.closest(".widgetDemo").hide();
        }

    });

    //$(".roleTest").not(".dState-aria-label").closest(".widgetDemo").hide();
    $roles = $(".roleTest:visible");

    $("#focusAdvancer").click(function (e) {

        setInterval(function () {
            var $currentFocus = $roles.eq(currentFocusIndex++);
            $currentFocus.focus();
        }, 2000);

    });

});