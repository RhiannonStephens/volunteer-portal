<html>
<%@ page import="au.org.ala.volunteer.Task" %>
<%@ page import="au.org.ala.volunteer.Picklist" %>
<%@ page import="au.org.ala.volunteer.PicklistItem" %>
<%@ page import="au.org.ala.volunteer.TemplateField" %>
<%@ page import="au.org.ala.volunteer.field.*" %>
<%@ page import="au.org.ala.volunteer.FieldCategory" %>
<%@ page import="au.org.ala.volunteer.DarwinCoreField" %>
<%@ page import="org.codehaus.groovy.grails.commons.ConfigurationHolder" %>
<%@ page contentType="text/html; UTF-8" %>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
<meta name="layout" content="${ConfigurationHolder.config.ala.skin}"/>
<meta name="viewport" content="initial-scale=1.0, user-scalable=no"/>
<title>Transcribe Task ${taskInstance?.id} : ${taskInstance?.project?.name}</title>
<!--  <script type="text/javascript" src="${resource(dir: 'js', file: 'jquery.jqzoom-core-pack.js')}"></script>
  <link rel="stylesheet" href="${resource(dir: 'css', file: 'jquery.jqzoom.css')}"/>-->
%{--<script type="text/javascript" src="${resource(dir: 'js', file: 'mapbox.min.js')}"></script>--}%
<script type="text/javascript" src="${resource(dir: 'js', file: 'jquery.mousewheel.min.js')}"></script>
<script type="text/javascript" src="${resource(dir: 'js/fancybox', file: 'jquery.fancybox-1.3.4.pack.js')}"></script>
<link rel="stylesheet" href="${resource(dir: 'js/fancybox', file: 'jquery.fancybox-1.3.4.css')}"/>
<script type="text/javascript" src="${resource(dir: 'js', file: 'ui.core.js')}"></script>
<script type="text/javascript" src="${resource(dir: 'js', file: 'ui.datepicker.js')}"></script>
<link rel="stylesheet" href="${resource(dir: 'css/smoothness', file: 'ui.all.css')}"/>
<script type="text/javascript" src="${resource(dir: 'js', file: 'jquery.validationEngine.js')}"></script>
<script type="text/javascript" src="${resource(dir: 'js', file: 'jquery.validationEngine-en.js')}"></script>
<link rel="stylesheet" href="${resource(dir: 'css', file: 'validationEngine.jquery.css')}"/>
<script type="text/javascript" src="${resource(dir: 'js', file: 'jquery.qtip-1.0.0-rc3.min.js')}"></script>
<script type="text/javascript" src="${resource(dir: 'js', file: 'jquery.cookie.js')}"></script>
<script type="text/javascript" src="${resource(dir: 'js', file: 'jquery.scrollview.js')}"></script>
<script src="http://cdn.jquerytools.org/1.2.6/all/jquery.tools.min.js"></script>
%{--<link rel="stylesheet" type="text/css" href="http://static.flowplayer.org/tools/css/standalone.css"/>--}%
<link rel="stylesheet" type="text/css" href="${resource(dir: 'css', file: 'rangeSlider.css')}"/>
%{--<script type="text/javascript" src="http://maps.google.com/maps/api/js?v=3.4&sensor=false"></script>--}%
<script type="text/javascript" src="${resource(dir: 'js', file: 'ScottSisiters.js')}"></script>
<script type="text/javascript">
    // global Object 
    var VP_CONF = {
        isReadonly: "${isReadonly}",
        isValid: ${(taskInstance?.isValid) ? "true" : "false"},
        validator: "${validator}"
    };

    var entries = [
    <g:set var="entriesField" value="${TemplateField.findByFieldTypeAndTemplate(DarwinCoreField.individualCount, template)}"/>
    <g:set var="numItems" value="${(recordValues?.get(0)?.get(entriesField.fieldType.name())?:entriesField.defaultValue).toInteger()}" />

    <g:each in="${0..numItems}" var="i">
        [
        <g:each in="${TemplateField.findAllByCategoryAndTemplate(FieldCategory.dataset, template, [sort:'id'])}" var="field">
            <g:set var="fieldLabel" value="${field.label?:field.fieldType.label}"/>
            <g:set var="fieldName" value="${field.fieldType.name()}"/>
            {name:'${fieldName}', label:'${fieldLabel}', value: '${recordValues?.get(i)?.get(field.fieldType.name())}'},
        </g:each>
        ],
    </g:each>
    ];


    function renderEntries() {
      try {
        var htmlStr ="";
        for (entryIndex in entries) {
          htmlStr += '<tr class="fieldNoteFields" id="0"><td><strong>' + (parseInt(entryIndex) + 1) + '.</strong>'
          for (fieldIndex in entries[entryIndex]) {
            var e = entries[entryIndex][fieldIndex];
            var name = "recordValues." + entryIndex + "." + e.name;
            htmlStr += '<label for="' + name + '">' + e.label + "</label>";
            htmlStr += '<input type="text" name="' + name + '" value="' + e.value + '" id="' + name + '">';
          }
          if (entryIndex > 0) {
            htmlStr += '<button style="margin-left: 10px" onclick="deleteEntry(' + entryIndex + '); return false;">Delete</button>';
          }
          htmlStr += "</td></tr>"
        }
        $("#identification_fields").html(htmlStr);
        $("#noOfEntries").attr('value', entries.length - 1);
      } catch (e) {
        alert(e)
      }
    }

    function syncEntries() {
      for (entryIndex in entries) {
        for (fieldIndex in entries[entryIndex]) {
          var e = entries[entryIndex][fieldIndex];
          e.value = $('#recordValues\\.' + entryIndex + '\\.' + e.name).val();
        }
      }
    }

    function addEntry() {
      try {

        // first we need to save any edits to the entry list
        syncEntries();
        var entry = [
        <g:each in="${TemplateField.findAllByCategoryAndTemplate(FieldCategory.dataset, template, [sort:'id'])}" var="field">
            <g:set var="fieldLabel" value="${field.label?:field.fieldType.label}"/>
            <g:set var="fieldName" value="${field.fieldType.name()}"/>
            {name:'${fieldName}', label:'${fieldLabel}', value: ''},
        </g:each>
        ];
        entries.push(entry);
        renderEntries();
      } catch (e) {
        alert(e)
      }
    }

    function deleteEntry(index) {
      syncEntries()
      if (index > 0 && index <= entries.length) {
        entries.splice(index, 1);
        renderEntries();
      }
    }

    $(document).ready(function() {
        // prompt user to save if page has been open for too long
        if (!VP_CONF.isReadonly && !VP_CONF.validator) {
            var timeoutInMin = 30;
            var message = "Please save your work by clicking the 'save unfinished record' button as it has been " +
                    timeoutInMin + " minutes since the last page refresh.";
            window.setTimeout(function() { alert(message); }, timeoutInMin * 60 * 1000);
        }
        // prevent enter key submitting form
        $(window).keydown(function(event) {
            if (event.keyCode == 13 && event.target.nodeName != "TEXTAREA") {
                event.preventDefault();
                return false;
            }
        });

        renderEntries();

        // Context sensitive help popups
        $("a.fieldHelp").qtip({
            tip: true,
            position: {
                corner: {
                    target: 'topMiddle',
                    tooltip: 'bottomRight'
                }
            },
            style: {
                width: 400,
                padding: 8,
                background: 'white', //'#f0f0f0',
                color: 'black',
                textAlign: 'left',
                border: {
                    width: 4,
                    radius: 5,
                    color: '#E66542'// '#E66542' '#DD3102'
                },
                tip: 'bottomRight',
                name: 'light' // Inherit the rest of the attributes from the preset light style
            }
        }).bind('click', function(e){ e.preventDefault(); return false; });

        $("#showNextFromProject").click(function(e) {
            e.preventDefault();
            location.href = "${createLink(controller:(validator) ? "validate" : "transcribe", action:'showNextFromProject', id:taskInstance?.project?.id)}";
        });

        $(":range").rangeinput({
            onSlide: zoomJournalImage
        }).change(zoomJournalImage);

        // Display painting for a given painting number
        $("#showPainting").click(function(e) {
            e.preventDefault();
            var paintingRef = $(":input#paintingRefNo").val();
            var uri = getSketchUri(paintingRef); 

            if (uri) {
                window.open(uri, "paintingWindow");
            } else {
                alert("There is no painting corresponding to reference number " + paintingRef + ". Not all field notes have a corresponding painting.");
            }
        });

        // display previous journal page in new window
        $("#showPreviousJournalPage").click(function(e) {
            e.preventDefault();
            var uri = showNotebookPage("${taskInstance?.externalIdentifier}", -1);

            if (uri) {
                window.open(uri, "journalWindow");
            } else {
                alert("Previous journal page was not found");
            }
        });

        // display next journal page in new window
        $("#showNextJournalPage").click(function(e) {
            e.preventDefault();
            var uri = showNotebookPage("${taskInstance?.externalIdentifier}", 1);

            if (uri) {
                window.open(uri, "journalWindow");
            } else {
                alert("Next journal page was not found");
            }
        });

        $("#imagePane").scrollview({
            grab:"${resource(dir: 'images', file: 'openhand.cur')}",
            grabbing:"${resource(dir: 'images', file: 'closedhand.cur')}"
        });

        var isReadonly = VP_CONF.isReadonly;
        if (isReadonly) {
            // readonly more
            $(":input").not('.skip').hover(function(e){alert('You do not have permission to edit this task.')}).attr('disabled','disabled').attr('readonly','readonly');
        }

    });

    function zoomJournalImage(event, value) {
        //console.info("value changed to", value);
        $("#journalPageImg").css("width", value + "%");
    }
</script>
%{--<script type="text/javascript" src="${resource(dir: 'js', file: 'journalTranscribe.js')}"></script>--}%
  <style type="text/css">

    div#journal2Text {
        margin-top: 15px;
    }

    #journal2Text table {
        width: 100%;
        padding-bottom: 10px;
        /*margin-right: 5px;*/
    }

    #journal2Text #transcribeAllText {
        font-size: 12px;
        padding: 2px;
    }

    #journal2Fields table {
        width: 100%;
        padding-bottom: 10px;
        /*margin-left: 5px;*/
    }

    div#journal2Fields {
        margin-top: 15px;
    }

    div#journal2Fields th {
        /*border-bottom: 2px solid #ffffff;*/
    }

    div#journal2Fields tr td {
        padding: 5px;
        /*border-bottom: 2px solid #ffffff;*/
    }

    div#journal2Fields tr:last-child td {
        border-bottom: none;
    }

  </style>
</head>

<body class="sublevel sub-site volunteerportal">

  <cl:navbar selected="expeditions" />

  <header id="page-header">
    <div class="inner">

      <cl:messages />

      <nav id="breadcrumb">
        <ol>
          <li><a href="${createLink(uri: '/')}"><g:message code="default.home.label"/></a></li>
          <li><a href="${createLink(controller: 'project', action:'list')}"><g:message code="default.projects.label"/></a></li>
          <li><g:link controller="project" action="index" id="${taskInstance?.project?.id}" class="crumb">${taskInstance?.project?.name}</g:link></li>
          <li class="last">${(validator) ? 'Validate' : 'Transcribe'} Task - ${(recordValues?.get(0)?.catalogNumber) ? recordValues?.get(0)?.catalogNumber : taskInstance?.id}</li>
        </ol>
      </nav>
      <hgroup>
        <h1>${(validator) ? 'Validate' : 'Transcribe'} Task: ${taskInstance?.project?.name} (ID: ${taskInstance?.externalIdentifier})</h1>
      </hgroup>
    </div>
  </header>

<div class="inner">
    <g:hasErrors bean="${taskInstance}">
        <div class="errors">
            There was a problem saving your edit: <g:renderErrors bean="${taskInstance}" as="list" />
        </div>
    </g:hasErrors>
    <div id="videoLinks" style="padding-top: 6px; float: right;">
        ${taskInstance?.project?.tutorialLinks}
    </div>

    <g:if test="${taskInstance}">
        <g:form controller="${validator ? "transcribe" : "validate"}" class="transcribeForm">
            <g:hiddenField name="recordId" value="${taskInstance?.id}"/>
            <g:hiddenField name="redirect" value="${params.redirect}"/>
            <div style="float:left;margin-top:5px;">Zoom image:&nbsp;</div>
            <g:set var="defaultWidthPercent" value="100" />
            <input type="range" name="width" min="50" max="150" value="${defaultWidthPercent}" />

            <span id="journalPageButtons">
                <button id="showPreviousJournalPage" title="displays page in new window">&lt;&ndash; show previous journal page</button>
                <button id="showNextJournalPage" title="displays page in new window">show next journal page &ndash;&gt;</button>
            </span>
            <div class="dialog" id="imagePane">
                <g:each in="${taskInstance.multimedia}" var="m">
                  <g:if test="${m.mimeType != 'text/plain'}">
                    <g:set var="imageUrl" value="${ConfigurationHolder.config.server.url}${m.filePath}"/>
                    <div class="pageViewer" id="journalPageImg" style="width:${defaultWidthPercent}%;height:300px;">
                        <div><img src="${imageUrl}" style="width:100%;"/></div>
                    </div>
                  </g:if>
                </g:each>
            </div>
            <div class="fields" id="journal2Text">
                <g:set var="entriesField" value="${TemplateField.findByFieldTypeAndTemplate(DarwinCoreField.individualCount, template)}"/>
                <g:hiddenField name="recordValues.0.${entriesField.fieldType}" id="noOfEntries" value="${recordValues?.get(0)?.get(entriesField.fieldType.name())?:entriesField.defaultValue}"/>
                <table>
                    <thead>
                        <tr>
                            <th>
                              <h3>1. Transcribe all text from the left hand page into this box as it appears</h3>
                            </th>
                          <th>
                              <h3>2. Transcribe all text from the right hand page into this box as it appears</h3>
                          </th>

                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td>
                                <g:textArea name="recordValues.0.occurrenceRemarks" value="${recordValues?.get(0)?.occurrenceRemarks}" id="transcribeAllText1" rows="12" cols="30" style="width:98%;height:300px;"/>
                            </td>
                          <td>
                              <g:textArea name="recordValues.1.occurrenceRemarks" value="${recordValues?.get(1)?.occurrenceRemarks}" id="transcribeAllText2" rows="12" cols="30" style="width:98%;height:300px;"/>
                          </td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <div class="fields" id="journal2Fields">
                <table>
                    <thead>
                        <tr>
                            <th colspan="2">
                                <h3>3. Where a species or common name appears in the text please enter any relevant information into the fields below</h3>
                                <button onclick="addEntry(); return false;">Add row</button>
                            </th>
                        </tr>
                    </thead>
                    <tbody id="identification_fields">
                    </tbody>
                </table>

            </div>

            <div class="fields" id="journalNotes" style="width:${(validator) ? '100%' : '50%'}">
                <table style="width: 100%">
                    <thead>
                    <tr><th><h3>Notes</h3> &ndash; Record any comments here that may assist in validating this task </th></tr>
                    </thead>
                    <tbody>
                        <tr class="prop">
                            <td class="name">${(validator) ? 'Transcriber' : 'Your'} Notes</td>
                            <td class="value"><g:textArea name="recordValues.0.transcriberNotes" value="${recordValues?.get(0)?.transcriberNotes}"
                                id="transcriberNotes" rows="10" cols="40" style="width: 100%"/></td>
                        </tr>
                        <g:if test="${validator}">
                            <tr class="prop">
                            <td class="name">Validator Notes</td>
                            <td class="value"><g:textArea name="recordValues.0.validatorNotes" value="${recordValues?.get(0)?.validatorNotes}"
                                id="transcriberNotes" rows="10" cols="40" style="width: 100%"/></td>
                        </tr>
                        </g:if>
                    </tbody>
                </table>
            </div>

            <div class="buttons" style="clear: both">
                <g:hiddenField name="id" value="${taskInstance?.id}"/>
                <g:if test="${validator}">
                    <span class="button"><g:actionSubmit class="validate" action="validate"
                             value="${message(code: 'default.button.validate.label', default: 'Validate')}"/></span>
                    <span class="button"><g:actionSubmit class="dontValidate" action="dontValidate"
                             value="${message(code: 'default.button.dont.validate.label', default: 'Dont validate')}"/></span>
                    <span class="button"><button id="showNextFromProject" class="skip">Skip</button></span>
                    <span style="color:gray;">&nbsp;&nbsp;[is valid: ${taskInstance?.isValid} | validatedBy:  ${taskInstance?.fullyValidatedBy}]</span>
                </g:if>
                <g:else>
                    <span class="button"><g:actionSubmit class="save" action="save"
                             value="${message(code: 'default.button.save.label', default: 'Submit for validation')}"/></span>
                    <span class="button"><g:actionSubmit class="savePartial" action="savePartial"
                             value="${message(code: 'default.button.save.partial.label', default: 'Save unfinished record')}"/></span>
                    <span class="button">
                        %{--<g:actionSubmit class="skip" action="showNextFromProject" params="[id: ${taskInstance?.project?.id}]"--}%
                             %{--value="${message(code: 'default.button.skip.label', default: 'Skip')}"/>--}%
                        <cl:isLoggedIn>
                            <button id="showNextFromProject" class="skip">Skip</button>
                        </cl:isLoggedIn>
                    </span>
                </g:else>
            </div>
            <a href="#promptUser" id="promptUserLink" style="display: none">show prompt to save</a>
            <div style="display: none">
                <div id="promptUser">
                    <h2>Lock has Expired</h2>
                    The lock on this record is about to expire.<br/>
                    Please either save your changes:<br/>
                    <span class="button"><g:actionSubmit class="savePartial" action="savePartial"
                             value="${message(code: 'default.button.save.partial.label', default: 'Save unfinished record')}"/></span>
                    <br>
                    Or reload the page (Note: any changes you may have made will be lost)
                    <br/>
                    <input type="button" value="Reload Page" onclick="window.location.reload()"/>
                    <br/>
                    NOTE: the page will be automatically saved in <span id="reloadCounter">5</span> minutes if no action if taken
                </div>
            </div>
        </g:form>
    </g:if>
    <g:else>
        No tasks loaded for this project !
    </g:else>
  </div>
</body>
</html>
