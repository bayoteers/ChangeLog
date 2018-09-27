/**
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * Copyright (C) 2013 Jolla Ltd.
 * Contact: Pami Ketolainen <pami.ketolainen@jollamobile.com>
 */

/**
 * Helper to change parameters in URL string
 * @param  {String} url      Old URL
 * @param  {String} name     Name of the parameter to change
 * @param  {String} newValue New value for the named parameter
 * @return {String}          New URL
 */
function clSetURLParam (url, name, newValue) {
    // Split the hash and parameters out of the URL
    var parts = url.split(/#/);
    var newUrl = parts[0];
    var hash = parts.length == 1 ? '' : parts[1];
    parts = newUrl.split(/\?/);
    newUrl = parts[0];
    var params = parts.length == 1 ? '' : parts[1];

    // Add or replace the parameter value
    var re = new RegExp(name+'=[^&]*');
    if (params.match(re) == null) {
        if (params) params += '&';
        params += name + '=' + newValue;
    } else {
        params = params.replace(re, name + '=' + newValue);
    }

    // Construct new url
    newUrl += '?' + params;
    if (hash) newUrl += '#' + hash;
    return newUrl;
}

/**
 * Handler for the date selector changes
 */
function clChangeDate(date)
{
    var $input = $("#datepicker");
    var $tabs = $("#tabs");
    var name = $input.attr("name");
    $input.css('color', '');

    // Update tab urls
    $tabs.data('tabs').anchors.each(function() {
        var $a = $(this)
        var url = $a.attr('href');
        url = clSetURLParam(url, name, date);
        $a.attr('href', url);
    });

    // Reload current tab
    // NOTE: option name changes to 'active' in later jQuery UI
    var selected = $tabs.tabs("option", "selected");
    $("#tabs").tabs("load", selected);

    //Update history
    if (history.replaceState) {
        var pageUrl = clSetURLParam(document.location.href, name, date);
        history.replaceState({}, document.title, pageUrl);
    }
}

/**
 * Handler for tab load events
 */
function clOnTabLoad(ev, ui)
{
    if (history.replaceState) {
        var url = document.location.href.replace(/#.*|$/, '#' + ui.panel.id);
        history.replaceState({}, document.title, url);
    } else {
        // This jumps the page to top of the table, but is probably better than
        // nothing when history manipulation is not available.
        window.location.hash = ui.panel.id;
    }
    $.cookie("clLastQuery", $(ui.tab).data('qid'), { expires: 9999 });
    $("table.changelog-table", ui.panel).tablesorter();
}

/**
 * Initializition when page has loaded
 */
function clInit()
{
    var relative_re = /^-\d+[hdwm]$/i;
    var ymd_re = /^\d{4}-\d{2}-\d{2}$/i;
    $("#datepicker").datepicker({
        maxDate: "-0D",
        dateFormat: 'yy-mm-dd',
        constrainInput: false,
        showOn: "button",
        buttonText: "&#128197;",
        defaultDate: -2,
        onSelect: function(date, picker) {
            clChangeDate(date);
        }
    }).keyup(function(e){
        if(e.keyCode == 13) {
            var $picker = $("#datepicker");
            var date = $picker.val();
            if (relative_re.test(date) || ymd_re.test(date)) {
                clChangeDate(date);
            } else {
                $picker.css('color', 'red');
            }
        }
    });

    var qid = $.cookie("clLastQuery") || 0;
    var selected = (!window.location.hash && qid) ? (clQueryIndex[qid] || 0) : undefined;

    $("#tabs").tabs({
        load: clOnTabLoad,
        selected: selected,
        ajaxOptions: {
            beforeSend: function() {$("#loadin-element").show()},
            complete: function() {$("#loadin-element").hide()}
        }
    });
}
