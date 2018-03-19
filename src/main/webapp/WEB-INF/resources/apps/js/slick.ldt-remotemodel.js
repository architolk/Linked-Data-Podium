function saveGrid() {
  loader.saveData(containerurl,context);
}
function statusFormatter(row, cell, value, columnDef, dataContent) {
  var img = "";
  if (value === 1) { //New item
    img = "<img src='../css/images/tick.png'>"
  } else if (value === 2) { //Changed item
    img = "<img src='../css/images/tag_red.png'>"
  }
  return img;
}

(function ($) {
  /***
   * A sample AJAX data store implementation.
   * Right now, it's hooked up to load search results from Octopart, but can
   * easily be extended to support any JSONP-compatible backend that accepts paging parameters.
   */
  function RemoteModel(pUrl) {
    // private
    var PAGESIZE = 50;
    var data = [];
    var searchstr = "";
    var sortcol = null;
    var sortdir = 1;
    var h_request = null;
    var req = null; // ajax request
    var url = pUrl;
    var resourceProperties = {};

    // events
    var onDataLoading = new Slick.Event();
    var onDataLoaded = new Slick.Event();
    var onDataSaving = new Slick.Event();
    var onDataSaved = new Slick.Event();


    function init() {
    }


    function isDataLoaded(from, to) {
      for (var i = from; i <= to; i++) {
        if (data[i] == undefined || data[i] == null) {
          return false;
        }
      }

      return true;
    }


    function clear() {
      for (var key in data) {
        delete data[key];
      }
      data.length = 0;
    }

    function removeRow(row) {
      data.splice(row,1);
    }

    function ensureData(from, to) {
      if (req) {
        req.abort();
        for (var i = req.fromPage; i <= req.toPage; i++)
          data[i * PAGESIZE] = undefined;
      }

      if (from < 0) {
        from = 0;
      }

      if (data.length > 0) {
        to = Math.min(to, data.length - 1);
      }

      var fromPage = Math.floor(from / PAGESIZE);
      var toPage = Math.floor(to / PAGESIZE);

      while (data[fromPage * PAGESIZE] !== undefined && fromPage < toPage)
        fromPage++;

      while (data[toPage * PAGESIZE] !== undefined && fromPage < toPage)
        toPage--;

      if (fromPage > toPage || ((fromPage == toPage) && data[fromPage * PAGESIZE] !== undefined)) {
        // TODO:  look-ahead
        onDataLoaded.notify({from: from, to: to});
        return;
      }

      if (h_request != null) {
        clearTimeout(h_request);
      }

      h_request = setTimeout(function () {
        for (var i = fromPage; i <= toPage; i++)
          data[i * PAGESIZE] = null; // null indicates a 'requested but not available yet'

        onDataLoading.notify({from: from, to: to});

        req = $.ajax({
          datatype: "json",
          url: url,
          cache: true,
          success: onSuccess,
          error: function () {
            onError(fromPage, toPage)
          }
        });
        req.fromPage = fromPage;
        req.toPage = toPage;
      }, 50);
    }


    function onError(fromPage, toPage) {
      alert("error loading pages " + fromPage + " to " + toPage);
    }

    function onSuccess(resp) {
      var from = 0;
      var context = resp['@context'];
      //Save resource properties to know which values are URI's
      for (var item in context) {
        if (typeof context[item] === 'object') {
          var pos = item.indexOf(":");
          if (pos > 0) {
            var prefix = item.substring(0,pos);
            var name = item.substring(pos+1);
            var namespace = context[prefix];
            if (namespace !== "") {
              resourceProperties[namespace+name] = true;
            }
          }
        }
      }
      //Load data
      if ('graph' in resp) {
        to = from + resp.graph.length;
        data.length = resp.graph.length;
        for (var i = 0; i < resp.graph.length; i++) {
          var resource = resp.graph[i];
          var item = {};
          for (var property in resource) {
            if (resource.hasOwnProperty(property)) {
              var pos = property.indexOf(":");
              var url = property;
              if (pos > 0) {
                var prefix = property.substring(0,pos);
                var name = property.substring(pos+1);
                var namespace = context[prefix];
                if (namespace !== "") {
                  url = namespace+name;
                }
              } else {
                var alias = context[property];
                if (alias !== "") {
                  url = alias;
                }
              }
              item[url] = resource[property];
            }
          }
          
          data[from + i] = item;
          data[from + i].index = from + i;
          data[from + i]['#'] = 0; // Keep track of changes in the data
        }
      } else if ('@id' in resp) {
          to = from + 1;
          var resource = resp;
          var item = {};
          for (var property in resource) {
            if (resource.hasOwnProperty(property) && property!=='@context') {
              var pos = property.indexOf(":");
              var url = property;
              if (pos > 0) {
                var prefix = property.substring(0,pos);
                var name = property.substring(pos+1);
                var namespace = context[prefix];
                if (namespace !== "") {
                  url = [namespace+name];
                }
              }
              item[url] = resource[property];
            }
          }
          
          data[from] = item;
          data[from].index = from;
          data[from]['#'] = 0; // Keep track of changes in the data
      } else {
        to = from;
      }
      
      req = null

      onDataLoaded.notify({from: from, to: to});
    }


    function reloadData(from, to) {
      for (var i = from; i <= to; i++)
        delete data[i];

      ensureData(from, to);
    }


    function setSort(column, dir) {
      sortcol = column;
      sortdir = dir;
      clear();
    }

    function setSearch(str) {
      searchstr = str;
      clear();
    }

    function addRow(grid,item, defaultItem) {
      item['#'] = 1;
      for (var property in defaultItem) {
        if (defaultItem.hasOwnProperty(property)) {
            item[property]=defaultItem[property];
        }
      }
      item.id = UUIDjs.create().toURN();
      grid.invalidateRow(data.length);
      data.push(item);
      grid.updateRowCount();
      grid.render();
    }

    function updateRow(row,template,fragments) {
      for (var property in template) {
        var value = template[property];
        for (var name in fragments) {
          var newvalue = data[row][fragments[name]];
          value = value.replace("{"+name+"}",newvalue);
        }
        data[row][property] = value
      }
    }
    
    function saveData(url,context) {

      var mergedContext = {};
      for (var item in context) {
        if (context.hasOwnProperty(item)) {
          if (typeof context[item] === 'object') {
            mergedContext[item]={'@type': '@id'};
          } else {
            mergedContext[item]=context[item];
          }
        }
      }
      for (var item in resourceProperties) {
        if (resourceProperties.hasOwnProperty(item)) {
          mergedContext[item]={'@type': '@id'};
        }
      }
    
      var body = {
        '@context': mergedContext,
        graph: data
      };

      onDataSaving.notify();
      
      $.ajax({
        type: "PUT",
        contentType: "application/ld+json",
        url: url,
        data: JSON.stringify(body),
        success: function () {
          for (var i = 0; i < data.length; i++) {
            data[i]['#'] = 0; //Saved, so reset change indication
          }
          grid.invalidateAllRows();
          grid.render();
          onDataSaved.notify();
        },
        error: function () {
          alert('Some error occured');
        }
      })
    }

    init();

    return {
      // properties
      "data": data,

      // methods
      "clear": clear,
      "isDataLoaded": isDataLoaded,
      "ensureData": ensureData,
      "reloadData": reloadData,
      "setSort": setSort,
      "setSearch": setSearch,
      "addRow": addRow,
      "removeRow": removeRow,
      "updateRow": updateRow,
      "saveData": saveData,

      // events
      "onDataLoading": onDataLoading,
      "onDataLoaded": onDataLoaded,
      "onDataSaving": onDataSaving,
      "onDataSaved": onDataSaved
    };
  }

  // Slick.Data.RemoteModel
  $.extend(true, window, { Slick: { Data: { RemoteModel: RemoteModel }}});
})(jQuery);