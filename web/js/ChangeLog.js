/*
   The contents of this file are subject to the Mozilla Public
   License Version 1.1 (the "License"); you may not use this file
   except in compliance with the License. You may obtain a copy of
   the License at http://www.mozilla.org/MPL/
  
   Software distributed under the License is distributed on an "AS
   IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
   implied. See the License for the specific language governing
   rights and limitations under the License.
  
   The Original Code is the Bugzilla Objective Watchdog Bugzilla Extension.
  
   The Initial Developer of the Original Code is "Nokia Corpodation"
   Portions created by the Initial Developer are Copyright (C) 2011 the
   Initial Developer. All Rights Reserved.
  
   Contributor(s):
     Eero Heino <eero.heino@nokia.com>
  */

// le template engine
var _tmplCache = {}
this.parseTemplate = function(str, data) {
    /// <summary>                                                                                                           
    /// Client side template parser that uses &lt;#= #&gt; and &lt;# code #&gt; expressions.                                
    /// and # # code blocks for template expansion.                                                                         
    /// NOTE: chokes on single quotes in the document in some situations                                                    
    ///       use &amp;rsquo; for literals in text and avoid any single quote                                               
    ///       attribute delimiters.                                                                                         
    /// </summary>                                                                                                          
    /// <param name="str" type="string">The text of the template to expand</param>                                          
    /// <param name="data" type="var">                                                                                      
    /// Any data that is to be merged. Pass an object and                                                                   
    /// that object's properties are visible as variables.                                                                  
    /// </param>                                                                                                            
    /// <returns type="string" />                                                                                           
    var err = "";
    try {
        var func = _tmplCache[str];
        if (!func) {
            var strFunc = "var p=[],print=function(){p.push.apply(p,arguments);};" + "with(obj){p.push('" + str.replace(/[\r\t\n]/g, " ").replace(/'(?=[^#]*#>)/g, "\t").split("'").join("\\'").split("\t").join("'").replace(/<#=(.+?)#>/g, "',$1,'").split("<#").join("');").split("#>").join("p.push('") + "');}return p.join('');";
            //alert(strFunc);                                                                                               
            func = new Function("obj", strFunc);
            _tmplCache[str] = func;
        }
        return func(data);
    } catch (e) {
        err = e.message;
    }
    return "< # ERROR: " + err + " # >";
    //return "< # ERROR: " + err.htmlEncode() + " # >";                                                                     
}

function get_datestamp(mv_day)
{
    var current_time = new Date();
    if (mv_day != undefined)
    {
        current_time.setDate(current_time.getDate() + mv_day);
    }
    var month = current_time.getMonth() + 1;
    if (month < 10)
    {
        month = '0' + month;
    }
    var day = current_time.getDate();
    if (day< 10)
    {
        day= '0' + day;
    }
    return current_time.getFullYear()+'-'+month+'-'+day;
}

function get_bug_ids_from_list(rows_id)
{
    var string_begins = "show_bug.cgi?id=";
    var id_list = [];
    $('#'+rows_id).find('a[href^="'+string_begins+'"]').each(function (i, val)
    {
        id_list.push($(this).attr('href').replace(string_begins, ''));
    });
    return id_list;
}

function go_to_buglist(rows_id)
{
    var buglist = get_bug_ids_from_list(rows_id);
    if (buglist.length)
    {
        window.location = 'buglist.cgi?bug_id=' + buglist.join(',');
    }

}
