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
    console.log("url", url)
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
    console.log("newUrl", newUrl);
    return newUrl;
}

/**
 * Handler for the date selector changes
 */
function clOnDatePickerSelect(date, picker)
{
    var name = picker.input.attr('name');
    var $tabs = $("#tabs");

    // Update tab urls
    $tabs.data('tabs').anchors.each(function() {
        var $a = $(this)
        var url = $a.data('href.tabs');
        url = clSetURLParam(url, name, date);
        $a.data('href.tabs', url);
        $a.data('load.tabs', url);
        console.log(url);
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
    console.log(ui);
    if (history.replaceState) {
        var url = document.location.href.replace(/#.*|$/, '#' + ui.panel.id);
        history.replaceState({}, document.title, url);
    } else {
        // This jumps the page to top of the table, but is probably better than
        // nothing when history manipulation is not available.
        window.location.hash = ui.panel.id;
    }
    $.cookie("ChangeLogActiveTab", ui.index, { expires: 9999 });
    $("table.changelog-table", ui.panel).tablesorter();
}
